import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

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
      // Falls back to the credential user if currentUser is null after reload
      // (e.g. account remotely disabled between creation and this call).
      await credential.user!.reload();
      final refreshedUser = _auth.currentUser ?? credential.user!;
      final userModel = _firebaseUserToModel(refreshedUser);

      // CRITICAL: without a users/{uid} Firestore document,
      // FirestoreUserRepository.watchCurrentUser() emits null for this
      // account forever (it does not lazily create the doc the way
      // getCurrentUser() does), so ProfileViewModel treats a freshly
      // registered user as signed-out and the profile screen never
      // populates. Writing it here — before returning Success — keeps
      // Auth state and Firestore state consistent from the first frame.
      await _firestore
          .collection('users')
          .doc(userModel.id)
          .set(userModel.toJson())
          // A flaky connection must not hang the "Kayıt Ol" button forever —
          // fail loudly after 15s instead so the UI can show an error.
          .timeout(const Duration(seconds: 15));

      return Success(userModel);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on TimeoutException {
      return const Failure(
        'Kayıt zaman aşımına uğradı. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on Exception catch (e) {
      return Failure('Kayıt oluşturulamadı. Lütfen tekrar deneyin.', exception: e);
    } catch (e) {
      // Catches non-Exception throwables (e.g. a null-check/TypeError) so
      // signUpWithEmail never throws past this point and leaves the caller's
      // isSubmitting flag stuck at true. `e` isn't statically an Exception
      // here, so it's only attached to Failure when it happens to be one.
      return Failure(
        'Kayıt oluşturulamadı. Lütfen tekrar deneyin.',
        exception: e is Exception ? e : null,
      );
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
      final userModel = _firebaseUserToModel(userCredential.user!);

      // Same requirement as signUpWithEmail: a first-time Google sign-in
      // needs a users/{uid} doc or ProfileViewModel's watchCurrentUser()
      // stream will treat this account as signed-out. Only seed it when
      // missing so a returning user's saved bio/pets aren't overwritten.
      await _ensureUserDocument(userModel);

      return Success(userModel);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e), exception: e);
    } on Exception catch (e) {
      return Failure(
        'Google ile giriş yapılamadı. Lütfen tekrar deneyin.',
        exception: e,
      );
    } catch (e) {
      return Failure(
        'Google ile giriş yapılamadı. Lütfen tekrar deneyin.',
        exception: e is Exception ? e : null,
      );
    }
  }

  // ── Session ────────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> signOut() async {
    try {
      // Firebase sign-out is authoritative — must succeed for the auth
      // stream to emit null and trigger navigation to LoginScreen.
      await _auth.signOut();

      // Google sign-out/disconnect is best-effort: failure here is silenced
      // because the user IS already signed out from Firebase — surfacing an
      // error at this point would be misleading.
      //
      // signOut() alone isn't enough — the Google Play Services layer keeps
      // a cached "last selected account" independent of our app's session,
      // so a plain signOut() + signIn() can silently re-authenticate the
      // same account instead of showing the picker. disconnect() revokes
      // that cached grant, which is what actually forces the account picker
      // to appear on the next signInWithGoogle() call.
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      } catch (_) {}

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

  /// Seeds `users/{uid}` from [user] only if the document doesn't exist yet.
  Future<void> _ensureUserDocument(UserModel user) async {
    final ref = _firestore.collection('users').doc(user.id);
    final doc = await ref.get().timeout(const Duration(seconds: 15));
    if (!doc.exists) {
      await ref.set(user.toJson()).timeout(const Duration(seconds: 15));
    }
  }

  /// Maps a [firebase_auth.User] to ESPATI's domain [UserModel].
  ///
  /// Uses Firebase Auth profile fields (uid, displayName, photoURL).
  /// Fields with no Firebase equivalent default to empty string / empty list.
  UserModel _firebaseUserToModel(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
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
      case 'account-exists-with-different-credential':
        return 'Bu e-posta adresi farklı bir giriş yöntemiyle kayıtlı. '
            'Lütfen e-posta ile giriş yapmayı deneyin.';
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
