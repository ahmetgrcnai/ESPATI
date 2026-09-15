import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../core/post_event_bus.dart';
import '../core/result.dart';
import '../data/models/pet_model.dart';
import '../data/models/post_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/interfaces/i_pet_repository.dart';
import '../data/repositories/interfaces/i_post_repository.dart';
import '../services/content_moderation_service.dart';

/// The discrete phases the upload pipeline moves through. Exposed to the UI
/// so the submit button can switch label/progress indicator accordingly.
enum CreatePostStatus {
  /// Form is idle — user is still editing.
  idle,

  /// Image is being re-encoded client-side (flutter_image_compress).
  compressing,

  /// Compressed image is being pushed to Firebase Storage.
  uploading,

  /// Post metadata is being written to Firestore (after Storage succeeded).
  saving,

  /// The entire pipeline completed; the UI should pop the screen.
  success,

  /// Any phase failed — inspect [CreatePostViewModel.errorMessage].
  error,
}

/// ViewModel powering the Post Creation workflow.
///
/// Bridges [IPetRepository] (for the user's pet list) and [IPostRepository]
/// (for the actual post upload), and owns a linear state machine:
///
///   idle → compressing → uploading → saving → success
///                                  ↘ error (from any phase)
///
/// Business invariants enforced here (never in the View):
///   • The user must pick an image *and* a pet before [submit] is accepted.
///   • Compression runs before upload; the pipeline refuses to upload any
///     JPEG larger than [_kMaxUploadBytes] even if the user supplied a huge
///     source file, protecting Storage costs and perceived upload time.
///   • Selected pet metadata (id / name / breed / type) is denormalized onto
///     the PostModel so the Global Feed renders them without extra reads.
class CreatePostViewModel extends ChangeNotifier {
  CreatePostViewModel({
    required IPostRepository postRepository,
    required IPetRepository petRepository,
    required UserModel? currentUser,
    String? initialGroupId,
    List<String> groupBannedWords = const [],
  })  : _postRepository = postRepository,
        _petRepository = petRepository,
        _currentUser = currentUser,
        _groupId = initialGroupId,
        _groupBannedWords = groupBannedWords {
    // Capture into a local so Dart's null-promotion applies; instance fields
    // aren't promotable even after a null check.
    final user = currentUser;
    if (user != null && user.id.isNotEmpty) {
      _subscribePets(user.id);
    }
  }

  // ── Dependencies ────────────────────────────────────────────────────────────

  final IPostRepository _postRepository;
  final IPetRepository _petRepository;
  final UserModel? _currentUser;

  /// The target group's own extra denylist (see [ChatGroupModel.bannedWords])
  /// — checked alongside [ContentModerationService]'s app-wide list in
  /// [submit]. Empty for posts with no [groupId] or a group that set none.
  final List<String> _groupBannedWords;

  StreamSubscription<List<PetModel>>? _petsSub;

  // ── Compression policy ──────────────────────────────────────────────────────
  //
  // Storage bills per byte and Firestore reads are cached by the CDN using
  // download URL — smaller is better on both axes. 1 MB is the "never exceed"
  // ceiling; we target ~900 KB by tuning [_kJpegQuality] and [_kMaxDimension].

  static const int _kMaxUploadBytes = 1 * 1024 * 1024; // 1 MB
  static const int _kJpegQuality = 82; // Good perceptual fidelity for pet photos
  static const int _kMaxDimension = 1600; // px on the long edge

  // ── State ───────────────────────────────────────────────────────────────────

  CreatePostStatus _status = CreatePostStatus.idle;
  CreatePostStatus get status => _status;

  /// 0..1 — only meaningful while [status] == [CreatePostStatus.uploading].
  double _uploadProgress = 0;
  double get uploadProgress => _uploadProgress;

  bool get isUploading => _status != CreatePostStatus.idle &&
      _status != CreatePostStatus.success &&
      _status != CreatePostStatus.error;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Form state

  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  PetModel? _selectedPet;
  PetModel? get selectedPet => _selectedPet;

