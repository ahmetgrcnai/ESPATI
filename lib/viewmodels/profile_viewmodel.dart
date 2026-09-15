import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../core/notification_service.dart';
import '../core/result.dart';
import '../data/models/pet_model.dart';
import '../data/models/post_model.dart';
import '../data/models/reminder_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/interfaces/i_pet_repository.dart';
import '../data/repositories/interfaces/i_post_repository.dart';
import '../data/repositories/interfaces/i_reminder_repository.dart';
import '../data/repositories/interfaces/i_user_repository.dart';

/// ViewModel for the Profile screen.
///
/// Manages four concerns:
///   1. User profile data (loaded from [IUserRepository])
///   2. Pet list — real-time stream from [IPetRepository]
///   3. Pati Takvimi reminder lifecycle (loaded from [IReminderRepository])
///   4. "Gönderilerim" post grid — real-time stream from [IPostRepository]
class ProfileViewModel extends ChangeNotifier {
  final IUserRepository _userRepo;
  final IReminderRepository _reminderRepo;
  final IPetRepository _petRepo;
  final IPostRepository _postRepo;
  final NotificationService _notifService;

  StreamSubscription<UserModel?>? _userSubscription;
  StreamSubscription<List<PetModel>>? _petsSubscription;
  StreamSubscription<List<ReminderModel>>? _remindersSubscription;
  StreamSubscription<List<PostModel>>? _postsSubscription;

  ProfileViewModel({
    required IUserRepository userRepository,
    required IReminderRepository reminderRepository,
    required IPetRepository petRepository,
    required IPostRepository postRepository,
    NotificationService? notificationService,
  })  : _userRepo = userRepository,
        _reminderRepo = reminderRepository,
        _petRepo = petRepository,
        _postRepo = postRepository,
        _notifService = notificationService ?? NotificationService.instance {
    _subscribeToUser();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _petsSubscription?.cancel();
    _remindersSubscription?.cancel();
    _postsSubscription?.cancel();
    super.dispose();
  }

  // ── User state ─────────────────────────────────────────────────────────────

  UserModel _user = UserModel.empty();
  UserModel get user => _user;

  bool _isUserLoading = false;
  bool get isUserLoading => _isUserLoading;

  /// True while a profile photo upload is in progress.
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  /// Increments on each successful upload to bust [CachedNetworkImage] cache.
  int _imageVersion = 0;
  int get imageVersion => _imageVersion;

  String? _uploadError;
  String? get uploadError => _uploadError;

  /// True while [updateProfile] is writing to Firestore.
  bool _isSavingProfile = false;
  bool get isSavingProfile => _isSavingProfile;

  String? _profileError;
  String? get profileError => _profileError;

  // ── Pet state ──────────────────────────────────────────────────────────────

  List<PetModel> _pets = [];
  List<PetModel> get pets => List.unmodifiable(_pets);

  bool _isPetsLoading = false;
  bool get isPetsLoading => _isPetsLoading;

  bool _isAddingPet = false;
  bool get isAddingPet => _isAddingPet;

  String? _petError;
  String? get petError => _petError;

  // ── Post state ─────────────────────────────────────────────────────────────

  List<PostModel> _posts = [];
  List<PostModel> get posts => List.unmodifiable(_posts);

  bool _isPostsLoading = false;
  bool get isPostsLoading => _isPostsLoading;

  // ── Reminder state ─────────────────────────────────────────────────────────

