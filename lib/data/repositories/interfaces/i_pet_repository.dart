import '../../../core/result.dart';
import '../../models/pet_model.dart';

/// Abstract interface for pet-related data operations.
///
/// Implementations can fetch from local mock data, REST API, or Firebase.
abstract class IPetRepository {
  /// Fetches all pets.
  Future<Result<List<PetModel>>> getAllPets();

  /// Fetches a single pet by its [petId].
  Future<Result<PetModel>> getPetById(String petId);

  /// Fetches pets belonging to a specific user.
  Future<Result<List<PetModel>>> getUserPets(String userId);
}
