import '../../../core/result.dart';
import '../../models/pet_model.dart';
import '../../sample_data.dart';
import '../interfaces/i_pet_repository.dart';

/// Mock implementation of [IPetRepository].
///
/// Returns data from [SampleData] wrapped in [Future.delayed]
/// to simulate real-world network latency (~800ms).
class MockPetRepository implements IPetRepository {
  /// Simulated network delay duration.
  static const _delay = Duration(milliseconds: 800);

  List<PetModel> get _mockPets {
    return SampleData.userPets.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      return PetModel(
        id: 'pet_$i',
        ownerId: 'current_user',
        name: p['name']!,
        breed: p['breed']!,
        age: int.tryParse(p['age']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ??
            0,
        gender: PetGender.unknown,
        medicalHistorySummary: '',
        petType: _guessPetType(p['breed']!),
      );
    }).toList();
  }

  @override
  Future<Result<List<PetModel>>> getAllPets() async {
    try {
      await Future.delayed(_delay);
      return Success(_mockPets);
    } on Exception catch (e) {
      return Failure('Failed to load pets', exception: e);
    }
  }

  @override
  Future<Result<PetModel>> getPetById(String petId) async {
    try {
      await Future.delayed(_delay);
      final pet = _mockPets.firstWhere(
        (p) => p.id == petId,
        orElse: () => PetModel.empty(),
      );
      if (pet.isEmpty) {
        return Failure('Pet not found: $petId');
      }
      return Success(pet);
    } on Exception catch (e) {
      return Failure('Failed to load pet', exception: e);
    }
  }

  @override
  Future<Result<List<PetModel>>> getUserPets(String userId) async {
    try {
      await Future.delayed(_delay);
      final pets = _mockPets.where((p) => p.ownerId == userId).toList();
      return Success(pets);
    } on Exception catch (e) {
      return Failure('Failed to load user pets', exception: e);
    }
  }

  /// Guesses the [PetType] from a breed description string.
  static PetType _guessPetType(String breed) {
    final lower = breed.toLowerCase();
    if (lower.contains('cat') ||
        lower.contains('persian') ||
        lower.contains('siamese')) {
      return PetType.cat;
    }
    if (lower.contains('dog') ||
        lower.contains('retriever') ||
        lower.contains('bulldog')) {
      return PetType.dog;
    }
    if (lower.contains('bird') || lower.contains('parrot')) {
      return PetType.bird;
    }
    return PetType.other;
  }
}
