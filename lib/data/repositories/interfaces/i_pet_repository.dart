import 'dart:io';

import '../../../core/result.dart';
import '../../models/pet_model.dart';

/// Abstract interface for pet-related data operations.
abstract class IPetRepository {
  /// Fetches all pets for the currently signed-in user.
  Future<Result<List<PetModel>>> getAllPets();

  /// Fetches a single pet by its [petId].
  Future<Result<PetModel>> getPetById(String petId);

  /// Fetches pets belonging to a specific user (one-time).
  Future<Result<List<PetModel>>> getUserPets(String userId);

  /// Emits [uid]'s pet list in real-time from `users/{uid}/pets`.
  Stream<List<PetModel>> watchUserPets(String uid);

  /// Uploads [image] to `pets/{ownerId}/{petName}_{timestamp}.jpg` (if
  /// provided), then saves [pet] to `users/{ownerId}/pets/{petId}`.
  ///
  /// The repository assigns the Firestore document ID; the returned
  /// [PetModel] has its [id] and [photoUrl] fields populated.
  Future<Result<PetModel>> addPet(PetModel pet, {File? image});

  /// Updates [pet]'s Firestore document.
  ///
  /// If [newImage] is provided, uploads it (replacing the old photo in
  /// Storage via [PetModel.photoUrl]) and stores the new download URL.
  Future<Result<void>> updatePet(PetModel pet, {File? newImage});

  /// Removes [pet]'s document from `users/{ownerId}/pets/` and deletes
  /// its Storage photo via the URL stored in [PetModel.photoUrl] (best-effort).
  Future<Result<void>> deletePet(PetModel pet);
}
