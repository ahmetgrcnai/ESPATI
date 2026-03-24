import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/models/listing_model.dart';
import '../viewmodels/form_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LISTING FORM SCREEN
// Shared form for both Adoption and Lost/Found listing creation.
// Driven by FormViewModel; all submission state lives in the ViewModel.
// ─────────────────────────────────────────────────────────────────────────────

class ListingFormScreen extends StatefulWidget {
  /// Determines the form title, accent colour, and saved [ListingStatus].
  final ListingStatus type;

  const ListingFormScreen({super.key, required this.type});

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  // ── Form infrastructure ───────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Text controllers ──────────────────────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _breedCtrl       = TextEditingController();
  final _ageCtrl         = TextEditingController();
  final _contactCtrl     = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // ── Dropdown selections ───────────────────────────────────────────────────
  String? _selectedSpecies;
  String? _selectedGender;
  String? _selectedDistrict;

  // ── Image picker ──────────────────────────────────────────────────────────
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  bool _imageError = false;

  static const int _maxImages      = 5;
  static const int _maxDescLength  = 500;

  // ── Dropdown options ──────────────────────────────────────────────────────

  static const List<String> _species = [
    'Kedi', 'Köpek', 'Kuş', 'Tavşan',
    'Balık', 'Sürüngen', 'Kemirgen', 'Diğer',
  ];

  static const List<String> _genders = ['Erkek', 'Dişi', 'Bilinmiyor'];

  static const List<String> _districts = [
    'Odunpazarı', 'Tepebaşı', 'Sivrihisar', 'İnönü',
    'Alpu', 'Beylikova', 'Çifteler', 'Günyüzü',
    'Han', 'Mahmudiye', 'Mihalgazi', 'Mihallıççık',
    'Sarıcakaya', 'Seyitgazi',
  ];

  // ── Convenience getters ───────────────────────────────────────────────────

  bool get _isAdoption => widget.type == ListingStatus.sahiplendirme;

  Color get _accentColor =>
      _isAdoption ? const Color(0xFFE65100) : AppColors.error;

  String get _screenTitle =>
      _isAdoption ? 'Sahiplendirme İlanı' : 'Kayıp/Buluntu İlanı';

  String get _submitLabel =>
      _isAdoption ? 'İlanı Yayınla' : 'Kaybı Bildir';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _ageCtrl.dispose();
    _contactCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // ── Image helpers ─────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;