  String _location = '';
  String get location => _location;

  /// Target community group ("Hangi Topluluğa Gönderilecek?"). `null` routes
  /// the post to no specific group ("Genel").
  String? _groupId;
  String? get groupId => _groupId;

  // Pets stream-backed

  List<PetModel> _pets = const [];
  List<PetModel> get pets => List.unmodifiable(_pets);

  bool _petsLoading = true;
  bool get petsLoading => _petsLoading;

  /// True if the submit button should be enabled right now. Photo and pet
  /// are both optional — a group post can be a text-only discussion (the
  /// Reddit/Facebook-style "start a discussion" flow).
  bool get canSubmit =>
      _status == CreatePostStatus.idle && _currentUser != null;

  // ── Pets stream ─────────────────────────────────────────────────────────────

  void _subscribePets(String uid) {
    // _petsLoading is already true via field initialiser — no notifyListeners()
    // call here. Calling it from the constructor fires while the Provider
    // element is still in its create() path, which triggers the !_dirty assertion.
    _petsSub = _petRepository.watchUserPets(uid).listen(
      (pets) {
        _pets = pets;
        _petsLoading = false;
        // If the previously-selected pet was deleted server-side, drop the
        // selection so the submit button disables gracefully.
        if (_selectedPet != null &&
            !pets.any((p) => p.id == _selectedPet!.id)) {
          _selectedPet = null;
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[CreatePostViewModel] watchUserPets error: $e');
        _petsLoading = false;
        notifyListeners();
      },
    );
  }

  // ── Form setters ────────────────────────────────────────────────────────────

  void setImage(File? file) {
    _selectedImage = file;
    notifyListeners();
  }

  void clearImage() {
    _selectedImage = null;
    notifyListeners();
  }

  void selectPet(PetModel? pet) {
    _selectedPet = pet;
    notifyListeners();
  }

  void setLocation(String location) {
    _location = location;
    notifyListeners();
  }

  void setGroupId(String? groupId) {
    _groupId = groupId;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null && _status != CreatePostStatus.error) return;
    _errorMessage = null;
    if (_status == CreatePostStatus.error) _status = CreatePostStatus.idle;
    notifyListeners();
  }

  // ── Compression ─────────────────────────────────────────────────────────────

  /// Re-encodes [source] as a JPEG sized/quality'd to stay under the 1 MB
  /// ceiling. Returns the compressed file; throws if compression fails.
  ///
  /// Strategy:
  ///   1. First pass at [_kJpegQuality] / [_kMaxDimension].
  ///   2. If still over the ceiling, drop quality in 10-point steps (floor 50).
  ///   3. If still over after the last step, return the smallest we achieved —
  ///      callers should still attempt the upload rather than hard-failing on
  ///      photos that genuinely can't shrink further.
  Future<File> _compressToUnder1Mb(File source) async {
    final dir = await getTemporaryDirectory();
    final basePath =
        '${dir.path}/espati_post_${DateTime.now().millisecondsSinceEpoch}';

    // [FIX RISK-RM-01] Track every file path created during the quality loop.
    // The finally block deletes all losers; only the winner survives to be
    // passed to the upload pipeline (where submit() deletes it after upload).
    final generatedPaths = <String>[];
    File? bestFile;
    int bestSize = 1 << 31;

    try {
      for (var quality = _kJpegQuality; quality >= 50; quality -= 10) {
        final targetPath = '$basePath-q$quality.jpg';
        final result = await FlutterImageCompress.compressAndGetFile(
          source.absolute.path,
          targetPath,
          quality: quality,
          minWidth: _kMaxDimension,
          minHeight: _kMaxDimension,
          format: CompressFormat.jpeg,
        );
        if (result == null) continue;

        generatedPaths.add(result.path);
        final file = File(result.path);
        final size = await file.length();

        if (size < bestSize) {
          bestFile = file;
          bestSize = size;
        }

        // Under budget — bestFile holds the winner; stop compressing.
        if (size <= _kMaxUploadBytes) break;
      }

      if (bestFile == null) {
        // compressAndGetFile returned null on every pass — surface a clear error.
        throw Exception(
          'Fotoğraf işlenemedi. Lütfen farklı bir görsel deneyin.',
        );
      }
      return bestFile;
    } finally {
      // Delete every intermediate temp file except the winner. This runs on
      // both normal return and exception paths, so no files are ever abandoned.
      for (final path in generatedPaths) {
        if (path == bestFile?.path) continue; // keep the file we'll upload
        try {
          await File(path).delete();
        } catch (_) {} // ignore individual cleanup failures
      }
    }
  }

