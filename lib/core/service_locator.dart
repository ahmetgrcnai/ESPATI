import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/interfaces/i_auth_repository.dart';
import '../data/repositories/interfaces/i_post_repository.dart';
import '../data/repositories/interfaces/i_user_repository.dart';
import '../data/repositories/interfaces/i_pet_repository.dart';
import '../data/repositories/interfaces/i_map_repository.dart';
import '../data/repositories/interfaces/i_social_repository.dart';
import '../data/repositories/interfaces/i_form_repository.dart';
import '../data/repositories/interfaces/i_academy_repository.dart';
import '../data/repositories/interfaces/i_reminder_repository.dart';
import '../data/repositories/firebase/firebase_auth_repository.dart';
import '../data/repositories/mock/mock_auth_repository.dart';
import '../data/repositories/mock/mock_post_repository.dart';
import '../data/repositories/mock/mock_user_repository.dart';
import '../data/repositories/mock/mock_pet_repository.dart';
import '../data/repositories/mock/mock_map_repository.dart';
import '../data/repositories/mock/mock_social_repository.dart';
import '../data/repositories/mock/mock_form_repository.dart';
import '../data/repositories/mock/mock_academy_repository.dart';
import '../data/repositories/mock/mock_reminder_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/ai_vet_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'gemini_service.dart';
import '../viewmodels/map_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../viewmodels/social_viewmodel.dart';
import '../viewmodels/form_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH MODE SWITCH
// ─────────────────────────────────────────────────────────────────────────────
// true  → MockAuthRepository  (offline, test@espati.com / password123)
// false → FirebaseAuthRepository (real Firebase, requires google-services)
// ─────────────────────────────────────────────────────────────────────────────
const bool kUseMock = false; // ← CHANGE THIS ONE LINE TO SWITCH

/// Wraps the given [child] widget with all necessary dependency providers.
///
/// Repositories are registered as interfaces (abstract types) so the UI
/// never depends on concrete implementations. To switch from mock to real
/// data, simply swap the `create:` lambdas below.
///
/// ViewModels are registered as [ChangeNotifierProvider]s so the UI
/// can reactively rebuild when state changes.
Widget createProviders({required Widget child}) {
  return MultiProvider(
    providers: [
      // ── Repositories (swap mock → real here) ──

      // Auth repository: controlled by [kUseMock] at the top of this file.
      // Flip that flag — nothing else in the codebase needs to change.
      Provider<IAuthRepository>(
        create: (_) =>
            kUseMock ? MockAuthRepository() : FirebaseAuthRepository(),
        dispose: (_, repo) {
          if (repo is MockAuthRepository) repo.dispose();
        },
      ),
      Provider<IPostRepository>(
        create: (_) => MockPostRepository(),
      ),
      Provider<IUserRepository>(
        create: (_) => MockUserRepository(),
      ),
      Provider<IPetRepository>(
        create: (_) => MockPetRepository(),
      ),
      Provider<IMapRepository>(
        create: (_) => MockMapRepository(),
      ),
      Provider<ISocialRepository>(
        create: (_) => MockSocialRepository(),
      ),
      Provider<IFormRepository>(
        create: (_) => MockFormRepository(),
      ),
      Provider<IAcademyRepository>(
        create: (_) => MockAcademyRepository(),
      ),
      Provider<IReminderRepository>(
        create: (_) => MockReminderRepository(),
      ),

      // ── ViewModels ──

      // AuthViewModel is registered first — it subscribes to authStateChanges
      // immediately on creation, so the auth state is ready before any other
      // ViewModel or screen reads it.
      ChangeNotifierProvider<AuthViewModel>(
        create: (context) => AuthViewModel(
          authRepository: context.read<IAuthRepository>(),
        ),
      ),
      ChangeNotifierProvider<HomeViewModel>(
        create: (context) => HomeViewModel(
          context.read<IPostRepository>(),
        ),
      ),
      ChangeNotifierProvider<AIVetViewModel>(
        // GeminiService.instance is the singleton — GenerativeModel is
        // created exactly once regardless of hot-reload or rebuilds.
        create: (context) => AIVetViewModel(
          geminiService: GeminiService.instance,
          academyRepository: context.read<IAcademyRepository>(),
        ),
      ),
      ChangeNotifierProvider<MapViewModel>(
        create: (context) => MapViewModel(
          context.read<IMapRepository>(),
        ),
      ),
      ChangeNotifierProvider<NotificationViewModel>(
        create: (_) => NotificationViewModel(),
      ),
      ChangeNotifierProvider<FormViewModel>(
        create: (context) => FormViewModel(context.read<IFormRepository>()),
      ),
      ChangeNotifierProvider<ProfileViewModel>(
        create: (context) => ProfileViewModel(
          reminderRepository: context.read<IReminderRepository>(),
        ),
      ),
      ChangeNotifierProxyProvider<NotificationViewModel, SocialViewModel>(
        create: (context) => SocialViewModel(
          context.read<ISocialRepository>(),
          context.read<NotificationViewModel>(),
        ),
        update: (context, notifVM, previous) =>
            previous ??
            SocialViewModel(
              context.read<ISocialRepository>(),
              notifVM,
            ),
      ),
    ],
    child: child,
  );
}
