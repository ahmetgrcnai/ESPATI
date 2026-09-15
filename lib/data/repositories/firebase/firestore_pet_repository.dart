import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/result.dart';
import '../../models/pet_model.dart';
import '../interfaces/i_pet_repository.dart';

/// Firestore implementation of [IPetRepository].
///
/// Firestore path : `users/{uid}/pets/{petId}`
/// Storage path   : `users/{uid}/pets/{petId}.jpg`
class FirestorePetRepository implements IPetRepository {
  FirestorePetRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _petsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('pets');

  // ── Real-time stream ───────────────────────────────────────────────────────

  @override
  Stream<List<PetModel>> watchUserPets(String uid) {
    return _petsCol(uid).orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((doc) => PetModel.fromFirestore(doc.data(), id: doc.id))
              .toList(),
        );
  }

  // ── Write: add ─────────────────────────────────────────────────────────────

  @override
  Future<Result<PetModel>> addPet(
    PetModel pet, {
    File? image,
    File? vaccinationCardImage,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Failure('Oturum açık kullanıcı bulunamadı.');

      final docRef = _petsCol(uid).doc();
      final petId = docRef.id;

      final photoUrl =
          image != null ? await _uploadPhoto(uid, petId, image) : '';
      final vaccinationCardUrl = vaccinationCardImage != null
          ? await _uploadVaccinationCard(uid, petId, vaccinationCardImage)
          : '';

      final finalPet = pet.copyWith(
        id: petId,
        ownerId: uid,
        photoUrl: photoUrl,
        vaccinationCardUrl: vaccinationCardUrl,
      );
      await docRef.set(finalPet.toFirestore());
      return Success(finalPet);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Evcil hayvan eklenemedi.', exception: e);
    }
  }

  // ── Write: update ──────────────────────────────────────────────────────────

  @override
  Future<Result<void>> updatePet(
    PetModel pet, {
    File? newImage,
    File? newVaccinationCardImage,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Failure('Oturum açık kullanıcı bulunamadı.');

      String photoUrl = pet.photoUrl;

      if (newImage != null) {
        // Upload replacement photo — deterministic per-pet path means this
        // overwrites the previous file in place, so no separate delete step
        // is needed for photos already stored under the current path scheme.
        photoUrl = await _uploadPhoto(uid, pet.id, newImage);

        // Best-effort cleanup for photos uploaded under the legacy
        // `pets/{uid}/{name}_{timestamp}.jpg` path (pre-fix data).
        if (pet.photoUrl.isNotEmpty && pet.photoUrl != photoUrl) {
          try {
            await _storage.refFromURL(pet.photoUrl).delete();
          } catch (_) {}
        }
      }

      String vaccinationCardUrl = pet.vaccinationCardUrl;
      if (newVaccinationCardImage != null) {
        vaccinationCardUrl =
            await _uploadVaccinationCard(uid, pet.id, newVaccinationCardImage);
      }

      final updated = pet.copyWith(
        photoUrl: photoUrl,
        vaccinationCardUrl: vaccinationCardUrl,
      );
      await _petsCol(uid)
          .doc(pet.id)
          .set(updated.toFirestore(), SetOptions(merge: true));
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Evcil hayvan güncellenemedi.', exception: e);
    }
  }

  // ── Write: delete ──────────────────────────────────────────────────────────

  @override
  Future<Result<void>> deletePet(PetModel pet) async {
    try {
      await _petsCol(pet.ownerId).doc(pet.id).delete();

      if (pet.photoUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(pet.photoUrl).delete();
        } catch (_) {}
      }
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Evcil hayvan silinemedi.', exception: e);
    }
  }

  // ── Read operations ────────────────────────────────────────────────────────

  @override
  Future<Result<List<PetModel>>> getAllPets() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Success([]);
    return getUserPets(uid);
  }

  @override
  Future<Result<List<PetModel>>> getUserPets(String userId) async {
    try {
      final snap = await _petsCol(userId).orderBy('name').get();
      final pets = snap.docs
          .map((doc) => PetModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
      return Success(pets);
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Evcil hayvanlar yüklenemedi.', exception: e);
    }
  }

  @override
  Future<Result<PetModel>> getPetById(String petId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Failure('Oturum açık kullanıcı bulunamadı.');
      final doc = await _petsCol(uid).doc(petId).get();
      if (!doc.exists || doc.data() == null) {
        return Failure('Evcil hayvan bulunamadı: $petId');
      }
      return Success(PetModel.fromFirestore(doc.data()!, id: doc.id));
    } on FirebaseException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Evcil hayvan yüklenemedi.', exception: e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Uploads [image] and returns its public download URL.
  ///
  /// Path: `users/{uid}/pets/{petId}.jpg` — mirrors the Firestore document
  /// path (`users/{uid}/pets/{petId}`) and the app's existing
  /// `users/{uid}/...` Storage convention (see profile photo uploads in
  /// [FirestoreUserRepository]), so it falls under the same security rules
  /// that already grant the owning user read/write access to their own tree.
  Future<String> _uploadPhoto(String uid, String petId, File image) async {
    final ref = _storage.ref().child('users/$uid/pets/$petId.jpg');
    await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Çiftleşme module's aşı karnesi proof photo — same path convention as
  /// [_uploadPhoto], just a distinct filename so it never collides with the
  /// main pet photo.
  ///
  /// Path: `users/{uid}/pets/{petId}_vaccination.jpg`
  Future<String> _uploadVaccinationCard(
      String uid, String petId, File image) async {
    final ref =
        _storage.ref().child('users/$uid/pets/${petId}_vaccination.jpg');
    await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  String _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
      case 'unauthorized':
        return 'Bu işlem için yetkiniz yok.';
      case 'object-not-found':
        return 'Dosya bulunamadı.';
      case 'canceled':
        return 'İşlem iptal edildi.';
      default:
        return e.message ?? 'Beklenmedik bir hata oluştu.';
    }
  }
}
