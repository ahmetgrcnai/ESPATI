import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../data/models/pati_video_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PATIES SERVICE (Phase 6 Step 15 — "Summit B": real Shorts/Reels backend)
//
// Uploads a raw .mp4 to Firebase Storage and writes its metadata document to
// Firestore, and streams the live feed [PatiesViewerScreen] renders. A plain
// singleton service (same shape as [ClaudeService]/
// [InteractionTrackingService]) rather than an IRepository — Paties is a
// single, self-contained vertical with no mock/Firebase swap requirement,
// so the extra interface layer isn't earning its keep here.
// ─────────────────────────────────────────────────────────────────────────────

class PatiesService {
  PatiesService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  static final PatiesService instance = PatiesService();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _kCollection = 'paties_videos';

  // ── Read — live feed ────────────────────────────────────────────────────────

  /// Streams the most recent Paties videos, newest first.
  ///
  /// `.limit(50)` guards against an unbounded listener re-reading the whole
  /// collection on every write as it grows — same cost-control reasoning as
  /// [FirestorePostRepository.getSocialFeed]. A corrupt document is skipped
  /// rather than breaking the whole stream.
  Stream<List<PatiVideoModel>> watchPatiesFeed() {
    return _firestore
        .collection(_kCollection)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final videos = <PatiVideoModel>[];
      for (final doc in snapshot.docs) {
        try {
          videos.add(PatiVideoModel.fromFirestore(doc));
        } catch (_) {
          // Skip malformed document — don't take down the whole stream.
        }
      }
      return videos;
    });
  }

  // ── Write — upload ────────────────────────────────────────────────────────

  /// Uploads [videoFile] (raw .mp4) to
  /// `paties_videos/{videoId}.mp4` in Firebase Storage, then writes the
  /// metadata document to `paties_videos/{videoId}` in Firestore.
  ///
  /// [authorId]/[authorName]/[authorPhoto] are supplied by the caller (the
  /// already-signed-in [AuthViewModel.currentUser]) rather than re-derived
  /// here from `FirebaseAuth.currentUser`, matching how
  /// [CreatePostViewModel]/[ListingFormScreen] build their models — the
  /// display name/photo live on the app's own [UserModel], not on the
  /// Firebase Auth profile.
  ///
  /// If the Storage upload succeeds but the Firestore write fails, an
  /// orphaned Storage file may remain — same documented trade-off as
  /// [FirestorePostRepository.createPost] / [FirestoreFormRepository.createListing].
  Future<Result<PatiVideoModel>> uploadVideo({
    required File videoFile,
    required String authorId,
    required String authorName,
    required String authorPhoto,
    String description = '',
  }) async {
    if (authorId.isEmpty) {
      return const Failure('Video paylaşmak için giriş yapmanız gerekiyor.');
    }

    try {
      final docRef = _firestore.collection(_kCollection).doc();
      final videoId = docRef.id;

      final storageRef = _storage.ref().child('paties_videos/$videoId.mp4');
      final uploadTask = storageRef.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );
      await uploadTask.timeout(const Duration(minutes: 5));

      final videoUrl = await storageRef.getDownloadURL();

      final video = PatiVideoModel(
        id: videoId,
        videoUrl: videoUrl,
        description: description.trim(),
        timestamp: DateTime.now(),
        authorId: authorId,
        authorName: authorName,
        authorPhoto: authorPhoto,
      );

      await docRef.set(video.toFirestore()).timeout(const Duration(seconds: 15));

      return Success(video);
    } on FirebaseException catch (e) {
      debugPrint('[PatiesService] uploadVideo FirebaseException: ${e.code} ${e.message}');
      return Failure(_mapFirebaseError(e), exception: e);
    } on TimeoutException {
      return const Failure(
        'Video yükleme zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.',
      );
    } catch (e) {
      debugPrint('[PatiesService] uploadVideo failed: $e');
      return Failure('Video yüklenemedi. Lütfen tekrar deneyin.',
          exception: e is Exception ? e : null);
    }
  }

  // ── Write — delete ────────────────────────────────────────────────────────

  /// Removes a video that a client has confirmed is unplayable: best-effort
  /// deletes the Storage file, then the Firestore metadata document.
  ///
  /// Self-healing cleanup driven by [PatiesViewerScreen] — when a device
  /// can't decode a video after a retry, the underlying file is corrupt or
  /// in an unsupported codec for every viewer, not just that one device, so
  /// the broken document is removed for good rather than left to keep
  /// failing. Storage deletion runs first but its failure doesn't block the
  /// Firestore delete — an `object-not-found` there just means the original
  /// upload never finished writing the file, which is exactly the kind of
  /// broken entry this is meant to clear out.
  Future<void> deleteVideo(PatiVideoModel video) async {
    if (video.videoUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(video.videoUrl).delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') {
          debugPrint(
              '[PatiesService] deleteVideo storage cleanup failed: ${e.code}');
        }
      } catch (e) {
        debugPrint('[PatiesService] deleteVideo storage cleanup failed: $e');
      }
    }

    try {
      await _firestore.collection(_kCollection).doc(video.id).delete();
    } catch (e) {
      debugPrint('[PatiesService] deleteVideo Firestore delete failed: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
      case 'unauthorized':
        return 'Bu işlem için yetkiniz yok.';
      case 'unavailable':
        return 'Sunucu şu anda kullanılamıyor. Lütfen tekrar deneyin.';
      case 'deadline-exceeded':
        return 'İstek zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.';
      case 'resource-exhausted':
        return 'Servis kotası doldu. Lütfen daha sonra tekrar deneyin.';
      case 'object-not-found':
        return 'Dosya bulunamadı.';
      case 'canceled':
        return 'İşlem iptal edildi.';
      default:
        return e.message ?? 'Beklenmedik bir hata oluştu.';
    }
  }
}
