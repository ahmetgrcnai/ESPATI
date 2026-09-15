import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/chat_group_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/form_viewmodel.dart';
import 'group_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CREATE GROUP SCREEN — "Grup Oluştur"
//
// Lets any signed-in user create a new Topluluk community group. Category
// is free text the creator types themselves ("Sohbet", "Eğitim İpuçları",
// ...) rather than a pick from the fixed [PetCategory] chips those belong
// to admin-seeded groups (e.g. "Kedi Sahipleri") — these are general
// discussion/forum groups, not another pet-type directory entry, so there's
// nothing to pick from a list. [FormViewModel.createGroup] auto-joins the
// creator as [GroupMemberRole.owner] in the same write (no separate
// membership step here), then the user is dropped straight into the new
// group's [GroupDetailScreen] — where, as owner, they can grant "Yönetici"
// (kick) rights to other members or remove anyone themselves
// ([GroupMembersScreen]).
//
// Reachable from two entry points: the Inbox "Yeni" FAB's action sheet and
// the Topluluk tab's app bar "+" icon.
// ─────────────────────────────────────────────────────────────────────────────

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _bannedWordsCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _coverImage;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    _bannedWordsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;
    setState(() => _coverImage = File(picked.path));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickCoverImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Kamerayla Çek'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickCoverImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    final me = context.read<AuthViewModel>().currentUser;
    final formVm = context.read<FormViewModel>();
    final group = await formVm.createGroup(
      name: _nameCtrl.text,
      description: _descriptionCtrl.text,
      petCategory: PetCategory.all,
      customCategory: _categoryCtrl.text,
      creatorName: (me == null || me.name.isEmpty) ? (me?.email ?? '') : me.name,
      creatorPhoto: me?.profilePicture ?? '',
      coverImage: _coverImage,
      bannedWords: _bannedWordsCtrl.text.split(','),
    );

    if (!mounted) return;

    if (group == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            formVm.createGroupError ?? 'Grup oluşturulamadı. Lütfen tekrar deneyin.',
            style: GoogleFonts.nunitoSans(fontSize: 13),
          ),
          backgroundColor: EspatiColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Grup Oluştur',
          style: GoogleFonts.baloo2(
            fontWeight: FontWeight.w600,
            fontSize: 19,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              const _SectionLabel(text: 'Kapak fotoğrafı (isteğe bağlı)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  height: 120,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                    ],
                    image: _coverImage != null
                        ? DecorationImage(image: FileImage(_coverImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _coverImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_rounded,
                                size: 32, color: Colors.black),
                            const SizedBox(height: 6),
                            Text(
                              'Kapak fotoğrafı ekle',
                              style: GoogleFonts.baloo2(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: GestureDetector(
                              onTap: () => setState(() => _coverImage = null),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black, width: 2),
                                ),
                                child: const Icon(Icons.close_rounded, size: 16),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              const _SectionLabel(text: 'Grup adı'),
              const SizedBox(height: 8),
              _BlockyField(
                child: TextFormField(
                  controller: _nameCtrl,
                  maxLength: 40,
                  style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Ör. Eskişehir Kedi Severler',
                    hintStyle: GoogleFonts.nunitoSans(
                        fontSize: 14, color: Colors.black.withValues(alpha: 0.4)),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: GoogleFonts.nunitoSans(
                        fontSize: 11, color: Colors.black.withValues(alpha: 0.55)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Grup adı boş olamaz.'
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              const _SectionLabel(text: 'Açıklama'),
              const SizedBox(height: 8),
              _BlockyField(
                child: TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  maxLength: 200,
                  style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Bu grup ne hakkında?',
                    hintStyle: GoogleFonts.nunitoSans(
                        fontSize: 14, color: Colors.black.withValues(alpha: 0.4)),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: GoogleFonts.nunitoSans(
                        fontSize: 11, color: Colors.black.withValues(alpha: 0.55)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Açıklama boş olamaz.'
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              const _SectionLabel(text: 'Kategori'),
              const SizedBox(height: 4),
              Text(
                'Grubun ne hakkında olduğunu tek kelimeyle özetle — kendi belirle, bir listeden seçmene gerek yok.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              _BlockyField(
                child: TextFormField(
                  controller: _categoryCtrl,
                  maxLength: 30,
                  style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Ör. Sohbet, Eğitim İpuçları, Kayıp İlanları',
                    hintStyle: GoogleFonts.nunitoSans(
                        fontSize: 14, color: Colors.black.withValues(alpha: 0.4)),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: GoogleFonts.nunitoSans(
                        fontSize: 11, color: Colors.black.withValues(alpha: 0.55)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Kategori boş olamaz.'
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              const _SectionLabel(text: 'Ek yasaklı kelimeler (isteğe bağlı)'),
              const SizedBox(height: 4),
              Text(
                'Uygulama genel filtresine ek olarak, bu grubuna özel engellemek istediğin kelimeler varsa virgülle ayırarak yaz.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              _BlockyField(
                child: TextFormField(
                  controller: _bannedWordsCtrl,
                  style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Ör. reklam, spam',
                    hintStyle: GoogleFonts.nunitoSans(
                        fontSize: 14, color: Colors.black.withValues(alpha: 0.4)),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        color: NeoBrutal.scaffoldBg,
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10 + MediaQuery.of(context).padding.bottom,
        ),
        child: GestureDetector(
          onTap: _submitting ? null : _submit,
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _submitting
                  ? EspatiColors.mintGreen.withValues(alpha: 0.4)
                  : EspatiColors.mintGreen,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: Colors.black, width: 3),
              boxShadow: _submitting
                  ? null
                  : const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    'GRUP OLUŞTUR',
                    style: GoogleFonts.baloo2(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

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
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: child,
    );
  }
}

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
