import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/neo_brutalist_tokens.dart';
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
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing App Bar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: NeoBrutal.scaffoldBg,
            leading: const _BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderBanner(guide: guide),
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
                          size: 14, color: Colors.black.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        '${guide.readMinutes} dk okuma',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    guide.title,
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Summary
                  Text(
                    guide.summary,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Container(height: 3, color: Colors.black),
                  ),

                  // Markdown body
                  MarkdownBody(
                    data: guide.contentMarkdown,
                    selectable: true,
                    styleSheet: _buildStyleSheet(),
                    checkboxBuilder: (checked) =>
                        _NeoChecklistBox(checked: checked, accent: guide.accentColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet() {
    final body = GoogleFonts.poppins(fontSize: 15, color: Colors.black, height: 1.6);
    final h1 = GoogleFonts.fredoka(
        fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black, height: 1.4);
    final h2 = GoogleFonts.fredoka(
        fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black, height: 1.4);
    final h3 = GoogleFonts.fredoka(
        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black, height: 1.4);

    return MarkdownStyleSheet(
      p: body,
      h1: h1,
      h2: h2,
      h3: h3,
      strong: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.black),
      em: GoogleFonts.poppins(
          fontStyle: FontStyle.italic, color: Colors.black.withValues(alpha: 0.85)),
      listBullet: body,
      blockquoteDecoration: BoxDecoration(
        color: guide.accentColor.withValues(alpha: 0.25),
        border: const Border(
          left: BorderSide(color: Colors.black, width: NeoBrutal.borderWidth),
        ),
      ),
      blockquote: GoogleFonts.poppins(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.black.withValues(alpha: 0.8)),
      blockquotePadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tableHead: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black),
      tableBody: GoogleFonts.poppins(fontSize: 13, color: Colors.black),
      tableBorder: TableBorder.all(color: Colors.black, width: 1.5),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      codeblockDecoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      code: GoogleFonts.sourceCodePro(fontSize: 13, color: Colors.black),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black, width: 2)),
      ),
    );
  }
}

// ── Header Banner — full-strength guide accent, sharp bottom border ────────

class _HeaderBanner extends StatelessWidget {
  final AcademyGuideModel guide;

  const _HeaderBanner({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: guide.accentColor,
        border: const Border(
          bottom: BorderSide(color: Colors.black, width: NeoBrutal.borderWidth),
        ),
      ),
      child: Center(
        child: Icon(guide.icon, size: 72, color: Colors.black),
      ),
    );
  }
}

// ── Back Button — sharp square, thick border, hard shadow ──────────────────

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: NeoBrutal.border(2),
            boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.black, size: 20),
        ),
      ),
    );
  }
}

// ── Checklist Box — Neo-Brutalist task-list checkbox, replaces flutter_
// markdown_plus's default rounded Material Icons.check_box glyph (which
// ignores this screen's design tokens entirely — sharp corners, thick
// black border, no default Material color).
// ─────────────────────────────────────────────────────────────────────────

class _NeoChecklistBox extends StatelessWidget {
  final bool checked;
  final Color accent;

  const _NeoChecklistBox({required this.checked, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: checked ? accent : Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: checked
            ? const Icon(Icons.check_rounded, size: 15, color: Colors.black)
            : null,
      ),
    );
  }
}

// ── Category Chip — rectangular, guide-accent fill, black border ───────────

class _CategoryChip extends StatelessWidget {
  final AcademyGuideModel guide;

  const _CategoryChip({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: guide.accentColor,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Text(
        guide.categoryLabel,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }
}
