import 'dart:async';

import '../../../core/result.dart';
import '../../models/user_model.dart';
import '../interfaces/i_auth_repository.dart';

/// Offline mock of [IAuthRepository] for UI development and QA testing.
///
/// No network calls, no Firebase dependency. A single hardcoded test account
/// lets you exercise the full auth flow — loading states, error snackbars,
/// and [AuthWrapper] navigation — without touching real credentials.
///
/// ┌─────────────────────────────────────────────────────────┐
/// │  Test Hesabı                                            │
/// │  E-posta : test@espati.com                              │
/// │  Şifre   : password123                                  │
/// └─────────────────────────────────────────────────────────┘
///
/// To switch back to real Firebase, flip [kUseMock] to `false` in
/// service_locator.dart — no other file needs to change.
class MockAuthRepository implements IAuthRepository {
  MockAuthRepository() {
    // Immediately signal "no active session" so AuthWrapper shows LoginScreen.
    _controller.add(null);
  }

  // ── Configuration ──────────────────────────────────────────────────────────

  static const _testEmail    = 'test@espati.com';
  static const _testPassword = 'password123';

  /// Realistic round-trip delay — exercises the [CircularProgressIndicator]
  /// on buttons and the [isSubmitting] state in [AuthViewModel].
  static const _delay = Duration(seconds: 2);

  // ── Dummy users ────────────────────────────────────────────────────────────

  static const _testUser = UserModel(
    id: 'mock-user-001',
    email: _testEmail,
    name: 'Test Kullanıcı',
    bio: 'ESPATI geliştirme test hesabı.',
    profilePicture: '',
    locationDistrict: 'Eskişehir',
    ownedPetIds: [],
  );

  static const _googleUser = UserModel(
    id: 'mock-google-001',
    email: 'google@espati.com',
    name: 'Google Test Kullanıcı',
    bio: '',
    profilePicture: '',
    locationDistrict: 'Eskişehir',
    ownedPetIds: [],
  );

  // ── Internal state ─────────────────────────────────────────────────────────

  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  // ── IAuthRepository — State ────────────────────────────────────────────────

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  UserModel? get currentUser => _currentUser;

  // ── IAuthRepository — Email / Password ────────────────────────────────────

  @override
  Future<Result<UserModel>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(_delay);

    final emailMatch    = email.trim().toLowerCase() == _testEmail;
    final passwordMatch = password == _testPassword;

    if (!emailMatch || !passwordMatch) {
      return const Failure(
        "Hatalı test girişi. Lütfen 'test@espati.com' ve 'password123' "
        'bilgilerini kullanın.',
      );
    }

    _emit(_testUser);
    return const Success(_testUser);
  }

  @override
  Future<Result<UserModel>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future.delayed(_delay);

    // Mock kayıt: herhangi bir e-posta / şifre kabul edilir, anında oturum açılır.
    final newUser = UserModel(
      id: 'mock-signup-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim().toLowerCase(),
      name: displayName.trim(),
      bio: '',
      profilePicture: '',
      locationDistrict: 'Eskişehir',
      ownedPetIds: const [],
    );

    _emit(newUser);
    return Success(newUser);
  }

  // ── IAuthRepository — Google ───────────────────────────────────────────────

  @override
  Future<Result<UserModel>> signInWithGoogle() async {
    await Future.delayed(_delay);
    // Simulates a successful Google OAuth flow without opening any system UI.
    _emit(_googleUser);
    return const Success(_googleUser);
  }

  // ── IAuthRepository — Session ──────────────────────────────────────────────

  @override
  Future<Result<void>> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _emit(null);
    return const Success(null);
  }

  // ── IAuthRepository — Password recovery ───────────────────────────────────

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(_delay);
    // Always succeeds — mirrors Firebase behaviour of not revealing whether
    // an address exists, preventing user-enumeration attacks.
    return const Success(null);
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Call when the repository is no longer needed to release the [StreamController].
  void dispose() {
    _controller.close();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  void _emit(UserModel? user) {
    _currentUser = user;
    if (!_controller.isClosed) _controller.add(user);
  }
}
