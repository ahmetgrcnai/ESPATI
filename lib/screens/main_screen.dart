import 'package:flutter/material.dart';

// Root-level rich screens
import 'social_screen.dart';
import 'form_hub_screen.dart';

// Subdir rich screens (full implementations)
import 'map/map_screen.dart';
import 'ai_vet/ai_vet_screen.dart';
import 'profile/profile_screen.dart';

import '../widgets/bottom_nav_bar.dart';

/// Root scaffold — 5-tab bottom navigation, IndexedStack preserves tab state.
///
/// Tab order:
///   0 → Sosyal      → SocialScreen    (Petzbe-inspired feed)
///   1 → Harita      → MapScreen       (Google Maps, Eskişehir pet-friendly)
///   2 → Forum       → FormHubScreen   (İlanlar + Mesajlar/Gruplar hub)
///   3 → Pati-AI     → AiVetScreen     (Gemini AI + Vet Q&A + Lost pets)
///   4 → Profil      → ProfileScreen   (User stats, pets grid, settings)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    SocialScreen(),
    MapScreen(),
    FormHubScreen(),
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
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
