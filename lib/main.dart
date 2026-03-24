import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/notification_service.dart';
import 'core/service_locator.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'screens/auth/auth_wrapper.dart';

/// Espati — A social media app for pet owners.
/// Main entry point.
Future<void> main() async {
  // Preserve the native splash until Flutter is ready to draw its first frame.
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

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

  // Load environment variables from .env file (Mevcut kodun)
  await dotenv.load(fileName: '.env');

  // Initialise local notification service (Mevcut kodun)
  await NotificationService.instance.init();

  // Remove the native splash — Flutter takes over rendering from here.
  FlutterNativeSplash.remove();

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
              home: const AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}