  List<ReminderModel> _reminders = [];
  List<ReminderModel> get reminders => List.unmodifiable(_reminders);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ReminderModel> upcomingReminders({int maxCount = 3}) {
    return (_reminders.where((r) => !r.isCompleted).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime)))
        .take(maxCount)
        .toList(growable: false);
  }

  // ── User stream ────────────────────────────────────────────────────────────

  void _subscribeToUser() {
    _isUserLoading = true;
    _userSubscription = _userRepo.watchCurrentUser().listen(
      (user) {
        if (user != null) {
          final uidChanged = _user.id != user.id;
          _user = user;
          if (uidChanged && user.id.isNotEmpty) {
            _subscribeToPets(user.id);
            _subscribeToReminders(user.id);
            _subscribeToPosts(user.id);
          }
        } else {
          // Signed out — clear all per-user state immediately.
          _user = UserModel.empty();
          _pets = [];
          _petsSubscription?.cancel();
          _petsSubscription = null;
          _reminders = [];
          _remindersSubscription?.cancel();
          _remindersSubscription = null;
          _posts = [];
          _postsSubscription?.cancel();
          _postsSubscription = null;
        }
        _isUserLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isUserLoading = false;
        debugPrint('[ProfileViewModel] watchCurrentUser error: $e');
        notifyListeners();
      },
    );
  }

  void _subscribeToPets(String uid) {
    _petsSubscription?.cancel();
    _isPetsLoading = true;
    _petsSubscription = _petRepo.watchUserPets(uid).listen(
      (pets) {
        _pets = pets;
        _isPetsLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isPetsLoading = false;
        debugPrint('[ProfileViewModel] watchUserPets error: $e');
        notifyListeners();
      },
    );
  }

  // ── Post stream ────────────────────────────────────────────────────────────

  void _subscribeToPosts(String uid) {
    _postsSubscription?.cancel();
    _isPostsLoading = true;
    _postsSubscription = _postRepo.watchUserPosts(uid).listen(
      (posts) {
        _posts = posts;
        _isPostsLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isPostsLoading = false;
        debugPrint('[ProfileViewModel] watchUserPosts error: $e');
        notifyListeners();
      },
    );
  }

  // ── Photo upload ───────────────────────────────────────────────────────────

  Future<void> pickAndUploadProfileImage() async {
    _uploadError = null;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;

    _isUploading = true;
    notifyListeners();

    final result = await _userRepo.uploadProfileImage(File(picked.path));

    switch (result) {
      case Success(:final data):
        _user = _user.copyWith(profilePicture: data);
        _imageVersion++;
      case Failure(:final message):
        _uploadError = message;
        debugPrint('[ProfileViewModel] uploadProfileImage error: $message');
    }

    _isUploading = false;
    notifyListeners();
  }

  void clearUploadError() {
    _uploadError = null;
    notifyListeners();
  }

  /// Persists [name], [username], [bio], and [link] to the user's Firestore
  /// document (Step 55 — the Instagram-standard 4-field Edit Profile form).
  ///
  /// Returns `true` on success. On failure, returns `false` and populates
  /// [profileError] for the calling screen to surface. On success, [_user]
  /// is updated optimistically here (not just left to the [watchCurrentUser]
  /// stream) so [ProfileScreen]'s `Consumer<ProfileViewModel>` reflects the
  /// edit the instant this future resolves, rather than waiting on a round
  /// trip back through Firestore's real-time listener.
  Future<bool> updateUserProfile({
    required String name,
    required String username,
    required String bio,
    required String link,
  }) async {
    _isSavingProfile = true;
    _profileError = null;
    notifyListeners();

    final updated = _user.copyWith(
      name: name.trim(),
      username: username.trim(),
      bio: bio.trim(),
      link: link.trim(),
    );
    final result = await _userRepo.updateUserData(updated);

    _isSavingProfile = false;
    if (result case Failure(:final message)) {
      _profileError = message;
      notifyListeners();
      return false;
    }
    _user = updated;
    notifyListeners();
    return true;
  }

  void clearProfileError() {
    _profileError = null;
    notifyListeners();
  }

  Future<void> loadUser() async {
    final result = await _userRepo.getCurrentUser();
    if (result case Success(:final data)) {
      _user = data;
      notifyListeners();
    }
  }

  // ── Pet operations ─────────────────────────────────────────────────────────

  /// Uploads [image] (if any) and saves [pet] to Firestore.
  /// The real-time stream automatically updates [pets] on success.
  Future<void> addPet(
    PetModel pet, {
    File? image,
    File? vaccinationCardImage,
  }) async {
    _isAddingPet = true;
    _petError = null;
    notifyListeners();

    final result = await _petRepo.addPet(
      pet,
      image: image,
      vaccinationCardImage: vaccinationCardImage,
    );

    if (result case Failure(:final message)) {
      _petError = message;
      debugPrint('[ProfileViewModel] addPet error: $message');
    }

    _isAddingPet = false;
    notifyListeners();
  }

  /// Updates [pet] text fields and optionally swaps the photo.
  /// The real-time stream automatically refreshes [pets] on success.
  Future<void> updatePet(
    PetModel pet, {
    File? newImage,
    File? newVaccinationCardImage,
  }) async {
    _isAddingPet = true;
    _petError = null;
    notifyListeners();

    final result = await _petRepo.updatePet(
      pet,
      newImage: newImage,
      newVaccinationCardImage: newVaccinationCardImage,
    );

    if (result case Failure(:final message)) {
      _petError = message;
      debugPrint('[ProfileViewModel] updatePet error: $message');
    }

    _isAddingPet = false;
    notifyListeners();
  }

  /// Optimistically removes the pet from the list; rolls back on failure.
  Future<void> deletePet(String petId) async {
    final removed = _pets.firstWhereOrNull((p) => p.id == petId);
    if (removed == null) return;

    _pets = _pets.where((p) => p.id != petId).toList();
    notifyListeners();

    final result = await _petRepo.deletePet(removed);
    if (result case Failure(:final message)) {
      _pets = [..._pets, removed];
      _petError = message;
      notifyListeners();
    }
  }

  void clearPetError() {
    _petError = null;
    notifyListeners();
  }

  // ── Reminder stream ────────────────────────────────────────────────────────

  void _subscribeToReminders(String uid) {
    _remindersSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    _remindersSubscription = _reminderRepo.watchAll().listen(
      (reminders) {
        _reminders = reminders;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = 'Hatırlatıcılar yüklenemedi.';
        debugPrint('[ProfileViewModel] watchAll (reminders) error: $e');
        notifyListeners();
      },
    );
  }

  // ── Reminder operations ────────────────────────────────────────────────────

  /// Returns `true` once persisted, `false` if rolled back — lets
  /// [_AddReminderSheet] keep its form open (instead of popping and losing
  /// the user's input) when the write fails.
  Future<bool> addReminder(ReminderModel reminder) async {
    _reminders = [..._reminders, reminder]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();

    final result = await _reminderRepo.add(reminder);
    if (result case Failure(:final message)) {
      _reminders = _reminders.where((r) => r.id != reminder.id).toList();
      _errorMessage = message;
      notifyListeners();
      return false;
    }

    await _notifService.scheduleReminder(reminder);
    return true;
  }

  /// Returns `true` once the completion is confirmed persisted, `false` if
  /// it was rolled back — [PatiTakvimiWidget] awaits this to know whether
  /// to release its own optimistic "shown as completed" flag, which (unlike
  /// [_reminders] here) has no other way to learn a completion failed and
  /// was reverted.
  Future<bool> completeReminder(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx == -1) return true;

    final updated = _reminders[idx].copyWith(isCompleted: true);
    final previous = _reminders[idx];
    _reminders = List.of(_reminders)..[idx] = updated;
    notifyListeners();

    final result = await _reminderRepo.update(updated);
    if (result case Failure(:final message)) {
      _reminders = List.of(_reminders)..[idx] = previous;
      _errorMessage = message;
      notifyListeners();
      return false;
    }

    await _notifService.cancelReminder(id);
    return true;
  }

  Future<void> deleteReminder(String id) async {
    final removed = _reminders.firstWhereOrNull((r) => r.id == id);
    if (removed == null) return;

    _reminders = _reminders.where((r) => r.id != id).toList();
    notifyListeners();

    final result = await _reminderRepo.delete(id);
    if (result case Failure(:final message)) {
      _reminders = [..._reminders, removed]
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _errorMessage = message;
      notifyListeners();
      return;
    }

    await _notifService.cancelReminder(id);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