    final picked = await _picker.pickMultiImage(limit: remaining);
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked);
        _imageError = false;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    if (_images.length >= _maxImages) return;

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo != null) {
      setState(() {
        _images.add(photo);
        _imageError = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Validate text fields
    final formValid = _formKey.currentState!.validate();

    // Validate images separately (not part of FormState)
    if (_images.isEmpty) {
      setState(() => _imageError = true);
    }

    if (!formValid || _images.isEmpty) return;

    final listing = ListingModel(
      id: 'lst_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      type: '${_selectedSpecies ?? ''} — ${_breedCtrl.text.trim()}',
      status: widget.type,
      location: _selectedDistrict ?? '',
      date: _formatDate(DateTime.now()),
      // In production, upload images to storage and store the URL.
      imageUrl: 'https://placekitten.com/400/400',
      contact: _contactCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    final vm = context.read<FormViewModel>();
    final success = await vm.createListing(listing);

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.submitError ?? 'Bir hata oluştu.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      vm.clearSubmitError();
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.softTeal.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle_rounded,
              color: AppColors.softTeal, size: 40),
        ),
        title: Text(
          'İlan Yayında!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'İlanınız başarıyla oluşturuldu.\nForum → İlanlar bölümünden görüntüleyebilirsiniz.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14,
              color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.65)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);      // close dialog
              Navigator.pop(context);  // return to FormHubScreen
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.softTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 12),
            ),
            child: Text('Harika!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Consumer<FormViewModel>(
      builder: (context, vm, _) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: _buildAppBar(theme, cs),
              body: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    // ── Header banner ─────────────────────────────────────
                    _TypeBanner(isAdoption: _isAdoption, accentColor: _accentColor),
                    const SizedBox(height: 20),

                    // ── Section 1: Hayvan Bilgileri ───────────────────────
                    _SectionHeader(
                        label: 'Hayvan Bilgileri',
                        icon: Icons.pets_rounded),
                    const SizedBox(height: 12),
                    _FormCard(
                      isDark: isDark,
                      children: [
                        _buildTextField(
                          controller: _nameCtrl,
                          label: 'İsim',
                          hint: 'Örn: Rocky, Mimi',
                          icon: Icons.badge_rounded,
                          validator: _requiredValidator('İsim'),
                        ),
                        const SizedBox(height: 14),
                        _buildDropdown(
                          label: 'Tür',
                          hint: 'Hayvan türünü seçin',
                          icon: Icons.category_rounded,
                          value: _selectedSpecies,
                          items: _species,
                          onChanged: (v) =>
                              setState(() => _selectedSpecies = v),
                          validator: (v) =>
                              v == null ? 'Tür seçimi zorunludur' : null,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _breedCtrl,
                          label: 'Irk / Cins',
                          hint: 'Örn: Golden Retriever, Tekir',
                          icon: Icons.info_outline_rounded,
                          validator: _requiredValidator('Irk/Cins'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _ageCtrl,
                                label: 'Yaş',
                                hint: 'Örn: 2',
                                icon: Icons.cake_rounded,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: _requiredValidator('Yaş'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: _buildDropdown(
                                label: 'Cinsiyet',
                                hint: 'Seçin',
                                icon: Icons.wc_rounded,
                                value: _selectedGender,
                                items: _genders,
                                onChanged: (v) =>
                                    setState(() => _selectedGender = v),
                                validator: (v) => v == null
                                    ? 'Cinsiyet zorunludur'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Section 2: Konum ─────────────────────────────────
                    _SectionHeader(
                        label: 'Konum', icon: Icons.location_on_rounded),
                    const SizedBox(height: 12),
                    _FormCard(
                      isDark: isDark,
                      children: [
                        _buildDropdown(
                          label: 'İlçe',
                          hint: 'Eskişehir ilçesini seçin',
                          icon: Icons.map_rounded,
                          value: _selectedDistrict,
                          items: _districts,
                          onChanged: (v) =>
                              setState(() => _selectedDistrict = v),
                          validator: (v) =>
                              v == null ? 'İlçe seçimi zorunludur' : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Section 3: İletişim ──────────────────────────────
                    _SectionHeader(
                        label: 'İletişim', icon: Icons.phone_rounded),
                    const SizedBox(height: 12),
                    _FormCard(
                      isDark: isDark,
                      children: [
                        _buildTextField(
                          controller: _contactCtrl,
                          label: 'Telefon',
                          hint: '05XX XXX XX XX',
                          icon: Icons.call_rounded,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9 +]')),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Telefon numarası zorunludur';
                            }
                            if (v.trim().replaceAll(' ', '').length < 10) {
                              return 'Geçerli bir telefon numarası girin';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Section 4: Açıklama ──────────────────────────────
                    _SectionHeader(
                        label: 'Açıklama', icon: Icons.description_rounded),
                    const SizedBox(height: 12),
                    _FormCard(
                      isDark: isDark,
                      children: [
                        TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 5,
                          maxLength: _maxDescLength,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Açıklama',
                            hintText: _isAdoption
                                ? 'Hayvanın karakterini, bakım gereksinimlerini ve ideal yuvasını anlatın...'
                                : 'Kaybolduğu yer, zaman, fiziksel özellikler ve son görülme koşullarını anlatın...',
                            labelStyle:
                                GoogleFonts.poppins(fontSize: 13),
                            hintStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: cs.onSurface.withOpacity(0.38)),
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 64),
                              child: Icon(Icons.edit_note_rounded,
                                  size: 20,
                                  color: cs.onSurface.withOpacity(0.5)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Açıklama zorunludur';
                            }
                            if (v.trim().length < 20) {
                              return 'Açıklama en az 20 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Section 5: Fotoğraflar ───────────────────────────
                    _SectionHeader(
                        label: 'Fotoğraflar', icon: Icons.photo_library_rounded),
                    const SizedBox(height: 4),
                    Text(
                      'En az 1, en fazla $_maxImages fotoğraf ekleyin.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ImagePickerSection(
                      images: _images,
                      hasError: _imageError,
                      maxImages: _maxImages,
                      onGallery: _pickFromGallery,
                      onCamera: _pickFromCamera,
                      onRemove: _removeImage,
                      isDark: isDark,
                      cs: cs,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // ── Submit button ─────────────────────────────────────────
              bottomNavigationBar: _SubmitBar(
                label: _submitLabel,
                accentColor: _accentColor,
                isSubmitting: vm.isSubmitting,
                onSubmit: _submit,
              ),
            ),

            // ── Full-screen loading overlay ───────────────────────────────
            if (vm.isSubmitting)
              Container(
                color: Colors.black.withOpacity(0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surface
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            color: AppColors.softTeal, strokeWidth: 3),
                        const SizedBox(height: 16),
                        Text(
                          'İlan yayınlanıyor...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(ThemeData theme, ColorScheme cs) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Kapat',
      ),
      title: Text(
        _screenTitle,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: cs.onSurface,
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Field builders ────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)),
        prefixIcon: Icon(icon, size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.poppins(
          fontSize: 14, color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        hintStyle: GoogleFonts.poppins(
            fontSize: 13, color: cs.onSurface.withOpacity(0.38)),
        prefixIcon: Icon(icon, size: 20,
            color: cs.onSurface.withOpacity(0.5)),
      ),
      dropdownColor:
          Theme.of(context).brightness == Brightness.dark
              ? cs.surface
              : Colors.white,
      borderRadius: BorderRadius.circular(16),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: cs.onSurface.withOpacity(0.5)),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item,
                    style: GoogleFonts.poppins(fontSize: 14)),
              ))
          .toList(),
    );
  }

  String? Function(String?) _requiredValidator(String fieldName) {
    return (v) => (v == null || v.trim().isEmpty)
        ? '$fieldName zorunludur'
        : null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPPORTING WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Coloured banner at the top of the form indicating listing type.
class _TypeBanner extends StatelessWidget {
  final bool isAdoption;
  final Color accentColor;

  const _TypeBanner({required this.isAdoption, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAdoption ? Icons.favorite_rounded : Icons.search_rounded,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdoption
                      ? 'Sahiplendirme İlanı'
                      : 'Kayıp/Buluntu İlanı',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAdoption
                      ? 'Evcil hayvanınıza sıcak bir yuva bulun'
                      : 'Kayıp hayvanınızı bildirin veya bulduğunuzu paylaşın',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: accentColor.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header with teal accent line.
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.softTeal),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.softTeal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.softTeal.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}

/// White/surface card wrapping form fields.
class _FormCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _FormCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Horizontal image preview strip with add buttons.
class _ImagePickerSection extends StatelessWidget {
  final List<XFile> images;
  final bool hasError;
  final int maxImages;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final ValueChanged<int> onRemove;
  final bool isDark;
  final ColorScheme cs;

  const _ImagePickerSection({
    required this.images,
    required this.hasError,
    required this.maxImages,
    required this.onGallery,
    required this.onCamera,
    required this.onRemove,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add buttons row
        Row(
          children: [
            _PickerButton(
              icon: Icons.photo_library_rounded,
              label: 'Galeri',
              onTap: onGallery,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _PickerButton(
              icon: Icons.camera_alt_rounded,
              label: 'Kamera',
              onTap: onCamera,
              isDark: isDark,
            ),
            const Spacer(),
            Text(
              '${images.length}/$maxImages',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: images.isEmpty && hasError
                    ? AppColors.error
                    : cs.onSurface.withOpacity(0.45),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // Error label
        if (hasError && images.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'En az 1 fotoğraf eklemeniz zorunludur',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ],

        // Preview strip
        if (images.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) => _ImageThumb(
                xFile: images[index],
                onRemove: () => onRemove(index),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Theme.of(context).colorScheme.surface
              : AppColors.softTealLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.softTeal.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.softTeal),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.softTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final XFile xFile;
  final VoidCallback onRemove;

  const _ImageThumb({required this.xFile, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softTeal.withOpacity(0.3)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.file(
              File(xFile.path),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky submit button bar pinned to the bottom of the screen.
class _SubmitBar extends StatelessWidget {
  final String label;
  final Color accentColor;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.label,
    required this.accentColor,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          disabledBackgroundColor: accentColor.withOpacity(0.5),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

String _formatDate(DateTime dt) {
  const months = [
    '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];
  return '${dt.day} ${months[dt.month]} ${dt.year}';
}
