import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/pet_model.dart';
import '../../data/repositories/interfaces/i_chat_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_thread_viewmodel.dart';
import '../../viewmodels/mating_viewmodel.dart';
import '../chat/chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MATING SWIPE SCREEN — "Çiftleşme" module, Phase 0/1.
//
// Opened from the heart icon on the Keşfet AppBar (left of the
// notification bell). Tinder-style deck: [PetCharacterTag]/health-declared
// pets only ([PetModel.isEligibleForMating]), right swipe = interested,
// left = pas geç. A mutual right-swipe creates a real match + drops both
// owners straight into the app's real chat system — see [MatingViewModel].
//
// Deliberately custom-built (no swipe-card package) — a plain
// GestureDetector + AnimatedContainer transform is enough for this
// gesture and avoids adding a new pubspec dependency for it.
// ─────────────────────────────────────────────────────────────────────────────

class MatingSwipeScreen extends StatefulWidget {
  const MatingSwipeScreen({super.key});

  @override
  State<MatingSwipeScreen> createState() => _MatingSwipeScreenState();
}

class _MatingSwipeScreenState extends State<MatingSwipeScreen> {
  MatingViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm == null) {
      _vm = context.read<MatingViewModel>();
      _vm!.addListener(_onVmChanged);
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    super.dispose();
  }

  void _onVmChanged() {
    final vm = _vm;
    if (vm == null || !mounted) return;
    final error = vm.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.nunitoSans(fontSize: 13)),
          backgroundColor: EspatiColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      vm.clearError();
    }
  }

  void _openMatchChat(MatingViewModel vm) {
    final match = vm.celebrationMatch;
    final owner = vm.matchedOwner;
    final pet = vm.matchedPet;
    if (match == null || match.chatRoomId.isEmpty) {
      vm.clearCelebration();
      return;
    }
    final myUid = context.read<AuthViewModel>().currentUser?.id ?? '';
    final chatRepo = context.read<IChatRepository>();
    vm.clearCelebration();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ChatThreadViewModel>(
          create: (_) => ChatThreadViewModel(
            chatRepository: chatRepo,
            roomId: match.chatRoomId,
            currentUserId: myUid,
          ),
          child: ChatScreen(
            chatTitle: (owner == null || owner.name.isEmpty)
                ? (pet?.name ?? 'Sohbet')
                : owner.name,
            otherUserPhoto: owner?.profilePicture ?? '',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatingViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: NeoBrutal.scaffoldBg,
          appBar: AppBar(
            backgroundColor: NeoBrutal.scaffoldBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_rounded, color: EspatiColors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Çiftleşme',
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              _buildBody(context, vm),
              if (vm.celebrationMatch != null)
                _MatchCelebration(
                  petName: vm.matchedPet?.name ?? '',
                  ownerName: (vm.matchedOwner == null || vm.matchedOwner!.name.isEmpty)
                      ? null
                      : vm.matchedOwner!.name,
                  petPhotoUrl: vm.matchedPet?.photoUrl ?? '',
                  onStartChat: () => _openMatchChat(vm),
                  onDismiss: vm.clearCelebration,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MatingViewModel vm) {
    if (vm.loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.2, color: EspatiColors.mintGreen),
      );
    }

    if (vm.mySwipingPet == null) {
      return _NoEligiblePetState(onClose: () => Navigator.of(context).pop());
    }

    final card = vm.currentCard;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            '${vm.mySwipingPet!.name} adına eşleşme arıyorsun',
            style: GoogleFonts.nunitoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ),
        Expanded(
          child: card == null
              ? _DeckEmptyState()
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: _SwipeCard(
                    key: ValueKey(card.id),
                    pet: card,
                    onSwipe: (liked) => vm.swipeCurrent(liked: liked),
                  ),
                ),
        ),
        if (card != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RoundActionButton(
                  icon: Icons.close_rounded,
                  color: Colors.white,
                  iconColor: Colors.black,
                  onTap: () => vm.swipeCurrent(liked: false),
                ),
                _RoundActionButton(
                  icon: Icons.favorite_rounded,
                  color: EspatiColors.red,
                  iconColor: Colors.white,
                  onTap: () => vm.swipeCurrent(liked: true),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SWIPE CARD — draggable, rotates/translates with the drag, snaps back with
// a short animation if released short of the threshold.
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeCard extends StatefulWidget {
  final PetModel pet;
  final ValueChanged<bool> onSwipe;

  const _SwipeCard({super.key, required this.pet, required this.onSwipe});

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> {
  static const double _threshold = 110;

  Offset _dragOffset = Offset.zero;
  bool _dragging = false;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragging = true;
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragOffset.dx > _threshold) {
      HapticFeedback.mediumImpact();
      widget.onSwipe(true);
    } else if (_dragOffset.dx < -_threshold) {
      HapticFeedback.mediumImpact();
      widget.onSwipe(false);
    }
    setState(() {
      _dragging = false;
      _dragOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final angle = (_dragOffset.dx / 300).clamp(-0.4, 0.4);
    final pet = widget.pet;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedContainer(
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translateByDouble(_dragOffset.dx, _dragOffset.dy, 0.0, 1.0)
          ..rotateZ(angle),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            pet.photoUrl.isEmpty
                ? Container(
                    color: NeoBrutal.inactiveFill,
                    child: const Icon(Icons.pets_rounded, size: 72, color: Colors.black),
                  )
                : CachedNetworkImage(
                    imageUrl: pet.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: NeoBrutal.inactiveFill),
                    errorWidget: (_, __, ___) => Container(
                      color: NeoBrutal.inactiveFill,
                      child: const Icon(Icons.pets_rounded, size: 72, color: Colors.black),
                    ),
                  ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pet.name}, ${pet.age}',
                      style: GoogleFonts.baloo2(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (pet.breed.isNotEmpty)
                      Text(
                        pet.breed,
                        style: GoogleFonts.nunitoSans(fontSize: 14, color: Colors.white70),
                      ),
                    if (pet.characterTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: pet.characterTags
                            .map((t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                  child: Text(
                                    t.label,
                                    style: GoogleFonts.nunitoSans(
                                        fontSize: 11, color: Colors.white),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    if (pet.bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        pet.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunitoSans(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Aşı doğrulaması rozeti — vaccination declaration + card are
            // exactly what let this pet be here at all; surfacing that
            // builds the trust Gemini's brief opened with.
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: EspatiColors.sageGreen,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 13, color: Colors.black),
                    const SizedBox(width: 4),
                    Text('Aşılı',
                        style: GoogleFonts.nunitoSans(
                            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black)),
                  ],
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
// ROUND ACTION BUTTON — ❌ / ❤️ under the deck.
// ─────────────────────────────────────────────────────────────────────────────

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _RoundActionButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY / EDGE STATES
// ─────────────────────────────────────────────────────────────────────────────

class _NoEligiblePetState extends StatelessWidget {
  final VoidCallback onClose;

  const _NoEligiblePetState({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border_rounded, size: 56, color: Colors.black),
            const SizedBox(height: 16),
            Text(
              'Eşleşme aramak için önce bir patini uygun hale getir.',
              textAlign: TextAlign.center,
              style: GoogleFonts.baloo2(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'Profilinden bir pati seç, düzenle ve "Eşleşme Arıyor" bölümünde '
              'aşı beyanı + karne fotoğrafını tamamla.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                  fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onClose,
              child: Text('Kapat',
                  style: GoogleFonts.baloo2(fontWeight: FontWeight.w600, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off_rounded, size: 56, color: Colors.black),
            const SizedBox(height: 16),
            Text(
              'Şu an gösterilecek başka pati yok.',
              textAlign: TextAlign.center,
              style: GoogleFonts.baloo2(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni patiler eşleşmeye açıldıkça burada görünecek.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                  fontSize: 13, color: Colors.black.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATCH CELEBRATION — full-screen overlay on a mutual match.
// ─────────────────────────────────────────────────────────────────────────────

class _MatchCelebration extends StatelessWidget {
  final String petName;
  final String? ownerName;
  final String petPhotoUrl;
  final VoidCallback onStartChat;
  final VoidCallback onDismiss;

  const _MatchCelebration({
    required this.petName,
    required this.ownerName,
    required this.petPhotoUrl,
    required this.onStartChat,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                'Eşleştiniz!',
                style: GoogleFonts.baloo2(
                    fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                ownerName == null
                    ? '$petName ile mutual bir eşleşme oldu.'
                    : '$petName ($ownerName) ile mutual bir eşleşme oldu.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunitoSans(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onStartChat,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: EspatiColors.mintGreen,
                    border: Border.all(color: Colors.black, width: 2.5),
                  ),
                  child: Text('Sohbete Başla',
                      style: GoogleFonts.baloo2(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onDismiss,
                child: Text('Kapat',
                    style: GoogleFonts.baloo2(fontWeight: FontWeight.w600, color: Colors.black54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
