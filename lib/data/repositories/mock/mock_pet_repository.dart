import 'dart:async';
import 'dart:io';

import '../../../core/result.dart';
import '../../models/pet_model.dart';
import '../../sample_data.dart';
import '../interfaces/i_pet_repository.dart';

/// Mock implementation of [IPetRepository].
///
/// Returns data from [SampleData] with simulated latency.
/// Mutations update an in-memory list and push to the stream.
class MockPetRepository implements IPetRepository {
  static const _delay = Duration(milliseconds: 800);

  late final List<PetModel> _pets = SampleData.userPets
      .asMap()
      .entries
      .map((entry) {
        final i = entry.key;
        final p = entry.value;
        return PetModel(
          id: 'pet_$i',
          ownerId: 'current_user',
          name: p['name']!,
          breed: p['breed']!,
          age: int.tryParse(
                  p['age']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ??
              0,
          gender: PetGender.unknown,
          medicalHistorySummary: '',
          petType: _guessPetType(p['breed']!),
          photoUrl: p['image'] ?? '',
          bio: '',
        );
      })
      .toList();

  StreamController<List<PetModel>>? _controller;
  int _idCounter = 100;

  // ── Stream ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<PetModel>> watchUserPets(String uid) {
    _controller?.close();
    _controller = StreamController<List<PetModel>>.broadcast();
    Future.microtask(_emit);
    return _controller!.stream;
  }

  void _emit() {
    if (!(_controller?.isClosed ?? true)) {
      _controller?.add(List.unmodifiable(_pets));
    }
  }

  // ── Write: add ─────────────────────────────────────────────────────────────

  @override
  Future<Result<PetModel>> addPet(PetModel pet, {File? image}) async {
    try {
      await Future.delayed(_delay);
      final newPet = pet.copyWith(id: 'pet_${_idCounter++}');
      _pets.add(newPet);
      _emit();
      return Success(newPet);
    } on Exception catch (e) {
      return Failure('Evcil hayvan eklenemedi.', exception: e);
    }
  }

  // ── Write: update ──────────────────────────────────────────────────────────

  @override
  Future<Result<void>> updatePet(PetModel pet, {File? newImage}) async {
    try {
      await Future.delayed(_delay);
      final idx = _pets.indexWhere((p) => p.id == pet.id);
      if (idx == -1) return Failure('Pet not found: ${pet.id}');
      _pets[idx] = pet;
      _emit();
      return const Success(null);
    } on Exception catch (e) {
      return Failure('Evcil hayvan güncellenemedi.', exception: e);
    }
  }

  // ── Write: delete ──────────────────────────────────────────────────────────

  @override
  Future<Result<void>> deletePet(PetModel pet) async {
    try {
      await Future.delayed(_delay);
      _pets.removeWhere((p) => p.id == pet.id);
      _emit();
      return const Success(null);
    } on Exception catch (e) {
      return Failure('Evcil hayvan silinemedi.', exception: e);
    }
  }

  // ── Read operations ────────────────────────────────────────────────────────

  @override
  Future<Result<List<PetModel>>> getAllPets() async {
    try {
      await Future.delayed(_delay);
      return Success(List.unmodifiable(_pets));
    } on Exception catch (e) {
      return Failure('Evcil hayvanlar yüklenemedi.', exception: e);
    }
  }

  @override
  Future<Result<PetModel>> getPetById(String petId) async {
    try {
      await Future.delayed(_delay);
      final pet = _pets.firstWhere(
        (p) => p.id == petId,
        orElse: PetModel.empty,
      );
      if (pet.isEmpty) return Failure('Pet not found: $petId');
      return Success(pet);
    } on Exception catch (e) {
      return Failure('Evcil hayvan yüklenemedi.', exception: e);
    }
  }

  @override
  Future<Result<List<PetModel>>> getUserPets(String userId) async {
    try {
      await Future.delayed(_delay);
      return Success(List.unmodifiable(_pets));
    } on Exception catch (e) {
      return Failure('Evcil hayvanlar yüklenemedi.', exception: e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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
