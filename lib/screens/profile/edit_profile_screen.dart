import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/common/neo_brutalist_text_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EDIT PROFILE SCREEN — Neo-Brutalist rebuild (Design System Step 53),
// wired to real backend persistence (Step 55).
//
// Instagram-standard 4-field layout (Ad / Kullanıcı Adı / Biyografi /
// Bağlantı). All four now round-trip through [UserModel] and
// [ProfileViewModel.updateUserProfile] to Firestore — [username]/[link] were
// added to [UserModel] in Step 55 specifically to close the gap Step 53 left
// (those two used to be local-only "yakında" stub fields; see git history
// for that version if needed).
//
// [_save] only pops the screen after [ProfileViewModel.updateUserProfile]
// resolves `true`; on `false` it stays open and surfaces [profileError] via
// a toast so the user can retry without re-typing anything. Known gap:
// `username` isn't checked for uniqueness yet — see the field's doc comment
// on [UserModel.username].
// ─────────────────────────────────────────────────────────────────────────────

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _usernameController;
  late final TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    // Pre-fill every field from the current ProfileViewModel.user — a
    // one-time read (not `watch`) is correct here: this State's own
    // TextEditingControllers become the source of truth for the form the
    // moment the screen opens, independent of any later `user` changes.
    final user = context.read<ProfileViewModel>().user;
    _nameController = TextEditingController(text: user.name);
    _bioController = TextEditingController(text: user.bio);
    _usernameController = TextEditingController(text: user.username);
    _linkController = TextEditingController(text: user.link);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _usernameController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<ProfileViewModel>();
    final success = await vm.updateUserProfile(
      name: _nameController.text,
      username: _usernameController.text,
      bio: _bioController.text,
      link: _linkController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      _showToast(vm.profileError ?? 'Profil güncellenemedi.');
      vm.clearProfileError();
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
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
          'Profili Düzenle',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Consumer<ProfileViewModel>(
              builder: (context, vm, _) => _SaveButton(
                isSaving: vm.isSavingProfile,
                onPressed: vm.isSavingProfile ? null : _save,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, vm, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: _AvatarPicker(
                      photoUrl: vm.user.profilePicture,
                      imageVersion: vm.imageVersion,
                      isUploading: vm.isUploading,
                      onTap: vm.isUploading
                          ? null
                          : () => vm.pickAndUploadProfileImage(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  NeoBrutalistTextField(
                    label: 'Ad',
                    controller: _nameController,
                    hintText: 'Adın Soyadın',
                    textCapitalization: TextCapitalization.words,
                    focusShadowColor: EspatiColors.mintGreen,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ad zorunludur'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  NeoBrutalistTextField(
                    label: 'Kullanıcı Adı',
                    controller: _usernameController,
                    hintText: '@kullaniciadi',
                    focusShadowColor: EspatiColors.peach,
                  ),
                  const SizedBox(height: 20),

                  NeoBrutalistTextField(
                    label: 'Biyografi',
                    controller: _bioController,
                    hintText: 'Kendinden ve patilerinden bahset...',
                    maxLines: 3,
                    focusShadowColor: EspatiColors.mintGreen,
                  ),
                  const SizedBox(height: 20),

                  NeoBrutalistTextField(
                    label: 'Bağlantı',
                    controller: _linkController,
                    hintText: 'https://...',
                    keyboardType: TextInputType.url,
                    focusShadowColor: EspatiColors.peach,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SAVE BUTTON — AppBar trailing action
// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;

  const _SaveButton({required this.isSaving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: EspatiColors.mintGreen,
          borderRadius: BorderRadius.zero,
          border: Border.fromBorderSide(
            BorderSide(color: Colors.black, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                'Kaydet',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR PICKER — large sharp square, thick border, tap-to-upload
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  final String photoUrl;
  final int imageVersion;
  final bool isUploading;
  final VoidCallback? onTap;

  static const double _size = 128;

  const _AvatarPicker({
    required this.photoUrl,
    required this.imageVersion,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: _size,
                height: _size,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: EspatiColors.peach,
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
                child: photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        // imageVersion busts the cache after each successful
                        // upload so the new photo loads immediately.
                        cacheKey: '${photoUrl}_v$imageVersion',
                        width: _size,
                        height: _size,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(
                            Icons.pets_rounded,
                            size: 48,
                            color: Colors.black),
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.pets_rounded,
                            size: 48,
                            color: Colors.black),
                      )
                    : const Icon(Icons.pets_rounded,
                        size: 48, color: Colors.black),
              ),
              if (isUploading)
                Container(
                  width: _size,
                  height: _size,
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NeoBrutalistButton(
          onPressed: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: EspatiColors.peach,
              borderRadius: BorderRadius.zero,
              border: Border.fromBorderSide(
                BorderSide(color: Colors.black, width: 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_camera_rounded,
                    size: 15, color: Colors.black),
                const SizedBox(width: 6),
                Text(
                  'Fotoğrafı Değiştir',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
