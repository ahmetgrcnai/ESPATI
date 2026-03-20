import '../../../core/result.dart';
import '../../models/user_model.dart';

/// Abstract interface for user-related data operations.
///
/// Implementations can fetch from local mock data, REST API, or Firebase.
abstract class IUserRepository {
  /// Fetches the currently logged-in user profile.
  Future<Result<UserModel>> getCurrentUser();
}
