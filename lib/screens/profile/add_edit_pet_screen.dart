import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/pet_model.dart';
import '../../services/content_moderation_service.dart';
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

  // ── Çiftleşme (mating) profile — see PetModel's own fields for why
  // these three are kept in lockstep (isAvailableForMating can't be true
  // without the other two). ──
  bool _isAvailableForMating = false;
  bool _isVaccinated = false;
  File? _newVaccinationCardImage;
  late Set<PetCharacterTag> _selectedCharacterTags;

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
    _isAvailableForMating = p?.isAvailableForMating ?? false;
    _isVaccinated = p?.isVaccinated ?? false;
    _selectedCharacterTags = {...(p?.characterTags ?? const [])};
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

  Future<void> _pickVaccinationCard() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (picked != null && mounted) {
      setState(() => _newVaccinationCardImage = File(picked.path));
    }
  }

  /// Çiftleşme module gate — [PetModel.isEligibleForMating] mirrors this on
  /// the read side, but the *write* side needs its own check so a user
  /// can't flip "Eşleşme Arıyor" on without ever having provided the proof
  /// it depends on. Returns an error string, or `null` if everything the
  /// flag requires is in place.
  String? _validateMatingProfile() {
    if (!_isAvailableForMating) return null;
    if (!_isVaccinated) {
      return 'Eşleşme için temel aşıların tam olduğunu beyan etmelisin.';
    }
    final hasCard = _newVaccinationCardImage != null ||
        (widget.existingPet?.vaccinationCardUrl.isNotEmpty ?? false);
    if (!hasCard) {
      return 'Eşleşme için aşı karnesi fotoğrafı yüklemelisin.';
    }
    // Madde 4 — ethics pass: reject commercial/sale language in the bio
    // before it ever reaches a profile other users can browse in the
    // swipe deck. Only checked when the mating flag is on — a plain pet
    // profile's bio isn't held to this (it's not a breeding listing).
    if (ContentModerationService.containsCommercialLanguage(
        _bioController.text)) {
      return 'Kısa tanıtım ticari satış ifadeleri içeriyor gibi görünüyor. '
          'Bu bir eşleşme profili, satış ilanı değil.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final matingError = _validateMatingProfile();
    if (matingError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(matingError, style: GoogleFonts.nunitoSans(fontSize: 13)),
          backgroundColor: EspatiColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final vm = context.read<ProfileViewModel>();
    final existingPet = widget.existingPet;
    final parsedWeight = double.tryParse(
        _weightController.text.trim().replaceAll(',', '.'));
    final characterTags = _selectedCharacterTags.toList();

    if (widget.isEditing && existingPet != null) {
      // ── Edit mode ────────────────────────────────────────────────────────
      // Same "clear/invalid input keeps the previous value" fallback [age]
      // already had — [parsedWeight] used to fall back to 0 unconditionally,
      // silently zeroing a pet's real weight if the field was ever cleared.
      final updated = existingPet.copyWith(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? existingPet.age,
        petType: _selectedType,
        gender: _selectedGender,
        bio: _bioController.text.trim(),
        weight: parsedWeight ?? existingPet.weight,
        isAvailableForMating: _isAvailableForMating,
        isVaccinated: _isVaccinated,
        characterTags: characterTags,
      );
      await vm.updatePet(
        updated,
        newImage: _newImage,
        newVaccinationCardImage: _newVaccinationCardImage,
      );
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
        weight: parsedWeight ?? 0,
        isAvailableForMating: _isAvailableForMating,
        isVaccinated: _isVaccinated,
        characterTags: characterTags,
      );
      await vm.addPet(
        pet,
        image: _newImage,
        vaccinationCardImage: _newVaccinationCardImage,
      );
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
          style: GoogleFonts.baloo2(
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
                  style: GoogleFonts.baloo2(
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
                              style: GoogleFonts.nunitoSans(
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
                  style: GoogleFonts.baloo2(
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
                const SizedBox(height: 28),

                // ── Çiftleşme profili ────────────────────────────────────────
                _MatingProfileSection(
                  isAvailableForMating: _isAvailableForMating,
                  onAvailableForMatingChanged: (v) =>
                      setState(() => _isAvailableForMating = v),
                  isVaccinated: _isVaccinated,
                  onVaccinatedChanged: (v) =>
                      setState(() => _isVaccinated = v),
                  newVaccinationCardImage: _newVaccinationCardImage,
                  existingVaccinationCardUrl:
                      widget.existingPet?.vaccinationCardUrl ?? '',
                  onPickVaccinationCard: _pickVaccinationCard,
                  selectedTags: _selectedCharacterTags,
                  onToggleTag: (tag) => setState(() {
                    if (_selectedCharacterTags.contains(tag)) {
                      _selectedCharacterTags.remove(tag);
                    } else {
                      _selectedCharacterTags.add(tag);
                    }
                  }),
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
                                style: GoogleFonts.baloo2(
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
                            style: GoogleFonts.baloo2(
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
// MATING PROFILE SECTION — the Çiftleşme (mating) module's opt-in block.
// "Eşleşme Arıyor" only ever means anything once the vaccine declaration +
// card photo are both in place — see [PetModel.isEligibleForMating] and
// [_AddEditPetScreenState._validateMatingProfile]. Character tags are
// always editable regardless of the toggle (harmless either way, and
// keeping them set saves re-picking if the owner re-enables it later).
// ─────────────────────────────────────────────────────────────────────────────

class _MatingProfileSection extends StatelessWidget {
  final bool isAvailableForMating;
  final ValueChanged<bool> onAvailableForMatingChanged;
  final bool isVaccinated;
  final ValueChanged<bool> onVaccinatedChanged;
  final File? newVaccinationCardImage;
  final String existingVaccinationCardUrl;
  final VoidCallback onPickVaccinationCard;
  final Set<PetCharacterTag> selectedTags;
  final ValueChanged<PetCharacterTag> onToggleTag;

  const _MatingProfileSection({
    required this.isAvailableForMating,
    required this.onAvailableForMatingChanged,
    required this.isVaccinated,
    required this.onVaccinatedChanged,
    required this.newVaccinationCardImage,
    required this.existingVaccinationCardUrl,
    required this.onPickVaccinationCard,
    required this.selectedTags,
    required this.onToggleTag,
  });

  @override
  Widget build(BuildContext context) {
    final hasCard =
        newVaccinationCardImage != null || existingVaccinationCardUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: EspatiColors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                'Çiftleşme Profili',
                style: GoogleFonts.baloo2(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => onAvailableForMatingChanged(!isAvailableForMating),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isAvailableForMating
                    ? EspatiColors.red.withValues(alpha: 0.12)
                    : NeoBrutal.inactiveFill,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Eşleşme Arıyor',
                      style: GoogleFonts.baloo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Icon(
                    isAvailableForMating
                        ? Icons.toggle_on_rounded
                        : Icons.toggle_off_outlined,
                    size: 30,
                    color: isAvailableForMating ? EspatiColors.red : Colors.black45,
                  ),
                ],
              ),
            ),
          ),
          if (isAvailableForMating) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => onVaccinatedChanged(!isVaccinated),
              child: Row(
                children: [
                  Icon(
                    isVaccinated
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Temel aşılarım tam (beyan ederim)',
                      style: GoogleFonts.nunitoSans(fontSize: 13, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onPickVaccinationCard,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasCard ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                      color: hasCard ? EspatiColors.sageGreen : Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasCard ? 'Aşı karnesi yüklendi (değiştir)' : 'Aşı karnesi fotoğrafı yükle',
                        style: GoogleFonts.nunitoSans(fontSize: 13, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Karakter Etiketleri',
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PetCharacterTag.values.map((tag) {
                final selected = selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () => onToggleTag(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? EspatiColors.sageGreen : Colors.white,
                      border: Border.all(
                        color: Colors.black,
                        width: selected ? 2 : 1.5,
                      ),
                    ),
                    child: Text(
                      tag.label,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'Bu bir satış ilanı değildir — kısa tanıtımda fiyat/satış ifadesi kullanma.',
              style: GoogleFonts.nunitoSans(
                fontSize: 11,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ],
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
              style: GoogleFonts.baloo2(
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
