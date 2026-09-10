import 'dart:io';

import '../../../core/result.dart';
import '../../models/user_model.dart';

/// Abstract interface for user-related data operations.
///
/// Implementations can fetch from local mock data, REST API, or Firebase.
abstract class IUserRepository {
  /// Fetches the currently logged-in user profile (one-time).
  Future<Result<UserModel>> getCurrentUser();

  /// Emits the current user's profile in real-time.
  ///
  /// Useful for keeping follower/following counts live on the ProfileScreen
  /// without manual polling. Emits `null` when no user is signed in.
  Stream<UserModel?> watchCurrentUser();

  /// Persists [user] data to the backing store.
  Future<Result<void>> updateUserData(UserModel user);

  /// Uploads [imageFile] to storage at `users/{uid}/profile_image.jpg`,
  /// then updates both the Firestore document and the Firebase Auth profile
  /// with the new download URL.
  ///
  /// Returns the public download URL on success.
  Future<Result<String>> uploadProfileImage(File imageFile);

  /// Searches users whose display name starts with [query] (case-insensitive).
  ///
  /// Uses a Firestore range query on the `nameLower` field:
  ///   `nameLower >= query.toLowerCase()`
  ///   `nameLower <= query.toLowerCase() + '\uf8ff'`
  ///
  /// The `\uf8ff` sentinel is the highest Unicode code point in the BMP,
  /// so the range matches every string with the given prefix.
  ///
  /// Returns an empty list when [query] is blank or no matches are found.
  Future<Result<List<UserModel>>> searchUsers(String query);
}
