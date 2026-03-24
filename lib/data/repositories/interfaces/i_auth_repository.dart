import 'dart:async';

import '../../../core/result.dart';
import '../../models/user_model.dart';

/// Contract for all authentication operations in ESPATI.
///
/// Implementations (Firebase, mock, etc.) must translate provider-specific
/// errors into user-friendly [Failure] messages before returning, so that
/// ViewModels and UI never depend on [firebase_auth] exceptions directly.
///
/// All mutating operations return [Result<UserModel>] or [Result<void>].
/// Read-only state is exposed via [authStateChanges] and [currentUser].
abstract class IAuthRepository {
  // ── State ──────────────────────────────────────────────────────────────────

  /// Emits a [UserModel] when a user signs in, and [null] when they sign out.
  ///
  /// Subscribe once (e.g. in [AuthViewModel]) and let the stream drive
  /// navigation — avoids manual checks scattered across the app.
  Stream<UserModel?> get authStateChanges;

  /// The currently signed-in user, or [null] if no session is active.
  ///
  /// Synchronous — safe to read without awaiting.
  UserModel? get currentUser;

  // ── Email / Password ───────────────────────────────────────────────────────

  /// Signs in an existing user with [email] and [password].
  ///
  /// Returns [Success<UserModel>] on success, or a [Failure] with a
  /// localised message on wrong credentials, network issues, etc.
  Future<Result<UserModel>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates a new account and sets the Firebase Auth display name.
  ///
  /// [displayName] is stored in Firebase Auth profile.
  /// Returns [Success<UserModel>] with the freshly created profile.
  Future<Result<UserModel>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  // ── Google ─────────────────────────────────────────────────────────────────

  /// Starts the Google Sign-In flow and links it to Firebase Auth.
  ///
  /// On first sign-in a new profile is created; on subsequent
  /// sign-ins the existing session is restored.
  Future<Result<UserModel>> signInWithGoogle();

  // ── Session ────────────────────────────────────────────────────────────────

  /// Signs out the current user from all providers.
  Future<Result<void>> signOut();

  // ── Password recovery ──────────────────────────────────────────────────────

  /// Sends a password-reset e-mail to [email].
  ///
  /// Returns [Success<void>] even if the address is not registered —
  /// this prevents user enumeration attacks.
  Future<Result<void>> sendPasswordResetEmail({required String email});
}
