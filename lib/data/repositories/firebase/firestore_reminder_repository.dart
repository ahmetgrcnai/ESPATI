import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/result.dart';
import '../../models/reminder_model.dart';
import '../interfaces/i_reminder_repository.dart';

/// Firestore implementation of [IReminderRepository].
///
/// Firestore path: `users/{uid}/reminders/{reminderId}`.
///
/// A subcollection under the user document — not a top-level `reminders`
/// collection with a `userId` field — mirrors [FirestorePetRepository]'s
/// `users/{uid}/pets` convention already used in this codebase. Every read
/// and write here is already scoped to the signed-in user (the interface
/// takes no `userId` parameter), so no cross-user query is ever needed and
/// no composite index has to be maintained for a `userId` filter. A
/// reminder's own [ReminderModel.petId] field (nullable — "applies to all
/// pets") stays independent of this path; it is not a second-level
/// subcollection key because a null `petId` would have nowhere to live.
class FirestoreReminderRepository implements IReminderRepository {
  FirestoreReminderRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _remindersCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('reminders');

  @override
  Future<Result<List<ReminderModel>>> getAll() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Failure('Oturum açık kullanıcı bulunamadı.');

      final snap = await _remindersCol(uid).orderBy('dateTime').get();
      final reminders = snap.docs.map(ReminderModel.fromFirestore).toList();
      return Success(reminders);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Hatırlatıcılar yüklenemedi.', exception: e);
    }
  }

  @override
  Stream<List<ReminderModel>> watchAll() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    return _remindersCol(uid).orderBy('dateTime').snapshots().map(
          (snap) => snap.docs.map(ReminderModel.fromFirestore).toList(),
        );
  }

  /// Writes under the caller-supplied [ReminderModel.id] rather than letting
  /// Firestore auto-generate a document ID.
  ///
  /// [ProfileViewModel.addReminder] schedules the device notification using
  /// this same client-generated ID (see `reminder_manager_screen.dart`), and
  /// later calls [NotificationService.cancelReminder] with whatever ID is on
  /// the reconciled [ReminderModel] coming back from [watchAll]. If Firestore
  /// assigned its own ID here, that reconciled ID would silently diverge from
  /// the one the notification was scheduled under, orphaning it on the device.
  @override
  Future<Result<ReminderModel>> add(ReminderModel reminder) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Failure('Oturum açık kullanıcı bulunamadı.');

      await _remindersCol(uid).doc(reminder.id).set(reminder.toFirestore());
      return Success(reminder);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Hatırlatıcı eklenemedi.', exception: e);
    }
  }

  @override
  Future<Result<void>> update(ReminderModel reminder) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Failure('Oturum açık kullanıcı bulunamadı.');

      await _remindersCol(uid).doc(reminder.id).set(reminder.toFirestore());
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Hatırlatıcı güncellenemedi.', exception: e);
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Failure('Oturum açık kullanıcı bulunamadı.');

      await _remindersCol(uid).doc(id).delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Hatırlatıcı silinemedi.', exception: e);
    }
  }

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok.';
      case 'not-found':
        return 'Hatırlatıcı bulunamadı.';
      case 'canceled':
        return 'İşlem iptal edildi.';
      default:
        return e.message ?? 'Beklenmedik bir hata oluştu.';
    }
  }
}
