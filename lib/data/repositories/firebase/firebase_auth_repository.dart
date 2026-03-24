import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/result.dart';
import '../../models/user_model.dart';
import '../interfaces/i_auth_repository.dart';

/// Firebase implementation of [IAuthRepository].
///
/// All [FirebaseAuthException] codes are translated into Turkish user-facing
/// messages in [_mapFirebaseError] — nothing from [firebase_auth] leaks
/// beyond this class.
class FirebaseAuthRepository implements IAuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  // ── State ──────────────────────────────────────────────────────────────────

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map(
      (user) => user != null ? _firebaseUserToModel(user) : null,
    );
  }

  @override
  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user != null ? _firebaseUserToModel(user) : null;
  }

  // ── Email / Password ───────────────────────────────────────────────────────

  @override
  Future<Result<UserModel>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return Success(_firebaseUserToModel(credential.user!));
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Giriş yapılamadı. Lütfen tekrar deneyin.', exception: e);
    }
  }

  @override
  Future<Result<UserModel>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Persist the display name in Firebase Auth profile.
      await credential.user!.updateDisplayName(displayName.trim());

      // Reload so currentUser reflects the updated displayName immediately.
      await credential.user!.reload();
      final refreshedUser = _auth.currentUser!;

      return Success(_firebaseUserToModel(refreshedUser));
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure('Kayıt oluşturulamadı. Lütfen tekrar deneyin.', exception: e);
    }
  }

  // ── Google ─────────────────────────────────────────────────────────────────

  @override
  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      // Opens the Google account picker. Returns null if user cancels.
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Failure('Google ile giriş iptal edildi.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return Success(_firebaseUserToModel(userCredential.user!));
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure(
        'Google ile giriş yapılamadı. Lütfen tekrar deneyin.',
        exception: e,
      );
    }
  }

  // ── Session ────────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> signOut() async {
    try {
      // Sign out from both providers so Google's picker shows next time.
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      return const Success(null);
    } on Exception catch (e) {
      return Failure('Çıkış yapılamadı. Lütfen tekrar deneyin.', exception: e);
    }
  }

  // ── Password recovery ──────────────────────────────────────────────────────

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure(
        'Şifre sıfırlama e-postası gönderilemedi.',
        exception: e,
      );
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Maps a [firebase_auth.User] to ESPATI's domain [UserModel].
  ///
  /// Uses Firebase Auth profile fields (uid, displayName, photoURL).
  /// Fields with no Firebase equivalent default to empty string / empty list.
  UserModel _firebaseUserToModel(User user) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      bio: '',
      profilePicture: user.photoURL ?? '',
      locationDistrict: '',
      ownedPetIds: const [],
    );
  }

  /// Translates [FirebaseAuthException.code] into a Turkish user-facing message.
  ///
  /// Covers all codes that [firebase_auth] can emit for email/password and
  /// OAuth flows. Falls back to a generic message for unknown codes.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      // ── Sign-in errors ───────────────────────────────────────────────────
      case 'user-not-found':
      case 'invalid-credential':
        return 'E-posta adresi veya şifre hatalı.';
      case 'wrong-password':
        return 'Şifre yanlış. Lütfen tekrar deneyin.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmıştır.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen bir süre bekleyin.';

      // ── Sign-up errors ───────────────────────────────────────────────────
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi formatı.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'operation-not-allowed':
        return 'Bu giriş yöntemi şu an etkin değil.';

      // ── Network ──────────────────────────────────────────────────────────
      case 'network-request-failed':
        return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';

      // ── Session ──────────────────────────────────────────────────────────
      case 'requires-recent-login':
        return 'Bu işlem için yeniden giriş yapmanız gerekiyor.';

      default:
        return 'Beklenmedik bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
