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

  @override
  Future<Result<UserModel>> getCurrentUser() async {
    try {
      await Future.delayed(_delay);

      const p = SampleData.userProfile;
      final user = UserModel(
        id: 'current_user',
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
}
