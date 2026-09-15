import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart' show EspatiColors;
import '../core/eskisehir_districts.dart';
import '../core/neo_brutalist_tokens.dart';
import '../data/models/listing_model.dart';
import '../services/content_moderation_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/form_viewmodel.dart';
import '../widgets/common/neo_brutalist_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LISTING FORM SCREEN (Neo-Brutalist pass — aligned to the app's actual
// current design system)
//
// Shared form for Sahiplendirme / Kayıp-Buluntu / Bakıcı listing creation.
// Same [NeoBrutal] tokens (white/near-white canvas, solid black borders,
// hard black offset shadows) as every other current-generation screen —
// Keşfet ([AlgorithmicFeedScreen]), Paties, Pati-AI & Akademi, guide
// detail. The cream/dark-brown palette ([CreatePostScreen],
// [action_hub_sheet.dart]) is an earlier design-system generation this
// screen no longer follows — see the app's own "Step 66" migration note
// on [AlgorithmicFeedScreen] ("was the dark-brown scaffold").
//
// [ListingStatus.bakici] is a service listing, not an animal listing, so it
// swaps the "Hayvan Bilgileri" section for "Hizmet Bilgileri" (service
// title, species scope, offered services, price) instead of reusing
// name/breed/age/gender fields for data they don't actually mean — see
// [ListingModel.serviceTypes] / [ListingModel.priceInfo].
//
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
  final _priceCtrl       = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // ── Dropdown selections ───────────────────────────────────────────────────
  String? _selectedSpecies;
  String? _selectedGender;
  String? _selectedDistrict;

  /// Target community group ("Hangi Topluluğa Gönderilecek?"). `null` =
  /// "Genel" — the listing isn't routed to a specific group.
  String? _selectedGroupId;

  /// "Acil" toggle — only meaningful (and only shown) for Kayıp listings.
  bool _isUrgent = false;

  /// Offered services — only meaningful (and only shown) for Bakıcı listings.
  final Set<String> _selectedServiceTypes = {};
  bool _serviceTypeError = false;

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

  static const String _allSpecies = 'Tüm Türler';

  static const List<String> _genders = ['Erkek', 'Dişi', 'Bilinmiyor'];

  static const List<String> _districts = [
    'Odunpazarı', 'Tepebaşı', 'Sivrihisar', 'İnönü',
    'Alpu', 'Beylikova', 'Çifteler', 'Günyüzü',
    'Han', 'Mahmudiye', 'Mihalgazi', 'Mihallıççık',
    'Sarıcakaya', 'Seyitgazi',
  ];

  static const List<String> _serviceTypeOptions = [
    'Gezdirme',
    'Günlük Bakım',
    'Pansiyon (Ev Sahipliği)',
    'Eğitim',
    'Veteriner Refakati',
    'Tımar / Bakım',
  ];

  // ── Convenience getters ───────────────────────────────────────────────────

  bool get _isKayip   => widget.type == ListingStatus.kayip;
  bool get _isBakici  => widget.type == ListingStatus.bakici;

  Color get _accentColor => widget.type.accentColor;

  String get _screenTitle => widget.type.title;

  String get _submitLabel => _isKayip ? 'Kaybı Bildir' : 'İlanı Yayınla';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _ageCtrl.dispose();
    _priceCtrl.dispose();
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

  void _toggleServiceType(String type) {
    setState(() {
      if (!_selectedServiceTypes.remove(type)) {
        _selectedServiceTypes.add(type);
      }
      if (_selectedServiceTypes.isNotEmpty) _serviceTypeError = false;
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Validate text fields
    final formValid = _formKey.currentState!.validate();

    // Validate images separately (not part of FormState)
    if (_images.isEmpty) {
      setState(() => _imageError = true);
    }

    // Bakıcı listings validate offered services instead of breed/age/gender.
    if (_isBakici && _selectedServiceTypes.isEmpty) {
      setState(() => _serviceTypeError = true);
    }

    if (!formValid || _images.isEmpty) return;
    if (_isBakici && _selectedServiceTypes.isEmpty) return;

    // Madde 8 — safety mandate: reject inappropriate text before it ever
    // reaches Firestore. Checks every user-authored text field together
    // (title fields + free-text description) in one pass.
    final moderationText =
        '${_nameCtrl.text} ${_breedCtrl.text} ${_descriptionCtrl.text}';
    if (ContentModerationService.containsInappropriateText(moderationText)) {
      _showSnackBar(
        'İçeriğiniz topluluk kurallarımıza uymayan ifadeler içeriyor.',
        isError: true,
      );
      return;
    }

    final vm = context.read<FormViewModel>();

    if (vm.isSubmitting) {
      // Guards against the "silent failure" case: isSubmitting stuck true
      // from an interrupted earlier attempt would otherwise disable this
      // button entirely (see _SubmitBar's onPressed), so tapping it does
      // nothing with zero feedback. Surface that explicitly instead.
      _showSnackBar(
        'Bir işlem zaten devam ediyor. Lütfen bekleyin veya uygulamayı '
        'yeniden başlatın.',
        isError: true,
      );
      return;
    }

    try {
      final currentUser = context.read<AuthViewModel>().currentUser;
      final (lat, lng) = EskisehirDistricts.resolve(_selectedDistrict ?? '');

      final listing = ListingModel(
        // Repository assigns the real Firestore document ID.
        id: '',
        name: _nameCtrl.text.trim(),
        type: _isBakici
            ? _selectedServiceTypes.join(', ')
            : '${_selectedSpecies ?? ''} — ${_breedCtrl.text.trim()}',
        species: _selectedSpecies ?? '',
        status: widget.type,
        location: _selectedDistrict ?? '',
        date: _formatDate(DateTime.now()),
        // Repository fills this in after uploading _images to Storage.
        imageUrls: const [],
        description: _descriptionCtrl.text.trim(),
        createdAt: DateTime.now(),
        // Needed so other users can message this listing's author (Sprint 8).
        authorId: currentUser?.id ?? '',
        authorName: currentUser?.name.isNotEmpty == true
            ? currentUser!.name
            : (currentUser?.email ?? ''),
        authorPhoto: currentUser?.profilePicture ?? '',
        latitude: lat,
        longitude: lng,
        isUrgent: _isKayip ? _isUrgent : false,
        groupId: _selectedGroupId,
        serviceTypes: _isBakici ? _selectedServiceTypes.toList() : const [],
        priceInfo: _isBakici ? _priceCtrl.text.trim() : '',
      );

      final success = await vm.createListing(
        listing,
        _images.map((x) => File(x.path)).toList(),
      );

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        _showSnackBar(vm.submitError ?? 'Bir hata oluştu.', isError: true);
        vm.clearSubmitError();
      }
    } catch (e, stack) {
      // Belt-and-suspenders: anything that throws *before* reaching
      // vm.createListing (which already has its own try/catch) would
      // otherwise be an uncaught exception with no visible feedback —
      // exactly the "tap and nothing happens" symptom.
      debugPrint('[ListingFormScreen] _submit unexpected exception: $e\n$stack');
      if (!mounted) return;
      _showSnackBar('Beklenmedik bir hata oluştu. Lütfen tekrar deneyin.',
          isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.nunitoSans(fontSize: 13)),
        backgroundColor: isError ? EspatiColors.red : EspatiColors.sageGreen,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.black, width: 2),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: NeoBrutal.border(3),
            boxShadow: NeoBrutal.shadow(const Offset(4, 4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: EspatiColors.sageGreen,
                  borderRadius: BorderRadius.zero,
                  border: NeoBrutal.border(2.5),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.black, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'İlan Yayında!',
                textAlign: TextAlign.center,
                style: GoogleFonts.baloo2(
                  fontWeight: FontWeight.w600,
                  fontSize: 19,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'İlanınız başarıyla oluşturuldu.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 20),
              NeoBrutalistButton(
                semanticLabel: 'Harika',
                onPressed: () {
                  Navigator.pop(ctx);      // close dialog
                  Navigator.pop(context);  // return to caller
                },
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: EspatiColors.sageGreen,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(2.5),
                    boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
                  ),
                  child: Text(
                    'Harika!',
                    style: GoogleFonts.baloo2(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<FormViewModel>(
      builder: (context, vm, _) {
        return Stack(
          children: [
            Scaffold(
              // Same canvas as Keşfet/Paties/Pati-AI & Akademi — not the
              // global theme's dark-brown scaffold default.
              backgroundColor: NeoBrutal.scaffoldBg,
              appBar: _ListingFormAppBar(title: _screenTitle),
              body: AbsorbPointer(
                absorbing: vm.isSubmitting,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // ── Type banner ─────────────────────────────────────
                      _TypeBanner(type: widget.type),
                      const SizedBox(height: 20),

                      // ── Section 1: Hayvan Bilgileri / Hizmet Bilgileri ──
                      _SectionLabel(
                          text:
                              _isBakici ? 'Hizmet Bilgileri' : 'Hayvan Bilgileri'),
                      const SizedBox(height: 8),
                      if (_isBakici) ..._buildBakiciFields() else ..._buildAnimalFields(),

                      const SizedBox(height: 20),

                      // ── Section 2: Konum ─────────────────────────────────
                      const _SectionLabel(text: 'Konum'),
                      const SizedBox(height: 8),
                      _BlockyField(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedDistrict,
                          style: GoogleFonts.nunitoSans(
                              fontSize: 14, color: Colors.black),
                          dropdownColor: Colors.white,
                          decoration: _fieldDecoration(
                            hintText: _isBakici
                                ? 'Hizmet verdiğiniz ilçeyi seçin'
                                : 'Eskişehir ilçesini seçin',
                            prefixIcon: Icons.map_rounded,
                          ),
                          items: _districts
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d,
                                        style: GoogleFonts.nunitoSans(
                                            fontSize: 14,
                                            color: Colors.black)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedDistrict = v),
                          validator: (v) =>
                              v == null ? 'İlçe seçimi zorunludur' : null,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Section 3: Topluluk ──────────────────────────────
                      const _SectionLabel(text: 'Topluluk'),
                      const SizedBox(height: 8),
                      _BlockyField(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _selectedGroupId,
                          style: GoogleFonts.nunitoSans(
                              fontSize: 14, color: Colors.black),
                          dropdownColor: Colors.white,
                          decoration: _fieldDecoration(
                            hintText: 'Genel (isteğe bağlı)',
                            prefixIcon: Icons.forum_rounded,
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Genel',
                                  style: GoogleFonts.nunitoSans(
                                      fontSize: 14,
                                      color: Colors.black)),
                            ),
                            ...vm.chatGroups.map((g) => DropdownMenuItem<String?>(
                                  value: g.id,
                                  child: Text(g.name,
                                      style: GoogleFonts.nunitoSans(
                                          fontSize: 14,
                                          color: Colors.black)),
                                )),
                          ],
                          onChanged: (v) => setState(() => _selectedGroupId = v),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Section 4: Acil Durum (Kayıp only) ───────────────
                      if (_isKayip) ...[
                        const _SectionLabel(text: 'Acil Durum'),
                        const SizedBox(height: 8),
                        _BlockyField(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Acil olarak işaretle',
                                        style: GoogleFonts.nunitoSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Yeni kaybolmuş veya risk altındaki '
                                        'hayvanlar için kullanın.',
                                        style: GoogleFonts.nunitoSans(
                                          fontSize: 11,
                                          color: Colors.black
                                              .withValues(alpha: 0.55),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isUrgent,
                                  onChanged: (v) =>
                                      setState(() => _isUrgent = v),
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: EspatiColors.red,
                                  trackOutlineColor:
                                      WidgetStateProperty.all(Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Section 5: Açıklama ──────────────────────────────
                      const _SectionLabel(text: 'Açıklama'),
                      const SizedBox(height: 8),
                      _BlockyField(
                        child: TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 5,
                          maxLength: _maxDescLength,
                          style: GoogleFonts.nunitoSans(
                              fontSize: 14, color: Colors.black),
                          decoration: _fieldDecoration(
                            hintText: _descriptionHint,
                            alignLabelTop: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Açıklama zorunludur';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Section 6: Fotoğraflar ───────────────────────────
                      const _SectionLabel(text: 'Fotoğraflar'),
                      const SizedBox(height: 4),
                      Text(
                        'En az 1, en fazla $_maxImages fotoğraf ekleyin.',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ImagePickerSection(
                        images: _images,
                        hasError: _imageError,
                        maxImages: _maxImages,
                        onGallery: _pickFromGallery,
                        onCamera: _pickFromCamera,
                        onRemove: _removeImage,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // ── Submit bar ─────────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _SubmitBar(
                label: _submitLabel,
                accentColor: _accentColor,
                isSubmitting: vm.isSubmitting,
                onSubmit: _submit,
              ),
            ),
          ],
        );
      },
    );
  }

  String get _descriptionHint {
    switch (widget.type) {
      case ListingStatus.sahiplendirme:
        return 'Hayvanın karakterini, bakım gereksinimlerini ve ideal yuvasını anlatın...';
      case ListingStatus.kayip:
        return 'Kaybolduğu yer, zaman, fiziksel özellikler ve son görülme koşullarını anlatın...';
      case ListingStatus.bakici:
        return 'Deneyiminizi, çalışma saatlerinizi ve hizmet detaylarınızı anlatın...';
    }
  }

  // ── Field groups ──────────────────────────────────────────────────────────

  List<Widget> _buildAnimalFields() {
    return [
      _BlockyField(
        child: TextFormField(
          controller: _nameCtrl,
          style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
          decoration: _fieldDecoration(
            hintText: 'İsim (Örn: Rocky, Mimi)',
            prefixIcon: Icons.badge_rounded,
          ),
          validator: _requiredValidator('İsim'),
        ),
      ),
      const SizedBox(height: 10),
      _BlockyField(
        child: DropdownButtonFormField<String>(
          initialValue: _selectedSpecies,
          style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
          dropdownColor: Colors.white,
          decoration: _fieldDecoration(
              hintText: 'Hayvan türünü seçin', prefixIcon: Icons.category_rounded),
          items: _species
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: GoogleFonts.nunitoSans(
                            fontSize: 14, color: Colors.black)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedSpecies = v),
          validator: (v) => v == null ? 'Tür seçimi zorunludur' : null,
        ),
      ),
      const SizedBox(height: 10),
      _BlockyField(
        child: TextFormField(
          controller: _breedCtrl,
          style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
          decoration: _fieldDecoration(
            hintText: 'Irk / Cins (Örn: Golden Retriever, Tekir)',
            prefixIcon: Icons.info_outline_rounded,
          ),
          validator: _requiredValidator('Irk/Cins'),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _BlockyField(
              child: TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.nunitoSans(
                    fontSize: 14, color: Colors.black),
                decoration:
                    _fieldDecoration(hintText: 'Yaş', prefixIcon: Icons.cake_rounded),
                validator: _requiredValidator('Yaş'),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: _BlockyField(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                style: GoogleFonts.nunitoSans(
                    fontSize: 14, color: Colors.black),
                dropdownColor: Colors.white,
                decoration:
                    _fieldDecoration(hintText: 'Cinsiyet', prefixIcon: Icons.wc_rounded),
                items: _genders
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g,
                              style: GoogleFonts.nunitoSans(
                                  fontSize: 14, color: Colors.black)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedGender = v),
                validator: (v) => v == null ? 'Cinsiyet zorunludur' : null,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildBakiciFields() {
    return [
      _BlockyField(
        child: TextFormField(
          controller: _nameCtrl,
          style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
          decoration: _fieldDecoration(
            hintText: 'İlan Başlığı (Örn: Deneyimli Köpek Bakıcısı)',
            prefixIcon: Icons.badge_rounded,
          ),
          validator: _requiredValidator('İlan başlığı'),
        ),
      ),
      const SizedBox(height: 10),
      _BlockyField(
        child: DropdownButtonFormField<String>(
          initialValue: _selectedSpecies,
          style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
          dropdownColor: Colors.white,
          decoration: _fieldDecoration(
              hintText: 'Baktığınız türü seçin', prefixIcon: Icons.category_rounded),
          items: [..._species, _allSpecies]
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: GoogleFonts.nunitoSans(
                            fontSize: 14, color: Colors.black)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedSpecies = v),
          validator: (v) => v == null ? 'Tür seçimi zorunludur' : null,
        ),
      ),
      const SizedBox(height: 10),
      _BlockyField(
        child: TextFormField(
          controller: _priceCtrl,
          style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
          decoration: _fieldDecoration(
            hintText: 'Fiyat Bilgisi (Örn: 150₺/gün, saatlik 50₺)',
            prefixIcon: Icons.sell_rounded,
          ),
          validator: _requiredValidator('Fiyat bilgisi'),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        'Verdiğiniz Hizmetler',
        style: GoogleFonts.nunitoSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black.withValues(alpha: 0.85),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _serviceTypeOptions
            .map((s) => _ServiceChip(
                  label: s,
                  isSelected: _selectedServiceTypes.contains(s),
                  onTap: () => _toggleServiceType(s),
                ))
            .toList(),
      ),
      if (_serviceTypeError) ...[
        const SizedBox(height: 6),
        Text(
          'En az bir hizmet seçmeniz zorunludur',
          style: GoogleFonts.nunitoSans(fontSize: 12, color: EspatiColors.red),
        ),
      ],
    ];
  }

  // ── Shared field decoration ──────────────────────────────────────────────

  InputDecoration _fieldDecoration({
    String? hintText,
    IconData? prefixIcon,
    bool alignLabelTop = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.nunitoSans(
          fontSize: 13.5, color: Colors.black.withValues(alpha: 0.4)),
      prefixIcon: prefixIcon == null
          ? null
          : Padding(
              padding: alignLabelTop ? const EdgeInsets.only(bottom: 88) : EdgeInsets.zero,
              child: Icon(prefixIcon, size: 19, color: Colors.black.withValues(alpha: 0.55)),
            ),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      counterStyle: GoogleFonts.nunitoSans(
          fontSize: 11, color: Colors.black.withValues(alpha: 0.45)),
      errorStyle: GoogleFonts.nunitoSans(fontSize: 11, color: EspatiColors.red),
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

/// Custom app bar — sharp close block (left) + Fredoka title, thick black
/// bottom border on the [NeoBrutal.scaffoldBg] canvas. Same convention as
/// [AiVetScreen]'s own app bar / [GuideDetailScreen]'s back button.
class _ListingFormAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const _ListingFormAppBar({required this.title});

  static const double _height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: const BoxDecoration(
        color: NeoBrutal.scaffoldBg,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: NeoBrutal.borderWidth),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              NeoBrutalistButton(
                semanticLabel: 'Kapat',
                onPressed: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(2.5),
                    boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.black, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White/black-bordered/hard-shadow frame around a plain (border-less,
/// unfilled) input — every field on this screen reads as one consistent
/// Neo-Brutalist block, matching [NeoBrutal] tokens used everywhere else.
class _BlockyField extends StatelessWidget {
  final Widget child;

  const _BlockyField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2),
        boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
      ),
      child: child,
    );
  }
}

/// Coloured banner at the top of the form indicating listing type — blocky
/// icon tile + title/subtitle, using [ListingStatus.accentColor]/[icon].
class _TypeBanner extends StatelessWidget {
  final ListingStatus type;

  const _TypeBanner({required this.type});

  String get _subtitle {
    switch (type) {
      case ListingStatus.sahiplendirme:
        return 'Evcil hayvanınıza sıcak bir yuva bulun';
      case ListingStatus.kayip:
        return 'Kayıp hayvanınızı bildirin veya bulduğunuzu paylaşın';
      case ListingStatus.bakici:
        return 'Evcil hayvan sahiplerine bakıcılık hizmeti sunun';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: type.accentColor,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2.5),
        boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.zero,
              border: NeoBrutal.border(2),
            ),
            child: Icon(type.icon, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.title,
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.75),
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

/// Section label sitting directly on the [NeoBrutal.scaffoldBg] canvas.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunitoSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black.withValues(alpha: 0.85),
      ),
    );
  }
}

/// One tappable service-type chip for Bakıcı listings — filled with the
/// screen's accent color when selected, same border/shadow language as
/// every other block on this screen.
class _ServiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? EspatiColors.lightBlue : Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(isSelected ? 2.5 : 2),
          boxShadow:
              isSelected ? NeoBrutal.shadow(const Offset(2, 2)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.black),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.nunitoSans(
                fontSize: 12.5,
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

/// Blocky add-photo buttons + horizontal thumbnail strip.
class _ImagePickerSection extends StatelessWidget {
  final List<XFile> images;
  final bool hasError;
  final int maxImages;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final ValueChanged<int> onRemove;

  const _ImagePickerSection({
    required this.images,
    required this.hasError,
    required this.maxImages,
    required this.onGallery,
    required this.onCamera,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _PickerButton(
              icon: Icons.photo_library_rounded,
              label: 'Galeri',
              onTap: onGallery,
            ),
            const SizedBox(width: 10),
            _PickerButton(
              icon: Icons.camera_alt_rounded,
              label: 'Kamera',
              onTap: onCamera,
            ),
            const Spacer(),
            Text(
              '${images.length}/$maxImages',
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                color: images.isEmpty && hasError
                    ? EspatiColors.red
                    : Colors.black.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        if (hasError && images.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'En az 1 fotoğraf eklemeniz zorunludur',
            style: GoogleFonts.nunitoSans(fontSize: 12, color: EspatiColors.red),
          ),
        ],

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

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      semanticLabel: label,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
          boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.nunitoSans(
                fontSize: 12.5,
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
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(xFile.path), fit: BoxFit.cover),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                  border: NeoBrutal.border(1.5),
                ),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky, blocky submit button bar pinned to the bottom of the screen —
/// filled with the listing type's accent color.
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
    return Container(
      decoration: const BoxDecoration(
        color: NeoBrutal.scaffoldBg,
        border: Border(
          top: BorderSide(color: Colors.black, width: NeoBrutal.borderWidth),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      child: NeoBrutalistButton(
        semanticLabel: label,
        onPressed: isSubmitting ? null : onSubmit,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSubmitting ? accentColor.withValues(alpha: 0.5) : accentColor,
            borderRadius: BorderRadius.zero,
            border: NeoBrutal.border(3),
            boxShadow: isSubmitting ? null : NeoBrutal.shadow(const Offset(4, 4)),
          ),
          child: isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'İlan yayınlanıyor…',
                      style: GoogleFonts.baloo2(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black),
                    ),
                  ],
                )
              : Text(
                  label.toUpperCase(),
                  style: GoogleFonts.baloo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
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
