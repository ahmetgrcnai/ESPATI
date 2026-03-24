import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../data/sample_data.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../widgets/pet_card.dart';
import 'reminder_manager_screen.dart';

/// Profile screen — user header, stats, my pets scrollable list,
/// post grid, and settings bottom sheet with dark mode toggle.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const profile = SampleData.userProfile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          profile['username'] as String,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isDark ? theme.colorScheme.surface : AppColors.peachLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.settings_rounded, color: textColor, size: 20),
            ),
            onPressed: () => _showSettingsSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar with gradient ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.peach, AppColors.primary],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      child: CircleAvatar(
                        radius: 39,
                        backgroundColor: isDark
                            ? theme.colorScheme.surface
                            : AppColors.peachLight,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profile['avatar'] as String,
                            width: 78,
                            height: 78,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Icon(Icons.person,
                                size: 40, color: AppColors.peach),
                            errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                size: 40,
                                color: AppColors.peach),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Stats
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatColumn(
                          value: '${profile['posts']}',
                          label: 'Posts',
                          textColor: textColor,
                        ),
                        _StatColumn(
                          value: '${profile['followers']}',
                          label: 'Followers',
                          textColor: textColor,
                        ),
                        _StatColumn(
                          value: '${profile['following']}',
                          label: 'Following',
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Name & Bio ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile['bio'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Eskişehir, Turkey',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Action Buttons ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Profile',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Share Profile',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                          color: isDark ? Colors.white24 : AppColors.divider,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── My Pets Section ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.pets_rounded, size: 20, color: AppColors.peach),
                  const SizedBox(width: 8),
                  Text(
                    'My Pets',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.add_circle_outline_rounded,
                        size: 18, color: AppColors.primary),
                    label: Text('Add Pet',
                        style:
                            TextStyle(color: AppColors.primary, fontSize: 13)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: SampleData.userPets.length,
                itemBuilder: (context, index) {
                  final pet = SampleData.userPets[index];
                  return PetCard(
                    name: pet['name']!,
                    breed: pet['breed']!,
                    imageUrl: pet['image']!,
                    age: pet['age']!,
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ── Pati Takvimi (Pet Schedule) ──
            Consumer<ProfileViewModel>(
              builder: (context, vm, _) =>
                  _PatiTakvimiSection(vm: vm, theme: theme),
            ),

            const SizedBox(height: 8),

            // ── Posts Grid Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.grid_on_rounded,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'My Posts',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Posts Grid ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: SampleData.userPostImages.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: SampleData.userPostImages[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark
                            ? theme.colorScheme.surface
                            : AppColors.peachLight,
                        child: Icon(Icons.pets,
                            size: 24,
                            color: AppColors.peach.withValues(alpha: 0.5)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark
                            ? theme.colorScheme.surface
                            : AppColors.peachLight,
                        child: Icon(Icons.pets,
                            size: 24,
                            color: AppColors.peach.withValues(alpha: 0.5)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Shows the settings bottom sheet with dark mode toggle.
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final textColor = theme.colorScheme.onSurface;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),

              // Dark Mode toggle
              Consumer<ThemeViewModel>(
                builder: (context, themeVM, _) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Icon(
                            themeVM.isDarkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      value: themeVM.isDarkMode,
                      onChanged: (_) => themeVM.toggleTheme(),
                      activeTrackColor: AppColors.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Notifications setting
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Push Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: textColor),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // About
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'About ESPATI',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    Text('v1.0.0',
                        style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PATI TAKVİMİ SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _PatiTakvimiSection extends StatelessWidget {
  final ProfileViewModel vm;
  final ThemeData theme;

  const _PatiTakvimiSection({required this.vm, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final upcoming = vm.upcomingReminders(maxCount: 3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.softTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_month_rounded,
                    size: 18, color: AppColors.softTeal),
              ),
              const SizedBox(width: 10),
              Text(
                'Pati Takvimi',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReminderManagerScreen(),
                  ),
                ),
                icon: Icon(Icons.open_in_new_rounded,
                    size: 15, color: AppColors.softTeal),
                label: Text(
                  'Tümünü Gör / Düzenle',
                  style: GoogleFonts.poppins(
                    color: AppColors.softTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Loading ───────────────────────────────────────────────────────
          if (vm.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )

          // ── Empty state ───────────────────────────────────────────────────
          else if (upcoming.isEmpty)
            _PreviewEmptyState(
              onAdd: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReminderManagerScreen(),
                ),
              ),
            )

          // ── Preview list (max 3) ──────────────────────────────────────────
          else
            ...upcoming.map(
              (reminder) => ReminderCard(
                reminder: reminder,
                onComplete: () => vm.completeReminder(reminder.id),
                onDelete: () => vm.deleteReminder(reminder.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _PreviewEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.softTeal.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.softTeal.withValues(alpha: 0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.add_alarm_rounded,
                size: 36, color: AppColors.softTeal.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              'İlk hatırlatıcını ekle!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.softTeal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aşı, mama, ilaç takvimini takip et',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
