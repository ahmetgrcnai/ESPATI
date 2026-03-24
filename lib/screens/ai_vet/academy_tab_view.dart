import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../data/models/academy_guide_model.dart';
import '../../viewmodels/ai_vet_viewmodel.dart';
import 'guide_detail_screen.dart';

/// Pati Akademi tab — search bar, category chip strip, and guide card list.
///
/// Triggers [AIVetViewModel.loadGuides] on first build.
/// All filtering is handled inside the ViewModel; this widget is purely
/// declarative.
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
    return Consumer<AIVetViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            // ── Search Bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: vm.setAcademySearch,
                decoration: InputDecoration(
                  hintText: 'Rehber ara…',
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.primary, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            vm.setAcademySearch('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Category Chips ──────────────────────────────────────────────
            SizedBox(
              height: 36,
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

            const SizedBox(height: 12),

            // ── Guide List ──────────────────────────────────────────────────
            Expanded(
              child: _buildBody(context, vm),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AIVetViewModel vm) {
    if (vm.isLoadingGuides) {
      return const Center(child: CircularProgressIndicator());
    }

    final guides = vm.filteredGuides;

    if (guides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Rehber bulunamadı',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary.withValues(alpha: 0.6)),
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

// ── Category Chip ──────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

// ── Academy Card ───────────────────────────────────────────────────────────────

class _AcademyCard extends StatelessWidget {
  final AcademyGuideModel guide;
  final VoidCallback onTap;

  const _AcademyCard({required this.guide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: guide.accentColor
                    .withValues(alpha: isDark ? 0.25 : 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Icon(
                guide.icon,
                size: 36,
                color: guide.accentColor,
              ),
            ),

            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: guide.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        guide.categoryLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: guide.accentColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      guide.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      guide.summary,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 3),
                        Text(
                          '${guide.readMinutes} dk',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.4),
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
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
