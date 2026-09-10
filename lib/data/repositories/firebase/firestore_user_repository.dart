import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/result.dart';
import '../../models/user_model.dart';
import '../interfaces/i_user_repository.dart';

/// Firestore implementation of [IUserRepository].
///
/// Reads and writes to the `users/{uid}` document in Firestore.
/// On first access, if the document doesn't exist yet, seeds it from
/// the Firebase Auth profile (displayName, photoURL) so the UI always
/// has something to show immediately after sign-up.
class FirestoreUserRepository implements IUserRepository {
  FirestoreUserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  @override
  Future<Result<UserModel>> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return const Failure('Oturum açık kullanıcı bulunamadı.');
      }

      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        // Always ensure id is set; fall back to Auth fields for name/photo
        // if the stored values are empty (e.g. legacy documents).
        final user = UserModel.fromJson({
          ...data,
          'id': firebaseUser.uid,
          if ((data['name'] as String? ?? '').isEmpty)
            'name': firebaseUser.displayName ?? '',
          if ((data['profilePicture'] as String? ?? '').isEmpty)
            'profilePicture': firebaseUser.photoURL ?? '',
        });
        return Success(user);
      }

      // Document doesn't exist — seed it from Firebase Auth profile so
      // subsequent reads don't hit Auth again.
      final user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        bio: '',
        profilePicture: firebaseUser.photoURL ?? '',
        locationDistrict: '',
        ownedPetIds: const [],
      );
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toJson());
      return Success(user);
    } on Exception catch (e) {
      return Failure('Kullanıcı profili yüklenemedi.', exception: e);
    }
  }

  /// Streams the `users/{uid}` document in real-time.
  ///
  /// Wraps Firebase Auth's `authStateChanges` so the stream reacts to
  /// sign-out (emits null) and account switches (emits the new user's
  /// Firestore document) without needing to re-subscribe.
  @override
  Stream<UserModel?> watchCurrentUser() {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);

      return _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        final data = doc.data()!;
        return UserModel.fromJson({
          ...data,
          'id': firebaseUser.uid,
          if ((data['name'] as String? ?? '').isEmpty)
            'name': firebaseUser.displayName ?? '',
          if ((data['profilePicture'] as String? ?? '').isEmpty)
            'profilePicture': firebaseUser.photoURL ?? '',
        });
      });
    });
  }

  @override
  Future<Result<void>> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true));
      return const Success(null);
    } on Exception catch (e) {
      return Failure('Profil güncellenemedi.', exception: e);
    }
  }

  /// Profil fotoğrafını Firebase Storage'a yükler ve her iki kaynağı günceller.
  ///
  /// **Adım 1 — Storage yüklemesi**
  /// `users/{uid}/profile_image.jpg` yoluna yüklenir. Sabit dosya adı
  /// kullanılır; bu sayede her yüklemede eski fotoğraf otomatik olarak
  /// üzerine yazılır ve Storage'da yetim dosya birikmez.
  ///
  /// **Adım 2 — Download URL**
  /// Yükleme tamamlanmadan URL alınamaz; [putFile] await edilir.
  ///
  /// **Adım 3 — Çift senkronizasyon**
  /// • Firestore `users/{uid}.profilePicture` → yeni URL
  /// • Firebase Auth `photoURL`               → yeni URL
  ///
  /// Her iki güncelleme de paralel çalıştırılır ([Future.wait]).
  @override
  Future<Result<String>> uploadProfileImage(File imageFile) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return const Failure('Oturum açık kullanıcı bulunamadı.');
      }

      // Adım 1 — Storage'a yükle
      final storageRef = _storage
          .ref()
          .child('users/${firebaseUser.uid}/profile_image.jpg');

      await storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Adım 2 — Download URL al
      final downloadUrl = await storageRef.getDownloadURL();

      // Adım 3 — Firestore ve Auth'u paralel güncelle
      await Future.wait([
        _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set({'profilePicture': downloadUrl}, SetOptions(merge: true)),
        firebaseUser.updatePhotoURL(downloadUrl),
      ]);

      return Success(downloadUrl);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Profil fotoğrafı yüklenemedi.', exception: e);
    }
  }

  /// Searches users by display-name prefix (case-insensitive, up to 20 results).
  ///
  /// **Fan-out strategy** — three Firestore queries run in parallel to cover
  /// every document shape that can exist in the collection:
  ///
  ///   1. `nameLower` range  — documents written by the updated app
  ///      (`UserModel.toJson()` stores `nameLower = name.toLowerCase()`).
  ///      Query: `nameLower >= lower` AND `nameLower <= lower + '\uf8ff'`.
  ///
  ///   2. `name` range (capitalized) — legacy documents that have a `name`
  ///      field but no `nameLower` field.
  ///      Query: `name >= capitalized` AND `name <= capitalized + '\uf8ff'`.
  ///
  ///   3. `displayName` range (capitalized) — manually seeded fixtures or
  ///      documents that use the Firebase Auth field name (e.g. `test_user_99`
  ///      with `displayName: "Pati Dostu Test"`).
  ///      Query: `displayName >= capitalized` AND `displayName <= capitalized + '\uf8ff'`.
  ///
  /// Results from all three are merged, deduplicated by document ID, filtered
  /// to exclude the signed-in user, and capped at 20 items.
  ///
  /// Cost: 3 × 1 Firestore read-request per search. Each request returns at
  /// most `_kSearchLimit` docs, so the ceiling is `3 × _kSearchLimit` reads
  /// per query.
  @override
  Future<Result<List<UserModel>>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const Success([]);

    try {
      final lower = trimmed.toLowerCase();
      // First-letter-capitalised variant covers stored `name` / `displayName`
      // fields where the value starts with an uppercase letter.
      final capitalized =
          lower[0].toUpperCase() + (lower.length > 1 ? lower.substring(1) : '');
      final uid = _auth.currentUser?.uid;
      const kSearchLimit = 20;

      // Fire all three queries simultaneously.
      final snapshots = await Future.wait([
        // Q1: nameLower — covers new app-written documents (case-insensitive)
        _firestore
            .collection('users')
            .where('nameLower', isGreaterThanOrEqualTo: lower)
            .where('nameLower', isLessThanOrEqualTo: '$lower\uf8ff')
            .limit(kSearchLimit)
            .get(),
        // Q2: name — covers legacy documents with plain `name` field
        _firestore
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: capitalized)
            .where('name', isLessThanOrEqualTo: '$capitalized\uf8ff')
            .limit(kSearchLimit)
            .get(),
        // Q3: displayName — covers manually seeded / Firebase-Auth-style docs
        _firestore
            .collection('users')
            .where('displayName', isGreaterThanOrEqualTo: capitalized)
            .where('displayName', isLessThanOrEqualTo: '$capitalized\uf8ff')
            .limit(kSearchLimit)
            .get(),
      ]);

      // Flatten, deduplicate by document ID, exclude self, cap at 20.
      final seen = <String>{};
      final users = <UserModel>[];

      for (final snap in snapshots) {
        for (final doc in snap.docs) {
          if (seen.contains(doc.id)) continue;
          if (doc.id == uid) continue; // exclude signed-in user
          seen.add(doc.id);
          users.add(UserModel.fromJson({'id': doc.id, ...doc.data()}));
        }
        if (users.length >= kSearchLimit) break;
      }

      return Success(users.take(kSearchLimit).toList());
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Arama başarısız oldu.', exception: e);
    }
  }

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok.';
      case 'object-not-found':
        return 'Dosya bulunamadı.';
      case 'canceled':
        return 'Yükleme iptal edildi.';
      case 'storage/unknown':
      default:
        return e.message ?? 'Beklenmedik bir hata oluştu.';
    }
  }
}
