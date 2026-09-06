import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/pet_model.dart';
import '../../viewmodels/form_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/common/espati_button.dart';
import '../../widgets/common/espati_card.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/common/profile_ads_list.dart';
import '../../widgets/common/profile_posts_grid.dart';
import '../../widgets/pet_action_bottom_sheet.dart';
import '../../widgets/pet_card.dart';
import '../inbox/inbox_screen.dart';
import '../feed_detail_screen.dart';
import 'add_edit_pet_screen.dart';
import 'edit_profile_screen.dart';
import 'pati_takvimi_widget.dart';
import 'reminder_manager_screen.dart';
import 'settings_screen.dart';

/// Profile screen — user header, stats, my pets scrollable list,
/// post grid, and settings bottom sheet with dark mode toggle.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Step 64 — 0 = Patilerim (pets), 1 = Gönderilerim (posts), 2 = Benim
  /// İlanlarım (listings). Was a 2-way toggle with the Pet Calendar
  /// rendered unconditionally below it regardless of which tab was
  /// selected ("bleeding into other tabs"); the bottom section is now a
  /// single per-tab switch (see [_buildTabContent]) so exactly one
  /// section's content — never more — exists in the tree at a time.
  int _selectedTabIndex = 0;

  /// Clears MainScreen's floating [EspatiBottomNavBar] overlay (same
  /// formula as `_PoiMapScreenState._infoCardBottomClearance`) — the bar
  /// sits on top of every tab's content in a [Stack], not reserved
  /// Scaffold layout space, so without this the last scrolled-to content
  /// (Pati Takvimi's reminder cards) renders directly underneath it and
  /// reads as "cut off" even once the scroll view has hit its max extent.
  static const double _bottomNavClearance = EspatiBottomNavBar.height + 24 + 16;

  @override
  void initState() {
    super.initState();
    // Listen for upload errors and show a SnackBar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().addListener(_onViewModelChanged);
      // Step 64 — "Benim İlanlarım" moved from a separate pushed
      // MyListingsScreen (which owned this listener itself) into an inline
      // tab here, so ProfileScreen now needs FormViewModel's delete-error
      // signal directly.
      context.read<FormViewModel>().addListener(_onFormViewModelChanged);
    });
  }

  @override
  void dispose() {
    context.read<ProfileViewModel>().removeListener(_onViewModelChanged);
    context.read<FormViewModel>().removeListener(_onFormViewModelChanged);
    super.dispose();
  }

  /// Formats large counts: 1200 → "1.2B" style (K for thousands).
  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  void _onViewModelChanged() {
    final vm = context.read<ProfileViewModel>();
    if (vm.uploadError != null) {
      _showErrorSnackBar(vm.uploadError!);
      vm.clearUploadError();
    }
    if (vm.petError != null) {
      _showErrorSnackBar(vm.petError!);
      vm.clearPetError();
    }
  }

  void _onFormViewModelChanged() {
    final vm = context.read<FormViewModel>();
    if (vm.deleteListingError != null) {
      _showErrorSnackBar(vm.deleteListingError!);
      vm.clearDeleteListingError();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EspatiColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openPetForm(BuildContext context, {PetModel? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditPetScreen(existingPet: existing),
      ),
    );
  }

  /// Long-press action sheet: Edit or Delete. `backgroundColor: transparent`
  /// lets [PetActionBottomSheet] draw its own blocky bordered container
  /// instead of showing through the sheet's default Material surface.
  void _showPetActions(BuildContext context, ProfileViewModel vm, PetModel pet) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PetActionBottomSheet(
        petName: pet.name,
        onEdit: () => _openPetForm(context, existing: pet),
        onDelete: () => _confirmDeletePet(context, vm, pet),
      ),
    );
  }

  void _confirmDeletePet(
      BuildContext context, ProfileViewModel vm, PetModel pet) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${pet.name} silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              vm.deletePet(pet.id);
            },
            child: Text('Sil', style: TextStyle(color: EspatiColors.red)),
          ),
        ],
      ),
    );
  }

  /// Delete confirmation for a listing — mirrors [_confirmDeletePet]'s
  /// dialog exactly (same file, same shape/style) rather than the more
  /// elaborate Neo-Brutalist dialog `MyListingsScreen` used to have; this
  /// screen keeps both destructive-action dialogs looking identical to
  /// each other.
  void _confirmDeleteListing(
      BuildContext context, FormViewModel vm, ListingModel listing) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('"${listing.name}" ilanı silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              vm.deleteListing(listing.id);
            },
            child: Text('Sil', style: TextStyle(color: EspatiColors.red)),
          ),
        ],
      ),
    );
  }

  /// Step 64 — the single dispatch point for the tab-dependent bottom
  /// section. A `switch` on [_selectedTabIndex] rather than an `if/else`
  /// chain that happened to also let the Pet Calendar slip in unconditionally
  /// afterward (the exact bug this step fixes) — each case is a fully
  /// self-contained section, so there's no shared trailing widget any case
  /// can "bleed" into.
  Widget _buildTabContent(
    BuildContext context,
    ProfileViewModel vm,
    FormViewModel formVm,
    Color textColor,
  ) {
    return switch (_selectedTabIndex) {
      0 => _buildPatilerimSection(context, vm, textColor),
      1 => _buildGonderilerimSection(context, vm, textColor),
      2 => _buildIlanlarimSection(context, vm, formVm, textColor),
      _ => const SizedBox.shrink(),
    };
  }

  /// Case 0 — pets carousel AND the Pet Calendar. The calendar belongs
  /// here only: it's schedule data *about* the user's pets, not a
  /// general-purpose profile fixture.
  Widget _buildPatilerimSection(
      BuildContext context, ProfileViewModel vm, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.pets_rounded, size: 20, color: EspatiColors.peach),
              const SizedBox(width: 8),
              Text(
                'Patilerim',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
              const Spacer(),
              // Step 50 — harmonized with the active tab's mintGreen (was a
              // bare lightBlue TextButton, disconnected from the rest of
              // the Neo-Brutalist palette), and wrapped in NeoBrutalistButton
              // (Step 44) for the same tactile scale/spring every other
              // block button gets.
              NeoBrutalistButton(
                onPressed:
                    vm.isUserLoading ? null : () => _openPetForm(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: EspatiColors.mintGreen,
                    borderRadius: BorderRadius.zero,
                    border:
                        Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 16, color: Colors.black),
                      const SizedBox(width: 4),
                      Text('Pati Ekle',
                          style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (vm.isPetsLoading)
          _PetsShimmer()
        else if (vm.pets.isEmpty)
          _PetsEmptyState(onAdd: () => _openPetForm(context))
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: EspatiCard(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                height: 156,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  itemCount: vm.pets.length,
                  itemBuilder: (context, index) {
                    final pet = vm.pets[index];
                    return PetCard(
                      name: pet.name,
                      breed:
                          pet.breed.isNotEmpty ? pet.breed : pet.petType.name,
                      imageUrl: pet.photoUrl,
                      age: pet.age > 0 ? '${pet.age} yaş' : '',
                      onLongPress: () => _showPetActions(context, vm, pet),
                    );
                  },
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),

        // ── Pati Takvimi (Pet Schedule) ── Neo-Brutalist timeline (Design
        // System Step 40) — real ProfileViewModel.reminders, not the old
        // rounded-card preview. Only ever built here, tab 0 — Step 64
        // fixes it being built unconditionally regardless of tab.
        PatiTakvimiWidget(
          reminders: vm.reminders,
          isLoading: vm.isLoading,
          onComplete: vm.completeReminder,
          onAdd: vm.addReminder,
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ReminderManagerScreen(),
            ),
          ),
        ),
      ],
    );
  }

  /// Case 1 — posts grid ONLY. No calendar.
  Widget _buildGonderilerimSection(
      BuildContext context, ProfileViewModel vm, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.grid_on_rounded, size: 20, color: EspatiColors.lightBlue),
              const SizedBox(width: 8),
              Text(
                'Gönderilerim',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (vm.isPostsLoading)
          _PostsShimmer()
        else if (vm.posts.isEmpty)
          _PostsEmptyState()
        else
          // Step 61 — Neo-Brutalist 2-column gallery grid. shrinkWrap +
          // NeverScrollableScrollPhysics: this grid lives inside the outer
          // SingleChildScrollView's Column, so without them it would try
          // to take unbounded height and collapse/disappear.
          ProfilePostsGrid(
            imageUrls: vm.posts.map((p) => p.imageUrl).toList(),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onTapItem: (index) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FeedDetailScreen.post(vm.posts[index]),
              ),
            ),
          ),
      ],
    );
  }

  /// Case 2 — listings list ONLY. No calendar. Was a separate pushed
  /// MyListingsScreen; folded in here as the toggle's third segment
  /// (Step 64) so a user's listings render in exactly one place.
  Widget _buildIlanlarimSection(BuildContext context, ProfileViewModel vm,
      FormViewModel formVm, Color textColor) {
    final mine = formVm.listingsByAuthor(vm.user.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.campaign_rounded, size: 20, color: EspatiColors.peach),
              const SizedBox(width: 8),
              Text(
                'Benim İlanlarım',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (formVm.isListingsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: EspatiColors.sageGreen),
            ),
          )
        else if (mine.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: EspatiCard(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                children: [
                  const Icon(Icons.campaign_rounded,
                      size: 36, color: Colors.black),
                  const SizedBox(height: 8),
                  Text(
                    'Henüz bir ilanınız yok',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Step 62 — horizontal AdListCard (image left, critical text
          // right: status/title/date-location). shrinkWrap +
          // NeverScrollableScrollPhysics for the same nested-scrollable
          // reason as ProfilePostsGrid above.
          ProfileAdsList(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mine.length,
            itemBuilder: (context, i) {
              final listing = mine[i];
              final isDeleting = formVm.isDeletingListing;

              return Stack(
                children: [
                  AdListCard(
                    imageUrl: listing.imageUrl,
                    title: listing.name,
                    subtitle: '${listing.date} • ${listing.location}',
                    statusLabel: listing.status.label.toUpperCase() +
                        (listing.isUrgent ? ' · ACİL' : ''),
                    statusColor: listing.status.accentColor,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => FeedDetailScreen.listing(listing)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        border:
                            Border.all(color: Colors.black, width: 2),
                      ),
                      child: isDeleting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: EspatiColors.red),
                              onPressed: () =>
                                  _confirmDeleteListing(context, formVm, listing),
                              tooltip: 'Sil',
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Step 56 — the screen now sits on a light EspatiColors.cream canvas
    // (was the dark-brown scaffold), matching EditProfileScreen/
    // SettingsScreen so the app stops "context switching" between a dark
    // profile and light sub-pages. Header text is darkBrown accordingly —
    // was cream, which needed to be light-on-dark; now it needs to be
    // dark-on-light, same direction colorScheme.onSurface already points,
    // but pinned to the literal EspatiColors token per the design system's
    // "no theme-derived colors" rule rather than reused from theme.
    const textColor = Colors.black;

    return Consumer<ProfileViewModel>(
      builder: (context, vm, _) =>
          _buildScaffold(context, vm, theme, isDark, textColor),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    ProfileViewModel vm,
    ThemeData theme,
    bool isDark,
    Color textColor,
  ) {
    final user = vm.user;
    // Step 64 — needed inline now that "Benim İlanlarım" is a tab here
    // rather than a separate pushed MyListingsScreen (which used to own
    // this watch itself).
    final formVm = context.watch<FormViewModel>();

    return Scaffold(
      // Off-white Neo-Brutalist canvas, matching EditProfileScreen/SettingsScreen.
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          user.name.isNotEmpty ? user.name : (user.email.isNotEmpty ? user.email.split('@').first : 'Profil'),
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: textColor,
          ),
        ),
        actions: [
          // Step 56 — both action badges are now pop-out Neo-Brutalist
          // bricks (BorderRadius.zero, thick darkBrown border, hard offset
          // shadow) instead of a bare rounded-outline IconButton, and use
          // NeoBrutalistButton for the same tactile press every other block
          // button in the app gets rather than Material's ripple.
          NeoBrutalistButton(
            semanticLabel: 'Mesajlar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InboxScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: EspatiColors.peach,
                borderRadius: BorderRadius.zero,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.mail_outline_rounded,
                  color: Colors.black, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          NeoBrutalistButton(
            semanticLabel: 'Ayarlar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: EspatiColors.mintGreen,
                borderRadius: BorderRadius.zero,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.settings_rounded,
                  color: Colors.black, size: 20),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: vm.isUserLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar — tappable, shows upload spinner overlay. Step
                  // 56: square Neo-Brutalist block (thick darkBrown border +
                  // hard offset shadow), matching EditProfileScreen's avatar
                  // language — was a soft circular gradient ring with no
                  // border/shadow at all, the exact "doesn't pop against a
                  // light canvas" problem this step exists to fix.
                  GestureDetector(
                    onTap: vm.isUploading
                        ? null // block taps while uploading
                        : () => vm.pickAndUploadProfileImage(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            color: EspatiColors.peach,
                            borderRadius: BorderRadius.zero,
                            border: Border.fromBorderSide(
                              BorderSide(
                                  color: Colors.black, width: 3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(4, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: user.profilePicture.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: user.profilePicture,
                                  // imageVersion busts the cache after each
                                  // successful upload so the new photo loads
                                  // immediately.
                                  cacheKey:
                                      '${user.profilePicture}_v${vm.imageVersion}',
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Icon(
                                      Icons.pets_rounded,
                                      size: 36,
                                      color: Colors.black),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.pets_rounded,
                                          size: 36,
                                          color: Colors.black),
                                )
                              : const Icon(Icons.pets_rounded,
                                  size: 36, color: Colors.black),
                        ),

                        // Upload spinner overlay
                        if (vm.isUploading)
                          Container(
                            width: 84,
                            height: 84,
                            color: Colors.black45,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        // Camera icon badge (shown when not uploading)
                        else
                          Positioned(
                            bottom: -3,
                            right: -3,
                            child: Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: EspatiColors.mintGreen,
                                borderRadius: BorderRadius.zero,
                                border: Border.fromBorderSide(
                                  BorderSide(
                                      color: Colors.black,
                                      width: 2),
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.black,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Stats
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatColumn(
                          value: _formatCount(vm.posts.length),
                          label: 'Gönderi',
                          textColor: textColor,
                        ),
                        _StatColumn(
                          value: _formatCount(user.followersCount),
                          label: 'Takipçi',
                          textColor: textColor,
                        ),
                        _StatColumn(
                          value: _formatCount(user.followingCount),
                          label: 'Takip',
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Name & Bio ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : user.email,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      color: textColor,
                    ),
                  ),
                  // Step 55 — username is now a real, persisted field
                  // (EditProfileScreen), so it needs somewhere to actually
                  // render; this Consumer-driven build already re-runs the
                  // instant ProfileViewModel.updateUserProfile resolves.
                  if (user.username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  if (user.locationDistrict.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: EspatiColors.lightBlue),
                        const SizedBox(width: 4),
                        Text(
                          user.locationDistrict,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: EspatiColors.lightBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Action Buttons (neo-brutalist) ──
            // Step 56: local zero-radius bricks, not the shared
            // [EspatiButton] (which rounds its corners at 12px) — this
            // step's spec calls for BorderRadius.zero specifically on these
            // two, and EspatiButton is also used by AddEditPetScreen, which
            // is out of this step's scope to restyle.
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _ProfileHeaderButton(
                      label: 'Profili Düzenle',
                      icon: Icons.edit_rounded,
                      backgroundColor: EspatiColors.mintGreen,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileHeaderButton(
                      label: 'Profili Paylaş',
                      icon: Icons.share_rounded,
                      backgroundColor: EspatiColors.peach,
                      // Same no-op as before this restyle — share wasn't
                      // wired up previously either; only the container changed.
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            // ── Patilerim / Gönderilerim / Benim İlanlarım Toggle ──
            // Step 64 — "Benim İlanlarım" used to be a separate banner
            // above this toggle that pushed a whole other screen
            // (MyListingsScreen) showing the same data; it's now the
            // toggle's third segment instead, so there's exactly one place
            // in the app that renders a user's listings, not two.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ProfileSectionToggle(
                selectedIndex: _selectedTabIndex,
                onChanged: (i) => setState(() => _selectedTabIndex = i),
              ),
            ),
            const SizedBox(height: 16),

            // Step 64 — strict per-tab switch: exactly one of these three
            // sections is ever in the tree, never the Pet Calendar
            // alongside Gönderilerim/Benim İlanlarım's content.
            _buildTabContent(context, vm, formVm, textColor),

            // Was a bare 24px — nowhere near enough to clear the floating
            // bottom nav bar, so the calendar's last reminder card(s) sat
            // underneath it even when scrolled all the way down.
            const SizedBox(height: _bottomNavClearance),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PETS SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class _PetsShimmer extends StatelessWidget {
  const _PetsShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PETS EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _PetsEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _PetsEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: EspatiCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.pets_rounded,
                size: 40, color: Colors.black),
            const SizedBox(height: 10),
            Text(
              'Henüz pati yok!',
              style: GoogleFonts.fredoka(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'İlk dostunu tanıtmak için aşağıya dokun',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            EspatiButton(
              label: 'Pati Ekle',
              icon: Icons.pets_rounded,
              backgroundColor: EspatiColors.mintGreen,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PATİLERİM / GÖNDERİLERİM / BENİM İLANLARIM TOGGLE
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSectionToggle extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ProfileSectionToggle({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Step 52 — no outer padding/background and no gap between segments
    // left to show through (Step 50's 4px cream padding + 4px SizedBox gap
    // was exactly the "white gap" the user flagged). The segments sit
    // flush, each carrying its own full-bleed border/fill, so together they
    // read as one seamless Neo-Brutalist brick with zero bleed-through.
    // Step 64 — a third segment (Benim İlanlarım, was its own banner above
    // this toggle that pushed a separate screen) joined the other two.
    return Row(
      children: [
        Expanded(
          child: _SegmentButton(
            label: 'Patilerim',
            icon: Icons.pets_rounded,
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
        ),
        Expanded(
          child: _SegmentButton(
            label: 'Gönderilerim',
            icon: Icons.grid_on_rounded,
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ),
        Expanded(
          child: _SegmentButton(
            label: 'İlanlarım',
            icon: Icons.campaign_rounded,
            selected: selectedIndex == 2,
            onTap: () => onChanged(2),
          ),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Step 52 — uniform 2px border on both states (was 2.5/1) so the two
    // segments butt together as one evenly-bordered brick instead of a
    // mismatched seam; active/inactive is carried entirely by the solid
    // sageGreen-vs-cream fill (Step 57 — was mintGreen, see Step 56.5's
    // palette swap), never by a gap or a lighter border.
    final contentColor = Colors.black
        .withValues(alpha: selected ? 1 : 0.55);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? NeoBrutal.activeAccent : Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: contentColor),
            const SizedBox(width: 6),
            // Step 64 — maxLines/ellipsis added: three segments now share
            // this row instead of two, so each gets ~1/3 the width.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: contentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POSTS SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class _PostsShimmer extends StatelessWidget {
  const _PostsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 9,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POSTS EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _PostsEmptyState extends StatelessWidget {
  const _PostsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: EspatiCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.grid_on_rounded,
                size: 36, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              'Henüz bir gönderi paylaşmadınız.',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sosyal akışta ilk gönderini paylaş',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE HEADER BUTTON — "Profili Düzenle" / "Profili Paylaş" (Step 56).
// Zero-radius Neo-Brutalist brick, scoped to this screen's header rather
// than the shared EspatiButton (which rounds its corners) — see the call
// site's comment.
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeaderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _ProfileHeaderButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.black, width: 2.5),
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
            Icon(icon, size: 17, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
