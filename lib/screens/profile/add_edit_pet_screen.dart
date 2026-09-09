import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/pet_model.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/common/neo_brutalist_text_field.dart';

const _petTypeLabels = {
  PetType.dog: 'Köpek',
  PetType.cat: 'Kedi',
  PetType.bird: 'Kuş',
  PetType.fish: 'Balık',
  PetType.rabbit: 'Tavşan',
  PetType.hamster: 'Hamster',
  PetType.turtle: 'Kaplumbağa',
  PetType.other: 'Diğer',
};

const _petTypeEmojis = {
  PetType.dog: '🐕',
  PetType.cat: '🐈',
  PetType.bird: '🐦',
  PetType.fish: '🐟',
  PetType.rabbit: '🐰',
  PetType.hamster: '🐹',
  PetType.turtle: '🐢',
  PetType.other: '🐾',
};

// ─────────────────────────────────────────────────────────────────────────────
// ADD/EDIT PET SCREEN — Neo-Brutalist rebuild, aligned to the app's current
// design system (same [NeoBrutal] tokens as Keşfet/[ProfileScreen]).
//
// The "AddPetScreen" brief describes this screen's add-mode; it's rebuilt
// in place rather than forked into a parallel screen — this one already
// handles both add and edit (pass [existingPet] to edit), is wired from
// both of ProfileScreen's real entry points ("Pati Ekle" and the pet
// long-press "Düzenle" sheet), and a second, unwired copy would just be
// dead code sitting next to the real thing.
//
// [NeoBrutalistTextField] is reused as-is for every text field rather than
// re-implemented here — it was itself just migrated off the older cream/
// darkBrown palette onto white/black, so this screen picks that up for
// free.
//
// The gender toggle is real, not decorative: [PetModel.gender] already
// existed on the model and round-trips through Firestore via
// [PetModel.toJson]/[PetModel.fromJson] — this screen previously just never
// surfaced a control for it (add mode hardcoded [PetGender.unknown], edit
// mode never touched it).
// ─────────────────────────────────────────────────────────────────────────────

class AddEditPetScreen extends StatefulWidget {
  final PetModel? existingPet;

  const AddEditPetScreen({super.key, this.existingPet});

  bool get isEditing => existingPet != null;

  @override
  State<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends State<AddEditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _bioController;
  late PetType _selectedType;
  late PetGender _selectedGender;

