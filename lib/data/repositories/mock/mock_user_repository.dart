import 'dart:io';

import '../../../core/result.dart';
import '../../models/user_model.dart';
import '../../sample_data.dart';
import '../interfaces/i_user_repository.dart';

/// Mock implementation of [IUserRepository].
///
/// Returns data from [SampleData] wrapped in [Future.delayed]
/// to simulate real-world network latency (~800ms).
class MockUserRepository implements IUserRepository {
  /// Simulated network delay duration.
  static const _delay = Duration(milliseconds: 800);

  UserModel? _overriddenUser;

  @override
  Future<Result<UserModel>> getCurrentUser() async {
    try {
      await Future.delayed(_delay);

      if (_overriddenUser != null) return Success(_overriddenUser!);

      const p = SampleData.userProfile;
      final user = UserModel(
        id: 'current_user',
        email: 'demo@espati.com',
        name: p['name'] as String,
        bio: p['bio'] as String,
        profilePicture: p['avatar'] as String,
        locationDistrict: 'Eskişehir',
        ownedPetIds:
            SampleData.userPets.asMap().keys.map((i) => 'pet_$i').toList(),
      );

      return Success(user);
    } on Exception catch (e) {
      return Failure('Failed to load user profile', exception: e);
    }
  }

  @override
  Future<Result<void>> updateUserData(UserModel user) async {
    await Future.delayed(_delay);
    _overriddenUser = user;
    return const Success(null);
  }

  @override
  Stream<UserModel?> watchCurrentUser() async* {
    await Future.delayed(_delay);
    // Yield once — mock doesn't have real-time updates.
    yield _overriddenUser ?? await _buildMockUser();
  }

  Future<UserModel> _buildMockUser() async {
    const p = SampleData.userProfile;
    return UserModel(
      id: 'current_user',
      email: 'demo@espati.com',
      name: p['name'] as String,
      bio: p['bio'] as String,
      profilePicture: p['avatar'] as String,
      locationDistrict: 'Eskişehir',
      ownedPetIds:
          SampleData.userPets.asMap().keys.map((i) => 'pet_$i').toList(),
      followersCount: 128,
      followingCount: 64,
    );
  }

  @override
  Future<Result<String>> uploadProfileImage(File imageFile) async {
    // Mock: simulate upload delay and return a placeholder URL.
    await Future.delayed(const Duration(seconds: 2));
    const fakeUrl =
        'https://ui-avatars.com/api/?name=Demo+User&background=FFCBA4&color=fff&size=200';
    _overriddenUser = _overriddenUser?.copyWith(profilePicture: fakeUrl);
    return const Success(fakeUrl);
  }

  @override
  Future<Result<List<UserModel>>> searchUsers(String query) async {
    await Future.delayed(_delay);
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return const Success([]);
    final results = _mockUsers
        .where((u) => u.name.toLowerCase().startsWith(lower))
        .toList();
    return Success(results);
  }

  static final List<UserModel> _mockUsers = [
    UserModel(
      id: 'user_1',
      email: 'ayse@espati.com',
      name: 'Ayşe Kaya',
      bio: 'Labrador annesi 🐶',
      profilePicture: '',
      locationDistrict: 'Tepebaşı',
      ownedPetIds: ['pet_1'],
      followersCount: 42,
      followingCount: 18,
    ),
    UserModel(
      id: 'user_2',
      email: 'mehmet@espati.com',
      name: 'Mehmet Demir',
      bio: 'İki kedinin babası 🐱',
      profilePicture: '',
      locationDistrict: 'Odunpazarı',
      ownedPetIds: ['pet_2'],
      followersCount: 75,
      followingCount: 30,
    ),
    UserModel(
      id: 'user_3',
      email: 'zeynep@espati.com',
      name: 'Zeynep Arslan',
      bio: 'Porsuk kıyısı yürüyüşçüsü 🐕',
      profilePicture: '',
      locationDistrict: 'Eskişehir Merkez',
      ownedPetIds: ['pet_3'],
      followersCount: 120,
      followingCount: 55,
    ),
    UserModel(
      id: 'user_4',
      email: 'ali@espati.com',
      name: 'Ali Yıldız',
      bio: 'Golden Retriever aşığı ☀️',
      profilePicture: '',
      locationDistrict: 'Sazova',
      ownedPetIds: [],
      followersCount: 33,
      followingCount: 12,
    ),
  ];
}
