import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/common/neo_brutalist_list_tile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS SCREEN — Neo-Brutalist rebuild (Design System Step 54).
//
// Replaces ProfileScreen's old rounded, Material-styled `_showSettingsSheet`
// bottom sheet with a real, dedicated, pushed screen — same App Store-
// standard categorized layout (HESAP / BİLDİRİMLER / GİZLİLİK / DESTEK),
// fully Neo-Brutalist.
//
// Only two rows are backed by real app state today:
//   • "Karanlık Mod" — [ThemeViewModel.toggleTheme], carried over from the
//     old sheet (it actually worked; dropping it silently on this rebuild
//     would be a regression, not a cleanup — kept under its own GÖRÜNÜM
//     section since it's neither an account nor a notification setting).
//   • "Çıkış Yap" — [AuthViewModel.signOut]. [AuthWrapper] watches auth
//     state at the app root and swaps to LoginScreen once it emits null, so
//     this screen doesn't need to navigate anywhere itself after sign-out.
//
// Every other row (password change, notifications backend, blocked users,
// delete account, ToS/Privacy copy, support) has no real field/endpoint
// behind it yet — [UserModel] has no notification-prefs or blocked-user-ids
// field, [IAuthRepository] has no change-password/delete-account method.
// Same honest-stub convention as Paties' like/comment/share and the Edit
// Profile screen's username/link fields: these are real, tappable rows (App
// Store review wants to see the categories exist), but they surface a
// "yakında" toast instead of silently pretending to work. The notifications
// switch is local UI-only state for the same reason — nothing to persist it
// to yet.
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local-only — see file header. Defaults to on, matching what a user
  // would expect before ever touching this screen.
  bool _pushNotificationsEnabled = true;

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — yakında geliyor!',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.white, width: 1.5),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final authVM = context.read<AuthViewModel>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.black, width: 3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: Offset(5, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Çıkış yapılsın mı?',
                  style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black)),
              const SizedBox(height: 8),
              Text('Hesabından çıkış yapmak üzeresin.',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.7))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: NeoBrutalistButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.zero,
                          border: Border.fromBorderSide(
                            BorderSide(
                                color: Colors.black, width: 2),
                          ),
                        ),
                        child: Text('İptal',
                            style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                color: Colors.black)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeoBrutalistButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(
                          color: EspatiColors.red,
                          borderRadius: BorderRadius.zero,
                          border: Border.fromBorderSide(
                            BorderSide(
                                color: Colors.black, width: 2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Text('Çıkış Yap',
                            style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) authVM.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Ayarlar',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _SectionHeader('HESAP'),
          const SizedBox(height: 10),
          NeoBrutalistListTile(
            icon: Icons.lock_outline_rounded,
            title: 'Şifreyi Değiştir',
            iconBoxColor: EspatiColors.mintGreen,
            onTap: () => _comingSoon('Şifre değiştirme'),
          ),
          const SizedBox(height: 10),
          NeoBrutalistListTile(
            icon: Icons.delete_forever_rounded,
            title: 'Hesabı Sil',
            iconBoxColor: EspatiColors.red,
            onTap: () => _comingSoon('Hesap silme'),
          ),
          const SizedBox(height: 24),

          const _SectionHeader('GÖRÜNÜM'),
          const SizedBox(height: 10),
          Consumer<ThemeViewModel>(
            builder: (context, themeVM, _) => NeoBrutalistListTile(
              icon: themeVM.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              title: 'Karanlık Mod',
              iconBoxColor: EspatiColors.peach,
              trailing: Switch(
                value: themeVM.isDarkMode,
                onChanged: (_) => themeVM.toggleTheme(),
                activeTrackColor: EspatiColors.mintGreen,
                thumbColor: const WidgetStatePropertyAll(Colors.white),
              ),
              onTap: themeVM.toggleTheme,
            ),
          ),
          const SizedBox(height: 24),

          const _SectionHeader('BİLDİRİMLER'),
          const SizedBox(height: 10),
          NeoBrutalistListTile(
            icon: Icons.notifications_rounded,
            title: 'Bildirimler',
            subtitle: 'Anlık bildirimler',
            iconBoxColor: EspatiColors.mintGreen,
            trailing: Switch(
              value: _pushNotificationsEnabled,
              onChanged: (v) =>
                  setState(() => _pushNotificationsEnabled = v),
              activeTrackColor: EspatiColors.mintGreen,
              thumbColor: const WidgetStatePropertyAll(Colors.white),
            ),
            onTap: () => setState(() =>
                _pushNotificationsEnabled = !_pushNotificationsEnabled),
          ),
          const SizedBox(height: 24),

          const _SectionHeader('GİZLİLİK'),
          const SizedBox(height: 10),
          NeoBrutalistListTile(
            icon: Icons.block_rounded,
            title: 'Engellenen Kullanıcılar',
            iconBoxColor: EspatiColors.peach,
            onTap: () => _comingSoon('Engellenen kullanıcılar'),
          ),
          const SizedBox(height: 10),
          NeoBrutalistListTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Gizlilik Politikası',
            iconBoxColor: EspatiColors.peach,
            onTap: () => _comingSoon('Gizlilik politikası'),
          ),
          const SizedBox(height: 24),

          const _SectionHeader('DESTEK'),
          const SizedBox(height: 10),
          NeoBrutalistListTile(
            icon: Icons.description_rounded,
            title: 'Kullanım Şartları',
            iconBoxColor: EspatiColors.mintGreen,
            onTap: () => _comingSoon('Kullanım şartları'),
          ),
          const SizedBox(height: 10),
          NeoBrutalistListTile(
            icon: Icons.help_outline_rounded,
            title: 'Yardım ve Destek',
            iconBoxColor: EspatiColors.mintGreen,
            onTap: () => _comingSoon('Yardım merkezi'),
          ),
          const SizedBox(height: 32),

          // ── Logout ────────────────────────────────────────────────────
          NeoBrutalistButton(
            onPressed: _confirmLogout,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: EspatiColors.red,
                borderRadius: BorderRadius.zero,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Çıkış Yap',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: Text(
              'ESPATI v1.0.0-beta',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER — bold, uppercase, darkBrown
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.fredoka(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 1.1,
        color: Colors.black,
      ),
    );
  }
}