  /// Newly picked local file (null = keep existing remote photo).
  File? _newImage;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPet;
    _nameController = TextEditingController(text: p?.name ?? '');
    _breedController = TextEditingController(text: p?.breed ?? '');
    _ageController =
        TextEditingController(text: p != null && p.age > 0 ? '${p.age}' : '');
    _weightController = TextEditingController(
        text: p != null && p.weight > 0 ? _formatWeight(p.weight) : '');
    _bioController = TextEditingController(text: p?.bio ?? '');
    _selectedType = p?.petType ?? PetType.dog;
    // The toggle only offers two options — an existing PetGender.unknown
    // (pets added before this step shipped) falls back to male rather than
    // rendering neither segment selected.
    _selectedGender =
        p?.gender == PetGender.female ? PetGender.female : PetGender.male;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  static String _formatWeight(double w) =>
      w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toString();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 600);
    if (picked != null && mounted) {
      setState(() => _newImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final vm = context.read<ProfileViewModel>();
    final existingPet = widget.existingPet;
    final weight = double.tryParse(
            _weightController.text.trim().replaceAll(',', '.')) ??
        0;

    if (widget.isEditing && existingPet != null) {
      // ── Edit mode ────────────────────────────────────────────────────────
      final updated = existingPet.copyWith(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? existingPet.age,
        petType: _selectedType,
        gender: _selectedGender,
        bio: _bioController.text.trim(),
        weight: weight,
      );
      await vm.updatePet(updated, newImage: _newImage);
    } else {
      // ── Add mode ─────────────────────────────────────────────────────────
      final pet = PetModel(
        id: '',
        ownerId: vm.user.id,
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        gender: _selectedGender,
        medicalHistorySummary: '',
        petType: _selectedType,
        photoUrl: '',
        bio: _bioController.text.trim(),
        weight: weight,
      );
      await vm.addPet(pet, image: _newImage);
    }

    if (!mounted) return;

    if (vm.petError == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingPhotoUrl = widget.existingPet?.photoUrl ?? '';

    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.isEditing ? 'Patiyi Düzenle' : 'Yeni Pati Ekle',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Photo uploader ──────────────────────────────────────────
                Center(
                  child: _PetPhotoPicker(
                    newImage: _newImage,
                    existingPhotoUrl: existingPhotoUrl,
                    onTap: _pickImage,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Species chips ───────────────────────────────────────────
                Text(
                  'Pati Türü',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: PetType.values.map((type) {
                      final selected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = type),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? EspatiColors.sageGreen
                                  : Colors.white,
                              borderRadius: BorderRadius.zero,
                              border: Border.all(
                                  color: Colors.black, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Text(
                              '${_petTypeEmojis[type]} ${_petTypeLabels[type]}',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Name ─────────────────────────────────────────────────────
                NeoBrutalistTextField(
                  label: 'Pati Adı',
                  controller: _nameController,
                  hintText: 'Örn: Luna',
                  textCapitalization: TextCapitalization.words,
                  focusShadowColor: EspatiColors.sageGreen,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Pati adı zorunludur'
                      : null,
                ),
                const SizedBox(height: 20),

                // ── Breed ────────────────────────────────────────────────────
                NeoBrutalistTextField(
                  label: 'Tür / Cins',
                  controller: _breedController,
                  hintText: 'Örn: Golden Retriever',
                  textCapitalization: TextCapitalization.words,
                  focusShadowColor: EspatiColors.terracotta,
                ),
                const SizedBox(height: 20),

                // ── Age + Weight ─────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: NeoBrutalistTextField(
                        label: 'Yaş',
                        controller: _ageController,
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        focusShadowColor: EspatiColors.sageGreen,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return int.tryParse(v.trim()) == null
                              ? 'Sayı gir'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeoBrutalistTextField(
                        label: 'Kilo (kg)',
                        controller: _weightController,
                        hintText: '0',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        focusShadowColor: EspatiColors.terracotta,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return double.tryParse(
                                      v.trim().replaceAll(',', '.')) ==
                                  null
                              ? 'Sayı gir'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Gender toggle ────────────────────────────────────────────
                Text(
                  'Cinsiyet',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _GenderOption(
                        label: 'Erkek',
                        icon: Icons.male_rounded,
                        selected: _selectedGender == PetGender.male,
                        onTap: () =>
                            setState(() => _selectedGender = PetGender.male),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderOption(
                        label: 'Dişi',
                        icon: Icons.female_rounded,
                        selected: _selectedGender == PetGender.female,
                        onTap: () => setState(
                            () => _selectedGender = PetGender.female),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Bio ──────────────────────────────────────────────────────
                NeoBrutalistTextField(
                  label: 'Kısa Tanıtım',
                  controller: _bioController,
                  hintText: 'Karakteri, alışkanlıkları...',
                  maxLines: 2,
                  focusShadowColor: EspatiColors.sageGreen,
                ),
                const SizedBox(height: 32),

                // ── Save ─────────────────────────────────────────────────────
                NeoBrutalistButton(
                  onPressed: _submitting ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 19),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _submitting
                          ? EspatiColors.terracotta.withValues(alpha: 0.6)
                          : EspatiColors.terracotta,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                          color: Colors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(5, 5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.pets_rounded,
                                  color: Colors.black, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                widget.isEditing
                                    ? 'Değişiklikleri Kaydet'
                                    : 'Aileye Kat',
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PET PHOTO PICKER — large square Neo-Brutalist block, terracotta hard
// shadow. Shows the newly-picked local file, else the existing remote
// photo, else an "add a photo" prompt.
// ─────────────────────────────────────────────────────────────────────────────

class _PetPhotoPicker extends StatelessWidget {
  final File? newImage;
  final String existingPhotoUrl;
  final VoidCallback onTap;

  static const double _size = 140;

  const _PetPhotoPicker({
    required this.newImage,
    required this.existingPhotoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = newImage != null || existingPhotoUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: _size,
            height: _size,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.zero,
              border: Border.fromBorderSide(
                BorderSide(color: Colors.black, width: 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: EspatiColors.terracotta,
                  offset: Offset(5, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: newImage != null
                ? Image.file(newImage!,
                    width: _size, height: _size, fit: BoxFit.cover)
                : existingPhotoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: existingPhotoUrl,
                        width: _size,
                        height: _size,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(
                            Icons.pets_rounded,
                            size: 40,
                            color: Colors.black),
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.pets_rounded,
                            size: 40,
                            color: Colors.black),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_rounded,
                              size: 32, color: Colors.black),
                          const SizedBox(height: 6),
                          Text(
                            'Fotoğraf Ekle',
                            style: GoogleFonts.fredoka(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
          ),
          if (hasPhoto)
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: EspatiColors.sageGreen,
                  borderRadius: BorderRadius.zero,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 14, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GENDER OPTION — blocky toggle segment. Selected: sageGreen + hard shadow.
// Unselected: flat white with just the thick border, no shadow.
// ─────────────────────────────────────────────────────────────────────────────

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? EspatiColors.sageGreen : Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
