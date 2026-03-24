import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/app_colors.dart';
import '../../data/models/academy_guide_model.dart';

/// Full-screen guide reader.
///
/// Receives a fully-hydrated [AcademyGuideModel] so there is no async work
/// needed — the content is rendered immediately by [flutter_markdown].
class GuideDetailScreen extends StatelessWidget {
  final AcademyGuideModel guide;

  const GuideDetailScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing App Bar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: _BackButton(cs: cs, isDark: isDark),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderBanner(guide: guide, isDark: isDark),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta row: category chip + read time
                  Row(
                    children: [
                      _CategoryChip(guide: guide),
                      const Spacer(),
                      Icon(Icons.schedule_rounded,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        '${guide.readMinutes} dk okuma',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    guide.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Summary
                  Text(
                    guide.summary,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: theme.dividerColor),
                  ),

                  // Markdown body
                  MarkdownBody(
                    data: guide.contentMarkdown,
                    selectable: true,
                    styleSheet: _buildStyleSheet(theme, cs, isDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(
      ThemeData theme, ColorScheme cs, bool isDark) {
    final body = TextStyle(
        fontSize: 15, color: cs.onSurface, height: 1.6);
    final h1 = TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
        height: 1.4);
    final h2 = TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
        height: 1.4);
    final h3 = TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
        height: 1.4);

    return MarkdownStyleSheet(
      p: body,
      h1: h1,
      h2: h2,
      h3: h3,
      strong: TextStyle(
          fontWeight: FontWeight.w700, color: cs.onSurface),
      em: TextStyle(
          fontStyle: FontStyle.italic,
          color: cs.onSurface.withValues(alpha: 0.85)),
      listBullet: body,
      blockquoteDecoration: BoxDecoration(
        color: AppColors.peachLight.withValues(alpha: isDark ? 0.15 : 0.5),
        border: Border(
          left: BorderSide(color: AppColors.peach, width: 4),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      blockquote: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: cs.onSurface.withValues(alpha: 0.8)),
      blockquotePadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tableHead: TextStyle(
          fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurface),
      tableBody: TextStyle(fontSize: 13, color: cs.onSurface),
      tableBorder: TableBorder.all(
          color: theme.dividerColor, borderRadius: BorderRadius.circular(4)),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      codeblockDecoration: BoxDecoration(
        color: isDark ? cs.surface : AppColors.peachLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: AppColors.primaryDark),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
    );
  }
}

// ── Header Banner ──────────────────────────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  final AcademyGuideModel guide;
  final bool isDark;

  const _HeaderBanner({required this.guide, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            guide.accentColor.withValues(alpha: isDark ? 0.6 : 0.85),
            guide.accentColor.withValues(alpha: isDark ? 0.3 : 0.5),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          guide.icon,
          size: 72,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

// ── Back Button ────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;

  const _BackButton({required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? cs.surface.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_rounded, color: cs.onSurface, size: 20),
        ),
      ),
    );
  }
}

// ── Category Chip ──────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final AcademyGuideModel guide;

  const _CategoryChip({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: guide.accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: guide.accentColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        guide.categoryLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: guide.accentColor,
        ),
      ),
    );
  }
}
