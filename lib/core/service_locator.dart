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
import '../data/repositories/interfaces/i_chat_repository.dart';
import '../data/repositories/interfaces/i_mating_repository.dart';
import '../data/repositories/firebase/firebase_auth_repository.dart';
import '../data/repositories/firebase/firestore_pet_repository.dart';
import '../data/repositories/firebase/firestore_post_repository.dart';
import '../data/repositories/firebase/firestore_map_repository.dart';
import '../data/repositories/firebase/firestore_social_repository.dart';
import '../data/repositories/firebase/firestore_user_repository.dart';
import '../data/repositories/firebase/firestore_form_repository.dart';
import '../data/repositories/firebase/firestore_reminder_repository.dart';
import '../data/repositories/firebase/firestore_chat_repository.dart';
import '../data/repositories/firebase/firestore_mating_repository.dart';
import '../data/repositories/mock/mock_auth_repository.dart';
import '../data/repositories/mock/mock_post_repository.dart';
import '../data/repositories/mock/mock_user_repository.dart';
import '../data/repositories/mock/mock_pet_repository.dart';
import '../data/repositories/mock/mock_map_repository.dart';
import '../data/repositories/mock/mock_social_repository.dart';
import '../data/repositories/mock/mock_form_repository.dart';
import '../data/repositories/mock/mock_academy_repository.dart';
import '../data/repositories/mock/mock_reminder_repository.dart';
import '../data/repositories/mock/mock_chat_repository.dart';
import '../data/repositories/mock/mock_mating_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/ai_vet_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../services/pati_ai_service.dart';
import '../viewmodels/map_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../viewmodels/social_viewmodel.dart';
import '../viewmodels/form_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOD ANAHTARI
// ─────────────────────────────────────────────────────────────────────────────
// true  → Tüm mock repository'ler (offline, test@espati.com / password123)
// false → Firebase repository'ler (gerçek Firestore + Storage + Auth)
// ─────────────────────────────────────────────────────────────────────────────
const bool kUseMock = false; // ← BU TEK SATIRI DEĞİŞTİR

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
        create: (_) =>
            kUseMock ? MockPostRepository() : FirestorePostRepository(),
      ),
      Provider<IUserRepository>(
        create: (_) =>
            kUseMock ? MockUserRepository() : FirestoreUserRepository(),
      ),
      Provider<IPetRepository>(
        create: (_) =>
            kUseMock ? MockPetRepository() : FirestorePetRepository(),
      ),
      Provider<IMapRepository>(
        create: (_) =>
            kUseMock ? MockMapRepository() : FirestoreMapRepository(),
      ),
      Provider<ISocialRepository>(
        create: (_) =>
            kUseMock ? MockSocialRepository() : FirestoreSocialRepository(),
      ),
      Provider<IFormRepository>(
        create: (_) =>
            kUseMock ? MockFormRepository() : FirestoreFormRepository(),
        dispose: (_, repo) {
          if (repo is MockFormRepository) repo.dispose();
        },
      ),
      Provider<IAcademyRepository>(
        create: (_) => MockAcademyRepository(),
      ),
      Provider<IReminderRepository>(
        create: (_) =>
            kUseMock ? MockReminderRepository() : FirestoreReminderRepository(),
      ),
      Provider<IChatRepository>(
        create: (_) =>
            kUseMock ? MockChatRepository() : FirestoreChatRepository(),
      ),
      Provider<IMatingRepository>(
        create: (_) =>
            kUseMock ? MockMatingRepository() : FirestoreMatingRepository(),
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
        // PatiAiService.instance is the singleton — the HTTP client is
        // created exactly once regardless of hot-reload or rebuilds.
        create: (context) => AIVetViewModel(
          aiService: PatiAiService.instance,
          academyRepository: context.read<IAcademyRepository>(),
        ),
      ),
      ChangeNotifierProvider<MapViewModel>(
        create: (context) => MapViewModel(
          context.read<IMapRepository>(),
        ),
      ),
      ChangeNotifierProvider<NotificationViewModel>(
        create: (context) => NotificationViewModel(
          socialRepository: context.read<ISocialRepository>(),
        ),
      ),
      ChangeNotifierProvider<FormViewModel>(
        create: (context) => FormViewModel(context.read<IFormRepository>()),
      ),
      ChangeNotifierProvider<ProfileViewModel>(
        create: (context) => ProfileViewModel(
          userRepository: context.read<IUserRepository>(),
          reminderRepository: context.read<IReminderRepository>(),
          petRepository: context.read<IPetRepository>(),
          postRepository: context.read<IPostRepository>(),
        ),
      ),
      ChangeNotifierProvider<ChatViewModel>(
        create: (context) => ChatViewModel(
          userRepository: context.read<IUserRepository>(),
          chatRepository: context.read<IChatRepository>(),
        ),
      ),
      ChangeNotifierProxyProvider<NotificationViewModel, SocialViewModel>(
        create: (context) => SocialViewModel(
          context.read<ISocialRepository>(),
          context.read<IPostRepository>(),
          context.read<NotificationViewModel>(),
        ),
        update: (context, notifVM, previous) =>
            previous ??
            SocialViewModel(
              context.read<ISocialRepository>(),
              context.read<IPostRepository>(),
              notifVM,
            ),
      ),
    ],
    child: child,
  );
}
