import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/map_launcher_service.dart';
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/map_point.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../discovery/poi_map_screen.dart';
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
//   3. Veteriner  — [VeterinaryTabView]: real emergency-vet CTA (deep-links
//                    to [PoiMapScreen] pre-filtered to vets) + a live,
//                    distance-sorted-by-proximity vet clinic list off
//                    [MapViewModel]. Recovered from `health_education_hub_
//                    screen.dart` (Step 78's unwired "successor" hub, which
//                    duplicated this screen's own tab layout and was never
//                    actually adopted) — that file's static-Q&A placeholder
//                    tab is gone now that a real feature exists to show
//                    instead; the rest of that file (its own Academy tab
//                    rebuild, the never-wired [PatiAiScreen]) was dead code
//                    and has been removed rather than left stranded.
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
                VeterinaryTabView(),
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
                  style: GoogleFonts.baloo2(
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
    _TabSpec(label: 'Veteriner', icon: Icons.medical_services_rounded),
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
              style: GoogleFonts.nunitoSans(
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
// TAB 3 — VETERİNER: real emergency-vet CTA + a live, distance-annotated vet
// clinic list off [MapViewModel] — recovered from the dead
// `health_education_hub_screen.dart` (see file header). Not mocked: the same
// [MapViewModel.allPoints]/[MapViewModel.currentCenter] [PoiMapScreen] itself
// renders on the Harita tab.
// ─────────────────────────────────────────────────────────────────────────────

class VeterinaryTabView extends StatelessWidget {
  const VeterinaryTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, vm, _) {
        final vetPoints = vm.allPoints
            .where((p) => p.category == MapPointCategory.vet)
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          children: [
            _EmergencyVetButton(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PoiMapScreen(initialFilter: 'Veteriner'),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (vm.isLoading && vm.allPoints.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: EspatiColors.sageGreen),
                ),
              )
            else if (vetPoints.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Yakında veteriner kliniği bulunamadı',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
            else
              for (final point in vetPoints)
                VetClinicCard(
                  point: point,
                  distanceKm: Geolocator.distanceBetween(
                        vm.currentCenter.latitude,
                        vm.currentCenter.longitude,
                        point.latitude,
                        point.longitude,
                      ) /
                      1000,
                ),
          ],
        );
      },
    );
  }
}

/// Massive full-width CTA — hands off to [PoiMapScreen] pre-filtered to
/// vets, reusing the real Eskişehir vet-clinic map instead of duplicating
/// that data/UI here.
class _EmergencyVetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EmergencyVetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: EspatiColors.terracotta,
          borderRadius: BorderRadius.zero,
          border: Border.fromBorderSide(
            BorderSide(color: Colors.black, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: Offset(6, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          '🚨 Nöbetçi Veteriner Bul',
          textAlign: TextAlign.center,
          style: GoogleFonts.baloo2(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Thick-bordered clinic card: name + distance tag on the left, "Ara" /
/// "Yol Tarifi" blocky action buttons on the right.
class VetClinicCard extends StatelessWidget {
  final MapPoint point;
  final double distanceKm;

  const VetClinicCard({
    super.key,
    required this.point,
    required this.distanceKm,
  });

  void _call(BuildContext context) {
    // [MapPoint] has no phone field yet — an honest "not available" toast
    // beats fabricating a number nobody should actually dial.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Bu klinik için telefon numarası henüz eklenmedi.',
            style: GoogleFonts.nunitoSans(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Colors.white, width: 1.5),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ),
      );
  }

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
          Text(
            point.name,
            style: GoogleFonts.baloo2(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            point.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunitoSans(
              fontSize: 11.5,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: EspatiColors.sageGreen, width: 2),
            ),
            child: Text(
              '${distanceKm.toStringAsFixed(1)} km',
              style: GoogleFonts.nunitoSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ClinicActionButton(
                  label: 'Ara',
                  icon: Icons.call_rounded,
                  color: EspatiColors.sageGreen,
                  onTap: () => _call(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ClinicActionButton(
                  label: 'Yol Tarifi',
                  icon: Icons.navigation_rounded,
                  color: Colors.white,
                  onTap: () => MapLauncherService.launchGoogleMaps(
                      point.latitude, point.longitude, NavMode.driving),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClinicActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ClinicActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.black),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
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