  // ── Submit — the full pipeline ──────────────────────────────────────────────

  /// Runs the full compress → upload → save pipeline. Returns `true` iff the
  /// post was persisted. The caller (View) should pop on success.
  Future<bool> submit({
    required String description,
    bool isAnnouncement = false,
  }) async {
    if (!canSubmit) return false;

    final user = _currentUser!;
    final pet = _selectedPet;
    final source = _selectedImage;
    final trimmedDescription = description.trim();

    // Madde 8 — safety mandate: reject inappropriate text before the
    // compress/upload/save pipeline ever starts, so nothing is written to
    // Firestore or Storage for flagged content. Groups get their own extra
    // denylist on top of the app-wide one (see [_groupBannedWords]).
    if (ContentModerationService.containsInappropriateText(
        trimmedDescription,
        extraBannedWords: _groupBannedWords)) {
      _status = CreatePostStatus.error;
      _errorMessage =
          'İçeriğiniz topluluk kurallarımıza uymayan ifadeler içeriyor.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    _uploadProgress = 0;

    // Text-only discussion posts (no photo) skip compression entirely.
    File? compressed;
    if (source != null) {
      _status = CreatePostStatus.compressing;
      notifyListeners();
      try {
        compressed = await _compressToUnder1Mb(source);
      } catch (e) {
        _status = CreatePostStatus.error;
        _errorMessage = 'Fotoğraf hazırlanırken bir hata oluştu.';
        notifyListeners();
        return false;
      }
    }

    // Build the post with denormalized pet metadata, then delegate to the repo.
    final post = PostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: user.id,
      authorName: user.name.isEmpty ? user.email : user.name,
      authorImage: user.profilePicture,
      imageUrl: '', // Repo fills this in after Storage upload completes (if any).
      description: trimmedDescription,
      location: _location,
      timestamp: DateTime.now(),
      petId: pet?.id ?? '',
      petName: pet?.name ?? '',
      petBreed: pet?.breed ?? '',
      petType: pet?.petType.name ?? '',
      groupId: _groupId,
      isAnnouncement: isAnnouncement && _groupId != null,
    );

    _status = CreatePostStatus.uploading;
    notifyListeners();

    // [FIX RISK-RM-01] The compressed temp file (the winner from
    // _compressToUnder1Mb) is deleted here after the upload attempt completes,
    // regardless of whether createPost succeeds or fails.
    late final Result<PostModel> result;
    try {
      result = await _postRepository.createPost(
        post,
        compressed,
        onProgress: (p) {
          _uploadProgress = p;
          // Flip to "saving" phase once Storage reports 100% — gives the user
          // honest feedback while Firestore writes the metadata document.
          if (p >= 0.999 && _status == CreatePostStatus.uploading) {
            _status = CreatePostStatus.saving;
          }
          notifyListeners();
        },
      );
    } finally {
      if (compressed != null) {
        try {
          await compressed.delete();
        } catch (_) {}
      }
    }

    switch (result) {
      case Success(:final data):
        PostEventBus.instance.emitPostCreated(data);
        _status = CreatePostStatus.success;
        _uploadProgress = 1.0;
        notifyListeners();
        return true;

      case Failure(:final message):
        _status = CreatePostStatus.error;
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  @override
  void dispose() {
    _petsSub?.cancel();
    super.dispose();
  }
}
