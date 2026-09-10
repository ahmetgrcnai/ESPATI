
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/notification_service.dart';
import 'core/service_locator.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'screens/splash/splash_screen.dart';

/// Espati — A social media app for pet owners.
/// Main entry point.
Future<void> main() async {
  // Step 65 — flutter_native_splash has been removed entirely (package
  // uninstalled, native Android/iOS launch-screen configs reverted to
  // Flutter's plain unbranded defaults). There's no native splash left to
  // preserve/remove a handoff for; ths OS's own brief, blank default
  // launch screen is unavoidable (every Android/iOS app has *some* native
  // resource covering the gap before a first frame renders — that's
  // platform-level, not something any Flutter package can fully erase),
  // but zero branding lives there now. All of it — logo, slogan, colors,
  // animation — is the custom SplashScreen widget below.
  WidgetsFlutterBinding.ensureInitialized();

  // Load secrets from .env (gitignored) before any service that needs them
  // (ClaudeService) is constructed.
  await dotenv.load(fileName: '.env');

  // --- YENİ: Firebase Başlatma ---
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase successfully initialised");
  } catch (e) {
    debugPrint("❌ Firebase initialisation error: $e");
  }
  // -------------------------------

  // Initialise local notification service (Mevcut kodun)
  await NotificationService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const EspatiApp());
}

class EspatiApp extends StatelessWidget {
  const EspatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeViewModel(),
      child: createProviders( // service_locator.dart içindeki sağlayıcılar
        child: Consumer<ThemeViewModel>(
          builder: (context, themeVM, child) {
            return MaterialApp(
              title: 'Espati',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeVM.themeMode,
              // Step 65 — back to a Dart-level SplashScreen as the sole
              // branded boot moment, now that native splash customization
              // (flutter_native_splash) has been fully removed. SplashScreen
              // itself pushReplacement's to AuthWrapper (the real auth-check
              // gate — Login vs MainScreen) after its branded delay.
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
