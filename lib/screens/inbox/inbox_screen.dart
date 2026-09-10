import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/chat_room_model.dart';
import '../../data/repositories/interfaces/i_chat_repository.dart';
import '../../data/repositories/interfaces/i_user_repository.dart';
import '../../viewmodels/chat_thread_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/common/neo_brutalist_search_bar.dart';
import '../../widgets/inbox_chat_tile.dart';
import '../../widgets/message_requests_banner.dart';
import '../chat/chat_screen.dart';
import 'message_requests_screen.dart';
import 'new_chat_search_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INBOX SCREEN — 1-on-1 Mesajlar, Neo-Brutalist rebuild (Design System
// Step 67). Real, Firestore-backed messaging via [ChatViewModel] — unchanged
// from the previous version; only the presentation layer changed here.
//
// Reachable via the Messages icon on the Discover feed's AppBar (Step 66)
// and ProfileScreen's app bar, since Mesajlar is the app's sole PII-safe
// communication channel (Step 1) and has no bottom-nav tab of its own.
//
// Unread state: [ChatRoomModel.unreadCounts] exists and round-trips through
// Firestore (Step 67), but nothing increments/resets it yet — see that
// field's doc comment. Every room reads as read until that backend piece
// lands; this screen's unread styling is real and ready for it.
// ─────────────────────────────────────────────────────────────────────────────

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatRoomModel> _filtered(List<ChatRoomModel> rooms, String myUid) {
    if (_query.trim().isEmpty) return rooms;
    final q = _query.trim().toLowerCase();
    return rooms
        .where((r) => r.otherParticipantName(myUid).toLowerCase().contains(q))
        .toList();
  }

  static String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inHours < 1) return '${diff.inMinutes}dk';
    if (diff.inDays < 1) return '${diff.inHours}sa';
    if (diff.inDays < 7) return '${diff.inDays}g';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBrutalistButton(
              semanticLabel: 'Geri',
              onPressed: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
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
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.black, size: 20),
              ),
            ),
          ),
        ),
        title: Text(
          'Mesajlar',
          style: GoogleFonts.baloo2(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: NeoBrutalistSearchBar(
              controller: _searchController,
              hintText: 'Sohbetlerde ara...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Step 70 — "Gelen İstekler" banner, just below the search bar.
          // requestCount is a mock value: ChatRoomModel/IChatRepository have
          // no pending/known-sender concept yet, see
          // message_requests_screen.dart's file header for the real gap.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: MessageRequestsBanner(
              requestCount: 3,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const MessageRequestsScreen()),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ChatViewModel>(
              builder: (context, chatVm, _) {
                if (chatVm.isLoading && chatVm.chatRooms.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: EspatiColors.sageGreen),
                  );
                }
                if (chatVm.chatRooms.isEmpty) {
                  return const _EmptyInbox();
                }

                final rooms = _filtered(chatVm.chatRooms, chatVm.currentUserId);
                if (rooms.isEmpty) {
                  return _NoSearchResults(query: _query);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final unreadCount =
                        room.unreadCountFor(chatVm.currentUserId);
                    return InboxChatTile(
                      avatarUrl: room.otherParticipantPhoto(chatVm.currentUserId),
                      username: room.otherParticipantName(chatVm.currentUserId),
                      messageSnippet: room.lastMessage.isEmpty
                          ? 'Sohbete başla'
                          : room.lastMessage,
                      timeLabel: _timeLabel(room.lastUpdated),
                      isUnread: unreadCount > 0,
                      unreadCount: unreadCount,
                      onTap: () =>
                          _openChat(context, room, chatVm.currentUserId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Step 69 — massive blocky "new message" FAB. Opens NewChatSearchScreen,
      // a real Firestore-backed user search dedicated to starting a DM (not
      // the Follow-focused search/search_screen.dart reached from
      // CommunityHubScreen).
      floatingActionButton: NeoBrutalistButton(
        semanticLabel: 'Yeni Mesaj',
        onPressed: () => _openNewChatSearch(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Yeni',
                style: GoogleFonts.baloo2(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNewChatSearch(BuildContext context) {
    final userRepo = context.read<IUserRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<SearchViewModel>(
          create: (_) => SearchViewModel(userRepository: userRepo),
          child: const NewChatSearchScreen(),
        ),
      ),
    );
  }

  void _openChat(
      BuildContext context, ChatRoomModel room, String currentUserId) {
    final chatRepo = context.read<IChatRepository>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ChatThreadViewModel>(
          create: (_) => ChatThreadViewModel(
            chatRepository: chatRepo,
            roomId: room.roomId,
            currentUserId: currentUserId,
          ),
          child: ChatScreen(
            chatTitle: room.otherParticipantName(currentUserId),
            otherUserPhoto: room.otherParticipantPhoto(currentUserId),
          ),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined,
              size: 64, color: Colors.black),
          const SizedBox(height: 12),
          Text(
            'Henüz mesaj yok',
            style: GoogleFonts.nunitoSans(
              fontSize: 15,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  final String query;
  const _NoSearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 56, color: Colors.black),
          const SizedBox(height: 12),
          Text(
            '"$query" için sonuç bulunamadı',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
