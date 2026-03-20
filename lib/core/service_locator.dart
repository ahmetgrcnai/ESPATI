import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/interfaces/i_post_repository.dart';
import '../data/repositories/interfaces/i_user_repository.dart';
import '../data/repositories/interfaces/i_pet_repository.dart';
import '../data/repositories/interfaces/i_map_repository.dart';
import '../data/repositories/interfaces/i_social_repository.dart';
import '../data/repositories/mock/mock_post_repository.dart';
import '../data/repositories/mock/mock_user_repository.dart';
import '../data/repositories/mock/mock_pet_repository.dart';
import '../data/repositories/mock/mock_map_repository.dart';
import '../data/repositories/mock/mock_social_repository.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/ai_vet_viewmodel.dart';
import '../viewmodels/map_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../viewmodels/social_viewmodel.dart';

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

      // ── ViewModels ──
      ChangeNotifierProvider<HomeViewModel>(
        create: (context) => HomeViewModel(
          context.read<IPostRepository>(),
        ),
      ),
      ChangeNotifierProvider<AIVetViewModel>(
        create: (_) => AIVetViewModel(),
      ),
      ChangeNotifierProvider<MapViewModel>(
        create: (context) => MapViewModel(
          context.read<IMapRepository>(),
        ),
      ),
      ChangeNotifierProvider<NotificationViewModel>(
        create: (_) => NotificationViewModel(),
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
