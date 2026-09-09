import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/chat_group_model.dart';
import '../../data/models/pet_model.dart';
import '../../viewmodels/create_post_viewmodel.dart';
import '../../viewmodels/form_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CREATE POST SCREEN (Neo-Brutalist pass — Design System Step 32)
//
// Responsibilities (View layer only):
//   • Render CreatePostViewModel state.
//   • Collect image, description, pet, and location from the user.
//   • Delegate submission to [CreatePostViewModel.submit] and pop on success.
//
// All business logic — compression, upload, state transitions — lives in the
// ViewModel. This screen only reacts to `vm.status` and `vm.uploadProgress`.
//
// The ONE real Post-creation screen in the app — reachable both from the
// Explore AppBar's "Oluştur" hub ([action_hub_sheet.dart], no
// [initialImagePath]/[onPosted]) and from the Story-camera flow
// ([CameraPreviewScreen]'s "İLERİ" button, both supplied). Step 32 merged
// what used to be a second, camera-only post-caption screen into this one
// instead (DRY) — [initialImagePath] pre-fills [CreatePostViewModel] so the
// camera's already-captured photo doesn't need re-picking, and [onPosted]
// lets that flow do its own "pop everything, return to the Explore feed"
// navigation on success instead of this screen's normal single `pop()`.
// ─────────────────────────────────────────────────────────────────────────────

class CreatePostScreen extends StatefulWidget {
  /// Pre-fills [CreatePostViewModel.selectedImage] — set when arriving from
  /// [CameraPreviewScreen], which already captured a photo and shouldn't
  /// make the user pick one again via the gallery/camera sheet below.
  final String? initialImagePath;

  /// Overrides the default post-success navigation (a single `pop()`) —
  /// set by the camera flow so it can pop every pushed camera route and
  /// swipe the Explore feed's PageView back to its feed page in one go.
  final VoidCallback? onPosted;

  const CreatePostScreen({super.key, this.initialImagePath, this.onPosted});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _picker = ImagePicker();

  // Eskişehir districts — the default list used until the user picks one.
  static const _kDistricts = [
    'Odunpazarı',
    'Tepebaşı',
    'Sazova Parkı',
    'Porsuk Bulvarı',
    'Kent Parkı',
    'Atlasjet Caddesi',
    'Çarşı',
    'Vişnelik',
  ];

