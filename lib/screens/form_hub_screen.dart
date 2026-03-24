import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/models/listing_model.dart';
import '../data/models/chat_group_model.dart';
import '../data/models/direct_message_model.dart';
import '../viewmodels/form_viewmodel.dart';
import 'listing_form_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FORM HUB SCREEN
// Central interaction point: İlanlar (listings) + Mesajlar (inbox)
// ─────────────────────────────────────────────────────────────────────────────

class FormHubScreen extends StatefulWidget {
  const FormHubScreen({super.key});

  @override
  State<FormHubScreen> createState() => _FormHubScreenState();
}

class _FormHubScreenState extends State<FormHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Consumer<FormViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(context, theme, isDark, cs, vm),
          body: vm.isLoading && vm.chatGroups.isEmpty
              ? const _LoadingState()
              : vm.errorMessage != null
                  ? _ErrorState(
                      message: vm.errorMessage!,
                      onRetry: () => vm.loadAll(),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _ListingsTab(vm: vm, isDark: isDark, cs: cs),
                        _InboxTab(vm: vm, isDark: isDark, cs: cs),
                      ],
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateListingSheet(context),
            backgroundColor: AppColors.peach,
            foregroundColor: Colors.white,
            elevation: 4,
            tooltip: 'İlan Oluştur',
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        );
      },
    );
  }

  void _showCreateListingSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateListingSheet(
        onSahiplendirme: () {
          Navigator.pop(context);
          Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => const ListingFormScreen(
                type: ListingStatus.sahiplendirme,
              ),
            ),
          );
        },
        onKayip: () {
          Navigator.pop(context);
          Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => const ListingFormScreen(
                type: ListingStatus.kayip,
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    ColorScheme cs,
    FormViewModel vm,
  ) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 16,
      title: Row(
        children: [
          Icon(Icons.forum_rounded, color: AppColors.softTeal, size: 24),
          const SizedBox(width: 8),
          Text(
            'Forum',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: _appBarIcon(Icons.search_rounded, isDark, cs),
          onPressed: () {},
          tooltip: 'Ara',
        ),
        IconButton(
          icon: _appBarIcon(Icons.tune_rounded, isDark, cs),
          onPressed: () {},
          tooltip: 'Filtrele',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _buildTabBar(cs, isDark, vm),
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs, bool isDark, FormViewModel vm) {
    final inboxBadge = vm.totalInboxUnread;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surface
            : AppColors.peachLight.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.softTeal,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: cs.onSurface.withOpacity(0.55),
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: [
          const Tab(text: 'İlanlar'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Mesajlar'),
                if (inboxBadge > 0) ...[
                  const SizedBox(width: 6),
                  _Badge(count: inboxBadge),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBarIcon(IconData icon, bool isDark, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surface
            : AppColors.peachLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 19, color: cs.onSurface),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE LISTING BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CreateListingSheet extends StatelessWidget {
  final VoidCallback onSahiplendirme;
  final VoidCallback onKayip;

  const _CreateListingSheet({
    required this.onSahiplendirme,
    required this.onKayip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final sheetBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ──────────────────────────────────────────────────────────
          Text(
            'İlan Türü Seç',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          Text(
            'Oluşturmak istediğiniz ilan türünü seçin',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),

          // ── Sahiplendirme option ────────────────────────────────────────────
          _SheetOption(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFE65100),
            iconBg: const Color(0xFFE65100),
            title: 'Sahiplendirme İlanı',
            subtitle: 'Bir hayvanı sevgi dolu bir yuvaya kavuşturun',
            onTap: onSahiplendirme,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // ── Kayıp option ───────────────────────────────────────────────────
          _SheetOption(
            icon: Icons.search_rounded,
            iconColor: AppColors.error,
            iconBg: AppColors.error,
            title: 'Kayıp / Buluntu İlanı',
            subtitle: 'Kayıp hayvanınızı bulun veya bulduğunuzu bildirin',
            onTap: onKayip,
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          // ── Cancel ─────────────────────────────────────────────────────────
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurface.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Vazgeç',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _SheetOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardBg = isDark ? cs.surface : AppColors.peachLight.withOpacity(0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: iconColor.withOpacity(0.18),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // ── Icon container ──────────────────────────────────────────
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBg.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 14),

                // ── Text ────────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ── Chevron ─────────────────────────────────────────────────
                Icon(
                  Icons.chevron_right_rounded,
                  color: iconColor.withOpacity(0.6),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB A — İLANLAR (Listings)
// ─────────────────────────────────────────────────────────────────────────────

class _ListingsTab extends StatelessWidget {
  final FormViewModel vm;
  final bool isDark;
  final ColorScheme cs;

  const _ListingsTab({
    required this.vm,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final listings = vm.filteredListings;

    return Column(
      children: [
        // ── Search ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Kayıp veya sahiplendirme ara...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: cs.onSurface.withOpacity(0.38),
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),

        // ── Filter + counts ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _ListingFilter(
                  currentFilter: vm.listingFilter,
                  lostCount: vm.lostCount,
                  adoptionCount: vm.adoptionCount,
                  onChanged: vm.setListingFilter,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── List ───────────────────────────────────────────────────────────
        Expanded(
          child: listings.isEmpty
              ? _EmptyListings(filter: vm.listingFilter)
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: listings.length,
                  itemBuilder: (context, index) => _ListingCard(
                    item: listings[index],
                    isDark: isDark,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Listing filter widget ──────────────────────────────────────────────────

class _ListingFilter extends StatelessWidget {
  final String currentFilter;
  final int lostCount;
  final int adoptionCount;
  final ValueChanged<String> onChanged;

  const _ListingFilter({
    required this.currentFilter,
    required this.lostCount,
    required this.adoptionCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Tümü',
            count: lostCount + adoptionCount,
            isSelected: currentFilter == 'all',
            color: AppColors.softTeal,
            onTap: () => onChanged('all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Kayıp',
            count: lostCount,
            isSelected: currentFilter == 'kayip',
            color: AppColors.error,
            onTap: () => onChanged('kayip'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Sahiplendir',
            count: adoptionCount,
            isSelected: currentFilter == 'sahiplendirme',
            color: const Color(0xFFE65100),
            onTap: () => onChanged('sahiplendirme'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Listing card ──────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final ListingModel item;
  final bool isDark;

  const _ListingCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLost = item.status == ListingStatus.kayip;
    final statusColor = isLost ? AppColors.error : const Color(0xFFE65100);
    final statusIcon = isLost ? Icons.search_rounded : Icons.favorite_rounded;
    final cardColor = isDark
        ? Theme.of(context).colorScheme.surface
        : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo ────────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(18)),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 108,
              height: 134,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 108,
                height: 134,
                color: AppColors.peachLight,
                child: Icon(Icons.pets,
                    size: 36,
                    color: AppColors.peach.withOpacity(0.5)),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 108,
                height: 134,
                color: AppColors.peachLight,
                child: Icon(Icons.pets, size: 36, color: AppColors.peach),
              ),
            ),
          ),

          // ── Info ──────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  _StatusBadge(
                    label: item.status.label,
                    icon: statusIcon,
                    color: statusColor,
                  ),
                  const SizedBox(height: 6),

                  // Name + type
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    item.type,
                    style: TextStyle(
                      fontSize: 12,
                      color: (isDark ? Colors.white : AppColors.textPrimary)
                          .withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 13, color: AppColors.softTeal),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.softTeal,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Date + call button
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: (isDark ? Colors.white : AppColors.textPrimary)
                            .withOpacity(0.35),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.date,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              (isDark ? Colors.white : AppColors.textPrimary)
                                  .withOpacity(0.35),
                        ),
                      ),
                      const Spacer(),
                      _CallButton(contact: item.contact),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final String contact;
  const _CallButton({required this.contact});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aranıyor: $contact'),
            backgroundColor: AppColors.softTeal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.softTeal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.phone_rounded, size: 13, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Ara',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyListings extends StatelessWidget {
  final String filter;
  const _EmptyListings({required this.filter});

  @override
  Widget build(BuildContext context) {
    final label = filter == 'kayip'
        ? 'kayıp'
        : filter == 'sahiplendirme'
            ? 'sahiplendirme'
            : '';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64,
              color: AppColors.softTeal.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            label.isEmpty
                ? 'Henüz ilan yok'
                : 'Hiç $label ilanı bulunamadı',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB B — MESAJLAR (Inbox)
// ─────────────────────────────────────────────────────────────────────────────

class _InboxTab extends StatelessWidget {
  final FormViewModel vm;
  final bool isDark;
  final ColorScheme cs;

  const _InboxTab({
    required this.vm,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),

        // ── Sub-tab toggle ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _InboxToggle(
            currentView: vm.inboxView,
            groupUnread: vm.totalGroupUnread,
            dmUnread: vm.totalDmUnread,
            onChanged: vm.setInboxView,
            isDark: isDark,
            cs: cs,
          ),
        ),

        const SizedBox(height: 8),

        // ── Content ─────────────────────────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: vm.inboxView == InboxView.groups
                ? _GroupList(
                    key: const ValueKey('groups'),
                    groups: vm.chatGroups,
                    isDark: isDark,
                    onGroupTap: (id) => vm.markGroupRead(id),
                  )
                : _DmList(
                    key: const ValueKey('dms'),
                    dms: vm.directMessages,
                    isDark: isDark,
                    onDmTap: (id) => vm.markDmRead(id),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Sub-tab toggle ─────────────────────────────────────────────────────────────

class _InboxToggle extends StatelessWidget {
  final InboxView currentView;
  final int groupUnread;
  final int dmUnread;
  final ValueChanged<InboxView> onChanged;
  final bool isDark;
  final ColorScheme cs;

  const _InboxToggle({
    required this.currentView,
    required this.groupUnread,
    required this.dmUnread,
    required this.onChanged,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.surface
            : AppColors.peachLight.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleItem(
            label: 'Gruplar',
            icon: Icons.groups_rounded,
            badgeCount: groupUnread,
            isSelected: currentView == InboxView.groups,
            onTap: () => onChanged(InboxView.groups),
          ),
          _ToggleItem(
            label: 'Mesajlar',
            icon: Icons.chat_bubble_rounded,
            badgeCount: dmUnread,
            isSelected: currentView == InboxView.messages,
            onTap: () => onChanged(InboxView.messages),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final int badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.label,
    required this.icon,
    required this.badgeCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.softTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected ? Colors.white : Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[500],
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 6),
                _Badge(count: badgeCount),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Community groups list ─────────────────────────────────────────────────────

class _GroupList extends StatelessWidget {
  final List<ChatGroupModel> groups;
  final bool isDark;
  final ValueChanged<String> onGroupTap;

  const _GroupList({
    super.key,
    required this.groups,
    required this.isDark,
    required this.onGroupTap,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const _EmptyInbox(message: 'Henüz grup yok');
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: groups.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withOpacity(0.5),
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final group = groups[index];
        return _GroupTile(
          group: group,
          isDark: isDark,
          onTap: () => onGroupTap(group.id),
        );
      },
    );
  }
}

class _GroupTile extends StatelessWidget {
  final ChatGroupModel group;
  final bool isDark;
  final VoidCallback onTap;

  const _GroupTile({
    required this.group,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = group.petCategory;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // ── Colored group icon ──────────────────────────────────────
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: cat.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(cat.icon, color: cat.accentColor, size: 26),
            ),
            const SizedBox(width: 12),

            // ── Name + last message ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (group.isPinned) ...[
                        Icon(Icons.push_pin_rounded,
                            size: 12,
                            color: AppColors.softTeal),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          group.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    group.lastMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Time + unread badge ─────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  group.lastActivityLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: group.hasUnread
                        ? AppColors.softTeal
                        : textColor.withOpacity(0.38),
                    fontWeight: group.hasUnread
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                if (group.hasUnread)
                  _Badge(count: group.unreadCount)
                else
                  Row(
                    children: [
                      Icon(Icons.people_rounded,
                          size: 11,
                          color: textColor.withOpacity(0.3)),
                      const SizedBox(width: 3),
                      Text(
                        _formatCount(group.memberCount),
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return '$n';
  }
}

// ── Direct messages list ──────────────────────────────────────────────────────

class _DmList extends StatelessWidget {
  final List<DirectMessageModel> dms;
  final bool isDark;
  final ValueChanged<String> onDmTap;

  const _DmList({
    super.key,
    required this.dms,
    required this.isDark,
    required this.onDmTap,
  });

  @override
  Widget build(BuildContext context) {
    if (dms.isEmpty) {
      return const _EmptyInbox(message: 'Henüz mesaj yok');
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: dms.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withOpacity(0.5),
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final dm = dms[index];
        return _DmTile(
          dm: dm,
          isDark: isDark,
          onTap: () => onDmTap(dm.id),
        );
      },
    );
  }
}

class _DmTile extends StatelessWidget {
  final DirectMessageModel dm;
  final bool isDark;
  final VoidCallback onTap;

  const _DmTile({
    required this.dm,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // ── Avatar + online dot ─────────────────────────────────────
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.peachLight,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: dm.avatarUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Icon(Icons.person,
                          color: AppColors.peach, size: 26),
                      errorWidget: (_, __, ___) => Icon(Icons.person,
                          color: AppColors.peach, size: 26),
                    ),
                  ),
                ),
                if (dm.isOnline)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Name + message ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dm.displayName,
                          style: TextStyle(
                            fontWeight: dm.hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 14,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (dm.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified_rounded,
                            size: 14, color: AppColors.softTeal),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dm.lastMessage,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: dm.hasUnread
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: dm.hasUnread
                          ? textColor.withOpacity(0.75)
                          : textColor.withOpacity(0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Time + unread ───────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dm.timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: dm.hasUnread
                        ? AppColors.softTeal
                        : textColor.withOpacity(0.38),
                    fontWeight: dm.hasUnread
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                if (dm.hasUnread) _Badge(count: dm.unreadCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED UTILITY WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Circular unread count badge.
class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Centered empty state for the inbox.
class _EmptyInbox extends StatelessWidget {
  final String message;
  const _EmptyInbox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined,
              size: 64,
              color: AppColors.softTeal.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen loading indicator.
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: AppColors.softTeal),
    );
  }
}

/// Full-screen error state with retry.
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar Dene'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.softTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
