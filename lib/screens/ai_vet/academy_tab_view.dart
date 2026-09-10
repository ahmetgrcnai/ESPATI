import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/academy_guide_model.dart';
import '../../viewmodels/ai_vet_viewmodel.dart';
import 'guide_detail_screen.dart';

/// Pati Akademi tab — search bar, category chip strip, and guide card list.
///
/// Triggers [AIVetViewModel.loadGuides] on first build.
/// All filtering is handled inside the ViewModel; this widget is purely
/// declarative. Visual restyle only — real guide data, search, and category
/// filtering below are unchanged.
class AcademyTabView extends StatefulWidget {
  const AcademyTabView({super.key});

  @override
  State<AcademyTabView> createState() => _AcademyTabViewState();
}

class _AcademyTabViewState extends State<AcademyTabView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Trigger load after the first frame so the Provider tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIVetViewModel>().loadGuides();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NeoBrutal.scaffoldBg,
      child: Consumer<AIVetViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              // ── Search Bar — thick border, hard shadow ────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(),
                    boxShadow: NeoBrutal.shadow(),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: vm.setAcademySearch,
                    style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Rehber ara…',
                      hintStyle: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: Colors.black, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: Colors.black, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                vm.setAcademySearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Category Chips ──────────────────────────────────────────────
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: AcademyCategory.all.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = AcademyCategory.all[index];
                    final isSelected = vm.selectedCategory == cat.id;
                    return _CategoryChip(
                      label: cat.label,
                      isSelected: isSelected,
                      onTap: () => vm.setAcademyCategory(cat.id),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // ── Guide List ──────────────────────────────────────────────────
              Expanded(
                child: _buildBody(context, vm),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AIVetViewModel vm) {
    if (vm.isLoadingGuides) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    final guides = vm.filteredGuides;

    if (guides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: Colors.black.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Rehber bulunamadı',
              style: GoogleFonts.nunitoSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: guides.length,
      itemBuilder: (context, index) => _AcademyCard(
        guide: guides[index],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GuideDetailScreen(guide: guides[index]),
          ),
        ),
      ),
    );
  }
}

// ── Category Chip — rectangular, thick border, mechanical press ────────────

class _CategoryChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool showFlat = _isPressed || !widget.isSelected;
    final Color fill =
        widget.isSelected ? NeoBrutal.activeAccent : Colors.white;
    final Color content =
        widget.isSelected ? Colors.black : Colors.black.withValues(alpha: 0.7);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          showFlat ? 2 : 0,
          showFlat ? 2 : 0,
          0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
          boxShadow: showFlat ? const [] : NeoBrutal.shadow(const Offset(2, 2)),
        ),
        child: Text(
          widget.label,
          style: GoogleFonts.nunitoSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: content,
          ),
        ),
      ),
    );
  }
}

// ── Academy Card — thick border, hard shadow, real per-guide accent ────────

class _AcademyCard extends StatelessWidget {
  final AcademyGuideModel guide;
  final VoidCallback onTap;

  const _AcademyCard({required this.guide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(),
          boxShadow: NeoBrutal.shadow(),
        ),
        child: Row(
          children: [
            // Icon block — full-strength guide accent color, sharp edge.
            // Fixed height (not stretch — this Row sits in a ListView item
            // with unbounded height, so stretch would force the Expanded
            // text column below into an infinite-height layout exception).
            Container(
              width: 84,
              height: 96,
              decoration: BoxDecoration(
                color: guide.accentColor,
                border: const Border(
                  right: BorderSide(
                      color: Colors.black, width: NeoBrutal.borderWidth),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(guide.icon, size: 34, color: Colors.black),
            ),

            // Text content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: guide.accentColor,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        guide.categoryLabel,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      guide.title,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      guide.summary,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: Colors.black.withValues(alpha: 0.45)),
                        const SizedBox(width: 3),
                        Text(
                          '${guide.readMinutes} dk',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 11,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