  // Direct ViewModel reference — avoids calling context.read() inside dispose()
  // or async gaps where the element may already be deactivated.
  CreatePostViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialise once: capture the VM, seed the initial image/default
    // location, and wire the success-pop listener. All three are guarded by
    // the null check so didChangeDependencies re-entrancy (theme change,
    // etc.) is a no-op.
    if (_vm == null) {
      final vm = context.read<CreatePostViewModel>();
      _vm = vm;
      vm.addListener(_maybePopOnSuccess);
      // Deferred: calling either setter here invokes notifyListeners()
      // inside didChangeDependencies (which runs during
      // _flushDirtyElements), re-marking the Provider element dirty
      // mid-flush → !_dirty assertion crash.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final initialPath = widget.initialImagePath;
        if (initialPath != null && vm.selectedImage == null) {
          vm.setImage(File(initialPath));
        }
        if (vm.location.isEmpty) {
          vm.setLocation(_kDistricts.first);
        }
      });
    }
  }

  @override
  void dispose() {
    // Use the cached reference — context.read() is unsafe after deactivation
    // and causes a ProviderNotFoundException red screen on some device/OS combos.
    _vm?.removeListener(_maybePopOnSuccess);
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _maybePopOnSuccess() {
    final vm = _vm;
    if (vm == null || !mounted) return;
    if (vm.status == CreatePostStatus.success) {
      final onPosted = widget.onPosted;
      if (onPosted != null) {
        onPosted();
      } else {
        Navigator.of(context).pop();
      }
    } else if (vm.status == CreatePostStatus.error &&
        vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar(vm.errorMessage!, isError: true),
      );
      // Reset so the same error doesn't re-fire on every rebuild.
      vm.clearError();
    }
  }

  // ── Image picker ───────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 95, // High-quality source; VM does the real compression.
      maxWidth: 2400,
    );
    // Guard: null = user cancelled; !mounted = screen gone before picker returned.
    if (picked == null || !mounted) return;
    _vm?.setImage(File(picked.path));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Fotoğraf Seç',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                _ImageSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeriden Seç',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                _ImageSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamerayla Çek',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final vm = _vm;
    if (vm == null) return;

    if (vm.selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar('Lütfen bir fotoğraf seçin.', isError: true),
      );
      return;
    }
    if (vm.selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snackBar('Lütfen gönderideki patiyi seçin.', isError: true),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    HapticFeedback.mediumImpact();
    await vm.submit(description: _descriptionCtrl.text);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<CreatePostViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: NeoBrutal.scaffoldBg,
          appBar: AppBar(
            backgroundColor: NeoBrutal.scaffoldBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.black),
              onPressed:
                  vm.isUploading ? null : () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Yeni Gönderi',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                fontSize: 19,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
          ),
          body: AbsorbPointer(
            // Block all interaction while any pipeline phase is in flight.
            absorbing: vm.isUploading,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  _ImagePicker(
                    image: vm.selectedImage,
                    onTap: _showImageSourceSheet,
                    onClear: () => vm.clearImage(),
                  ),
                  const SizedBox(height: 20),

                  const _SectionLabel(text: 'Gönderideki pati *'),
                  const SizedBox(height: 8),
                  _HorizontalPetSelector(
                    pets: vm.pets,
                    loading: vm.petsLoading,
                    selected: vm.selectedPet,
                    onSelect: vm.selectPet,
                  ),
                  const SizedBox(height: 20),

                  const _SectionLabel(text: 'Açıklama'),
                  const SizedBox(height: 8),
                  _DescriptionField(controller: _descriptionCtrl),
                  const SizedBox(height: 16),

                  const _SectionLabel(text: 'Konum'),
                  const SizedBox(height: 8),
                  _BlockyField(
                    child: DropdownButtonFormField<String>(
                      initialValue: vm.location.isEmpty
                          ? _kDistricts.first
                          : vm.location,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.black),
                      dropdownColor: Colors.white,
                      decoration: _plainFieldDecoration(
                        prefixIcon: Icons.location_on_rounded,
                      ),
                      items: _kDistricts
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) vm.setLocation(v);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  const _SectionLabel(text: 'Hangi Topluluğa Gönderilecek?'),
                  const SizedBox(height: 8),
                  Consumer<FormViewModel>(
                    builder: (context, formVm, _) {
                      return _BlockyField(
                        child: DropdownButtonFormField<String?>(
                          initialValue: vm.groupId,
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black),
                          dropdownColor: Colors.white,
                          decoration: _plainFieldDecoration(
                            prefixIcon: Icons.forum_rounded,
                            hintText: 'Genel (isteğe bağlı)',
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Genel',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black)),
                            ),
                            ...formVm.chatGroups.map(
                              (ChatGroupModel g) => DropdownMenuItem<String?>(
                                value: g.id,
                                child: Text(g.name,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black)),
                              ),
                            ),
                          ],
                          onChanged: vm.setGroupId,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          bottomSheet: _SubmitBar(
            status: vm.status,
            progress: vm.uploadProgress,
            enabled: vm.canSubmit,
            onSubmit: _submit,
          ),
        );
      },
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  InputDecoration _plainFieldDecoration({
    IconData? prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
          fontSize: 14, color: Colors.black.withValues(alpha: 0.4)),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: Colors.black),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  SnackBar _snackBar(String message, {bool isError = false}) => SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: isError ? AppColors.error : EspatiColors.mintGreen,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.white, width: 1.5),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE SOURCE OPTION — blocky row in [_showImageSourceSheet]'s sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: EspatiColors.mintGreen,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOCKY FIELD — shared cream/dark-brown/hard-shadow frame around a plain
// (border-less, unfilled) input, used by the description field and both
// dropdowns so every input on this screen reads as one consistent
// Neo-Brutalist block instead of three different-looking widgets.
// ─────────────────────────────────────────────────────────────────────────────

class _BlockyField extends StatelessWidget {
  final Widget child;

