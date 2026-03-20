import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/app_colors.dart';
import 'core/service_locator.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'screens/home/home_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/ai_vet/ai_vet_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'widgets/bottom_nav_bar.dart';

/// Espati — A social media app for pet owners.
/// Main entry point.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.primary,
      systemNavigationBarIconBrightness: Brightness.light,
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
      child: createProviders(
        child: Consumer<ThemeViewModel>(
          builder: (context, themeVM, child) {
            return MaterialApp(
              title: 'Espati',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeVM.themeMode,
              home: const MainScreen(),
            );
          },
        ),
      ),
    );
  }
}

/// Root screen with bottom navigation and an IndexedStack to preserve tab state.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // All five tab screens
  final List<Widget> _screens = const [
    HomeScreen(),
    MapScreen(),
    MessagesScreen(),
    AiVetScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: EspatiBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
