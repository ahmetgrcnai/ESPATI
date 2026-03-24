import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Espati bottom navigation bar — 5 fixed tabs.
///
/// Active item: Soft Teal [AppColors.softTeal]
/// Inactive item: neutral grey
/// Light mode background: white
/// Dark mode background: pure AMOLED black (#000000)
class EspatiBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const EspatiBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? Colors.black : Colors.white,
      selectedItemColor: AppColors.softTeal,
      unselectedItemColor: isDark
          ? const Color(0xFF666666)
          : const Color(0xFFAAAAAA),
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 11,
      ),
      elevation: isDark ? 0 : 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.pets),
          label: 'Sosyal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Harita',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum_rounded),
          label: 'Forum',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy),
          label: 'Pati-AI',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