  const _BlockyField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE PICKER — sharp, blocky preview/pick target (Design System Step 32)
// ─────────────────────────────────────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _ImagePicker({
    required this.image,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
          image: image != null
              ? DecorationImage(
                  image: FileImage(image!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_rounded,
                      size: 44, color: Colors.black),
                  const SizedBox(height: 8),
                  Text(
                    'Fotoğraf ekle',
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: onClear,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        border:
                            Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: Colors.black),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HORIZONTAL PET SELECTOR — the bridge between IPetRepository and PostModel
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalPetSelector extends StatelessWidget {
  final List<PetModel> pets;
  final bool loading;
  final PetModel? selected;
  final ValueChanged<PetModel?> onSelect;

  const _HorizontalPetSelector({
    required this.pets,
    required this.loading,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 108,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: EspatiColors.mintGreen,
            ),
          ),
        ),
      );
    }
    if (pets.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.pets, color: Colors.black, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Önce profilinden bir pati ekle; ardından gönderi paylaşabilirsin.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: pets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final pet = pets[i];
          final isSelected = pet.id == selected?.id;
          return _PetChip(
            pet: pet,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(isSelected ? null : pet);
            },
          );
        },
      ),
    );
  }
}

class _PetChip extends StatelessWidget {
  final PetModel pet;
  final bool isSelected;
  final VoidCallback onTap;

  const _PetChip({
    required this.pet,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? EspatiColors.mintGreen : Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: Colors.black,
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: pet.photoUrl.isEmpty
                  ? const Icon(Icons.pets,
                      color: Colors.black, size: 24)
                  : CachedNetworkImage(
                      imageUrl: pet.photoUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(Icons.pets,
                          color: Colors.black, size: 24),
                      errorWidget: (_, __, ___) => const Icon(Icons.pets,
                          color: Colors.black, size: 24),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              pet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESCRIPTION FIELD — 280 char limit with live counter
// ─────────────────────────────────────────────────────────────────────────────

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const _DescriptionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _BlockyField(
      child: TextFormField(
        controller: controller,
        maxLines: 4,
        maxLength: 280,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
        decoration: InputDecoration(
          hintText: 'Patiniz hakkında bir şeyler yazın... 🐾',
          hintStyle: GoogleFonts.poppins(
              fontSize: 14, color: Colors.black.withValues(alpha: 0.4)),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
          counterStyle: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'Açıklama boş olamaz.'
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL — sits directly on the light NeoBrutal.scaffoldBg canvas.
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black.withValues(alpha: 0.85),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBMIT BAR — blocky mintGreen "PAYLAŞ" CTA + upload progress
//
// Sticks to the bottom of the screen; consumes the full ViewModel status so
// the user sees: label + spinner + linear progress while Storage uploads.
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final CreatePostStatus status;
  final double progress;
  final bool enabled;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.status,
    required this.progress,
    required this.enabled,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isUploading = status == CreatePostStatus.compressing ||
        status == CreatePostStatus.uploading ||
        status == CreatePostStatus.saving;

    return Container(
      color: NeoBrutal.scaffoldBg,
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar is only visible while uploading — keeps the idle UI calm.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: isUploading
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: LinearProgressIndicator(
                        value: status == CreatePostStatus.compressing
                            ? null // indeterminate during compression
                            : progress,
                        minHeight: 6,
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          EspatiColors.mintGreen,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          GestureDetector(
            onTap: enabled ? onSubmit : null,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: enabled
                    ? EspatiColors.mintGreen
                    : EspatiColors.mintGreen.withValues(alpha: 0.4),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: enabled
                    ? const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: isUploading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _labelFor(status, progress),
                          style: GoogleFonts.fredoka(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'PAYLAŞ',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _labelFor(CreatePostStatus status, double progress) {
    switch (status) {
      case CreatePostStatus.compressing:
        return 'Fotoğraf hazırlanıyor…';
      case CreatePostStatus.uploading:
        return 'Yükleniyor %${(progress * 100).round()}';
      case CreatePostStatus.saving:
        return 'Kaydediliyor…';
      case CreatePostStatus.success:
        return 'Paylaşıldı ✓';
      case CreatePostStatus.error:
      case CreatePostStatus.idle:
        return 'PAYLAŞ';
    }
  }
}
