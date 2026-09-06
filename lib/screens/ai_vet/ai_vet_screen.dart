import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/sample_data.dart';
import 'academy_tab_view.dart';
import 'pati_ai_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN — 3-tab scaffold, Neo-Brutalist chrome
//
//   1. Pati-AI    — [PatiAiChatBody], the same restyled chat body used by
//                    the standalone [PatiAiScreen] route — single source of
//                    truth, no duplicate chat implementation here anymore.
//   2. Akademi    — [AcademyTabView], searchable guide library (unchanged
//                    for now — visual restyle is a separate step).
//   3. Veteriner  — [_AskVetTab], static community Q&A listing (unchanged
//                    for now — visual restyle is a separate step).
//
// The tab bar itself is a custom Neo-Brutalist row ([_NeoTabRow]) instead
// of Flutter's Material [TabBar] — still driven by a real [TabController]
// so swipe-to-switch on [TabBarView] keeps working.
// ─────────────────────────────────────────────────────────────────────────────

class AiVetScreen extends StatefulWidget {
  const AiVetScreen({super.key});

  @override
  State<AiVetScreen> createState() => _AiVetScreenState();
}

class _AiVetScreenState extends State<AiVetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Track the interactive swipe drag, not just settled taps — mirrors how
    // Flutter's own TabBar syncs its indicator to TabBarView: `.index` only
    // updates once a swipe settles on a page, but `.animation` tracks the
    // drag continuously, so the tab row was lagging a full swipe behind.
    _tabController.animation!.addListener(_handleTabAnimation);
  }

  void _handleTabAnimation() {
    final newIndex = _tabController.animation!.value.round().clamp(0, 2);
    if (newIndex != _activeIndex) {
      setState(() => _activeIndex = newIndex);
    }
  }

  @override
  void dispose() {
    _tabController.animation?.removeListener(_handleTabAnimation);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: const _AiVetAppBar(),
      body: Column(
        children: [
          _NeoTabRow(
            activeIndex: _activeIndex,
            onSelect: (index) => _tabController.animateTo(index),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              // Tap-only tab switching — kaydırarak (swipe) sekme değişimi
              // kapalı, [_NeoTabRow] üzerinden dokunarak geçiş yapılıyor.
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                PatiAiChatBody(),
                AcademyTabView(),
                _AskVetTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR — off-white background, thick black bottom border, sharp square
// avatar. Same visual language as [PatiAiScreen]'s own app bar.
// ─────────────────────────────────────────────────────────────────────────────

class _AiVetAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AiVetAppBar();

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
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: EspatiColors.peach,
                  borderRadius: BorderRadius.zero,
                  border: NeoBrutal.border(2.5),
                  boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
                ),
                child: const Icon(Icons.pets_rounded,
                    color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pati-AI & Akademi',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const _CloseButton(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLOSE BUTTON — top-right, sharp square block, thick border, hard shadow.
// Pops this pushed route back to whichever main tab was active underneath
// (MainScreen), mirroring [guide_detail_screen.dart]'s [_BackButton].
// ─────────────────────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
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
        child: const Icon(Icons.close_rounded, color: Colors.black, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM NEO TAB ROW — replaces the Material TabBar. Active tab: violet
// fill + hard shadow. Inactive: grayscale + flat. Every tap plays a
// mechanical press (shadow collapses, block translates down) regardless of
// active state, then calls [onSelect] which drives the real TabController.
// ─────────────────────────────────────────────────────────────────────────────

class _TabSpec {
  final String label;
  final IconData icon;
  const _TabSpec({required this.label, required this.icon});
}

class _NeoTabRow extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const _NeoTabRow({required this.activeIndex, required this.onSelect});

  static const List<_TabSpec> _tabs = [
    _TabSpec(label: 'Pati AI', icon: Icons.smart_toy_rounded),
    _TabSpec(label: 'Akademi', icon: Icons.menu_book_rounded),
    _TabSpec(label: 'Veterinere Sor', icon: Icons.medical_services_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NeoBrutal.scaffoldBg,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++) ...[
            if (i != 0) const SizedBox(width: 8),
            Expanded(
              child: _NeoTabItem(
                spec: _tabs[i],
                isActive: activeIndex == i,
                onTap: () => onSelect(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NeoTabItem extends StatefulWidget {
  final _TabSpec spec;
  final bool isActive;
  final VoidCallback onTap;

  const _NeoTabItem({
    required this.spec,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NeoTabItem> createState() => _NeoTabItemState();
}

class _NeoTabItemState extends State<_NeoTabItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool showFlat = _isPressed || !widget.isActive;
    final Color fill =
        widget.isActive ? NeoBrutal.activeAccent : NeoBrutal.inactiveFill;
    final Color content =
        widget.isActive ? Colors.black : NeoBrutal.inactiveContent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          showFlat ? 4 : 0,
          showFlat ? 4 : 0,
          0,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(),
          boxShadow: showFlat ? const [] : NeoBrutal.shadow(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.spec.icon, size: 18, color: content),
            const SizedBox(height: 4),
            Text(
              widget.spec.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — VETERİNER SORU-CEVAP (unchanged — visual restyle is a later step)
// ─────────────────────────────────────────────────────────────────────────────

class _AskVetTab extends StatelessWidget {
  const _AskVetTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── CTA banner — solid peach block, thick border, hard shadow ────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Veterinere soru sor — yakında geliyor!',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                backgroundColor: EspatiColors.lightBlue,
                behavior: SnackBarBehavior.floating,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Colors.black, width: 2),
                ),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EspatiColors.peach,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(),
                boxShadow: NeoBrutal.shadow(),
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
                    child: const Icon(Icons.medical_services_rounded,
                        color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Veterinere Sor',
                          style: GoogleFonts.fredoka(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Patiliniz için uzman görüşü alın',
                          style: GoogleFonts.poppins(
                            color: Colors.black.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.black, size: 18),
                ],
              ),
            ),
          ),
        ),

        // ── Section header ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Son Sorular',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Tümünü Gör',
                  style: GoogleFonts.poppins(
                      color: Colors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        // ── Q&A list ──────────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: SampleData.vetQuestions.length,
            itemBuilder: (context, index) {
              final q = SampleData.vetQuestions[index];
              return _VetQuestionCard(
                category: q['category'] as String,
                question: q['question'] as String,
                answersCount: q['answers'] as int,
                author: q['author'] as String,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VetQuestionCard extends StatelessWidget {
  final String category;
  final String question;
  final int answersCount;
  final String author;

  const _VetQuestionCard({
    required this.category,
    required this.question,
    required this.answersCount,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2),
        boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EspatiColors.peach,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.question_answer_rounded,
                  size: 14, color: Colors.black),
              const SizedBox(width: 4),
              Text(
                '$answersCount yanıt',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$author tarafından',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
