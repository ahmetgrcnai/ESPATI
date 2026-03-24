import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../data/models/user_model.dart';
import '../data/repositories/interfaces/i_auth_repository.dart';

// ── Auth state enum ────────────────────────────────────────────────────────────

/// Represents the three possible authentication states of the app.
///
/// [unknown]         — stream has not emitted yet; show splash / loading UI.
/// [authenticated]   — a valid session exists; navigate to main app.
/// [unauthenticated] — no session; navigate to login screen.
enum AuthState { unknown, authenticated, unauthenticated }

// ── ViewModel ─────────────────────────────────────────────────────────────────

/// Manages authentication state and exposes auth operations to the UI.
///
/// Subscribes to [IAuthRepository.authStateChanges] in the constructor and
/// cancels the subscription in [dispose] — the stream drives navigation,
/// no manual polling is ever needed.
///
/// Loading semantics:
///   • [isLoading]    — stream is initialising; suppress auth screens (show splash).
///   • [isSubmitting] — a button action is in flight; disable inputs and buttons.
class AuthViewModel extends ChangeNotifier {
  final IAuthRepository _authRepository;

  AuthViewModel({required IAuthRepository authRepository})
      : _authRepository = authRepository {
    _subscribeToAuthState();
  }

  // ── State ──────────────────────────────────────────────────────────────────

  AuthState _authState = AuthState.unknown;
  AuthState get authState => _authState;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  /// True while the [authStateChanges] stream is resolving on app start.
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// True while a sign-in / sign-up / sign-out call is in flight.
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // ── Stream subscription ────────────────────────────────────────────────────

  late final StreamSubscription<UserModel?> _authSubscription;

  void _subscribeToAuthState() {
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) {
        _currentUser = user;
        _authState =
            user != null ? AuthState.authenticated : AuthState.unauthenticated;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _authState = AuthState.unauthenticated;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ── Email / Password ───────────────────────────────────────────────────────

  /// Signs in with [email] and [password].
  ///
  /// Returns `true` on success. On failure, sets [errorMessage] and returns
  /// `false` — the UI should listen to [errorMessage] to show a snackbar.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _beginSubmit();

    final result = await _authRepository.signInWithEmail(
      email: email,
      password: password,
    );

    return _handleResult(result);
  }

  /// Registers a new account with [email], [password], and [displayName].
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _beginSubmit();

    final result = await _authRepository.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );

    return _handleResult(result);
  }

  // ── Google ─────────────────────────────────────────────────────────────────

  /// Starts the Google Sign-In flow.
  Future<bool> signInWithGoogle() async {
    _beginSubmit();

    final result = await _authRepository.signInWithGoogle();

    return _handleResult(result);
  }

  // ── Session ────────────────────────────────────────────────────────────────

  /// Signs out the current user.
  Future<void> signOut() async {
    _beginSubmit();

    final result = await _authRepository.signOut();

    switch (result) {
      case Success():
        // authStateChanges stream will emit null and update _authState.
        break;
      case Failure(:final message):
        _errorMessage = message;
    }

    _endSubmit();
  }

  // ── Password recovery ──────────────────────────────────────────────────────

  /// Sends a password-reset e-mail to [email].
  ///
  /// On success, sets [successMessage] so the UI can show a confirmation.
  Future<bool> sendPasswordResetEmail({required String email}) async {
    _beginSubmit();

    final result =
        await _authRepository.sendPasswordResetEmail(email: email);

    switch (result) {
      case Success():
        _successMessage =
            'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.';
        _endSubmit();
        return true;
      case Failure(:final message):
        _errorMessage = message;
        _endSubmit();
        return false;
    }
  }

  // ── Message helpers ────────────────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears the current success message.
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Sets [isSubmitting] = true and clears stale messages before a call.
  void _beginSubmit() {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Sets [isSubmitting] = false after a call completes.
  void _endSubmit() {
    _isSubmitting = false;
    notifyListeners();
  }

  /// Handles a [Result<UserModel>] — updates state and returns success flag.
  bool _handleResult(Result<UserModel> result) {
    switch (result) {
      case Success():
        // authStateChanges stream will fire and update _currentUser / _authState.
        _endSubmit();
        return true;
      case Failure(:final message):
        _errorMessage = message;
        _endSubmit();
        return false;
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
