import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../data/models/listing_model.dart';
import '../../viewmodels/discovery_viewmodel.dart';
import '../feed_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DISCOVERY SCREEN — Listings search & filtering (Phase 2)
//
// State machine (driven by DiscoveryViewModel.state) — the same finite-state
// shape as SearchScreen (User Search), reused deliberately:
//   initial → _IdleSplash        (paw illustration + hint copy)
//   loading → centered spinner
//   success → _ResultsList       (ListingModel cards)
//   empty   → _NoResultsView
//   error   → snackbar + idle    (non-blocking, surfaces once)
//
// Architecture:
//   • DiscoveryViewModel is injected by the CALLER via a scoped
//     ChangeNotifierProvider (factory pattern — fresh instance per push,
//     auto-disposed on pop). See form_hub_screen.dart for the push call.
// ─────────────────────────────────────────────────────────────────────────────

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late final TextEditingController _ctrl;

  static const List<String> _species = [
    'Kedi', 'Köpek', 'Kuş', 'Tavşan',
    'Balık', 'Sürüngen', 'Kemirgen', 'Diğer',
  ];

  static const List<String> _districts = [
    'Odunpazarı', 'Tepebaşı', 'Sivrihisar', 'İnönü',
    'Alpu', 'Beylikova', 'Çifteler', 'Günyüzü',
    'Han', 'Mahmudiye', 'Mihalgazi', 'Mihalıççık',
    'Sarıcakaya', 'Seyitgazi',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryViewModel>().addListener(_onVMChanged);
    });
  }

  @override
  void dispose() {
    context.read<DiscoveryViewModel>().removeListener(_onVMChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onVMChanged() {
    final vm = context.read<DiscoveryViewModel>();
    if (vm.state == DiscoveryState.error && vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(vm.errorMessage!, style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      vm.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final bgColor = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFFFF5F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'İlan Ara',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Consumer<DiscoveryViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              // ── Keyword field ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _ctrl,
                  onChanged: (q) => vm.onKeywordChanged(q),
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'İsim, cins veya açıklama ara...',
                    hintStyle: GoogleFonts.poppins(fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: cs.onSurface.withValues(alpha: 0.4), size: 20),
                    suffixIcon: _ctrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 18),
                            onPressed: () {
                              _ctrl.clear();
                              vm.onKeywordChanged('');
                              setState(() {});
                            },
                          ),
                    filled: true,
                    fillColor: isDark ? cs.surface : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // ── Status chips ─────────────────────────────────────────────
              _FilterChipRow<ListingStatus?>(
                selected: vm.status,
                options: const [
                  (null, 'Tümü'),
                  (ListingStatus.kayip, 'Kayıp'),
                  (ListingStatus.sahiplendirme, 'Sahiplendirme'),
                  (ListingStatus.bakici, 'Bakıcı'),
                ],
                onSelected: vm.setStatus,
              ),
              const SizedBox(height: 8),

              // ── Species chips ────────────────────────────────────────────
              _FilterChipRow<String?>(
                selected: vm.species,
                options: [
                  (null, 'Tüm Türler'),
                  ..._species.map((s) => (s, s)),
                ],
                onSelected: vm.setSpecies,
              ),
              const SizedBox(height: 8),

              // ── District dropdown ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: vm.district,
                      hint: Text('İlçe seçin',
                          style: GoogleFonts.poppins(fontSize: 13)),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      borderRadius: BorderRadius.circular(14),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tüm İlçeler',
                              style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                        ..._districts.map((d) => DropdownMenuItem<String?>(
                              value: d,
                              child:
                                  Text(d, style: GoogleFonts.poppins(fontSize: 13)),
                            )),
                      ],
                      onChanged: vm.setDistrict,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),

              // ── Results ───────────────────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _body(vm),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _body(DiscoveryViewModel vm) {
    switch (vm.state) {
      case DiscoveryState.initial:
        return const _IdleSplash(key: ValueKey('idle'));
      case DiscoveryState.loading:
        return const Center(
          key: ValueKey('loading'),
          child: CircularProgressIndicator(color: AppColors.softTeal),
        );
      case DiscoveryState.success:
        return _ResultsList(key: const ValueKey('results'), results: vm.results);
      case DiscoveryState.empty:
        return const _NoResultsView(key: ValueKey('empty'));
      case DiscoveryState.error:
        // Error was already surfaced as a snackbar; fall back to idle.
        return const _IdleSplash(key: ValueKey('idle-err'));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER CHIP ROW — generic horizontal ChoiceChip strip
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChipRow<T> extends StatelessWidget {
  final T selected;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;

  const _FilterChipRow({
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (value, label) = options[i];
          final isSelected = value == selected;
          return ChoiceChip(
            label: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.softTeal)),
            selected: isSelected,
            onSelected: (_) => onSelected(value),
            selectedColor: AppColors.softTeal,
            backgroundColor: AppColors.softTeal.withValues(alpha: 0.10),
            showCheckmark: false,
            side: BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULTS LIST
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final List<ListingModel> results;
  const _ResultsList({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey('discovery_results'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, i) => _DiscoveryCard(item: results[i]),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  final ListingModel item;
  const _DiscoveryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = item.status.accentColor;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FeedDetailScreen.listing(item)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 76,
                  height: 76,
                  color: AppColors.peachLight,
                  child: Icon(Icons.pets, color: AppColors.peach.withValues(alpha: 0.5)),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 76,
                  height: 76,
                  color: AppColors.peachLight,
                  child: Icon(Icons.pets, color: AppColors.peach),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.status.label,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                  const SizedBox(height: 2),
                  Text(item.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.textPrimary)),
                  Text(item.type,
                      style: TextStyle(
                          fontSize: 12,
                          color: (isDark ? Colors.white : AppColors.textPrimary)
                              .withValues(alpha: 0.5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: AppColors.softTeal),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(item.location,
                            style: TextStyle(fontSize: 11, color: AppColors.softTeal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IDLE / EMPTY STATES
// ─────────────────────────────────────────────────────────────────────────────

class _IdleSplash extends StatelessWidget {
  const _IdleSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.travel_explore_rounded,
              size: 72, color: AppColors.peach.withValues(alpha: 0.45)),
          const SizedBox(height: 16),
          Text('İlan Keşfet',
              style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.55))),
          const SizedBox(height: 6),
          Text(
            'Bir anahtar kelime yazın veya yukarıdaki\nfiltrelerden birini seçin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 13, color: textColor.withValues(alpha: 0.35), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: textColor.withValues(alpha: 0.22)),
          const SizedBox(height: 16),
          Text('Sonuç bulunamadı',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: textColor.withValues(alpha: 0.5))),
          const SizedBox(height: 6),
          Text('Filtreleri değiştirmeyi deneyin.',
              style: GoogleFonts.poppins(fontSize: 13, color: textColor.withValues(alpha: 0.32))),
        ],
      ),
    );
  }
}
