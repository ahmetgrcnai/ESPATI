import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/chat_room_model.dart';
import '../../data/repositories/interfaces/i_chat_repository.dart';
import '../../viewmodels/chat_thread_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/request_chat_tile.dart';
import '../chat/chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE REQUESTS SCREEN ("Gelen İstekler") — Design System Step 70/71.
//
// Real data as of Step 71: [ChatViewModel.pendingRequests] — rooms someone
// else started ([ChatRoomModel.initiatorId]) that the current user hasn't
// accepted yet ([ChatRoomModel.acceptedByRecipient]). A cold DM from search
// lands here; a listing-inquiry message skips straight to the main inbox
// (see feed_detail_screen.dart / new_chat_search_screen.dart's autoAccept
// argument). Accept opens the real chat thread; Decline deletes the room.
// ─────────────────────────────────────────────────────────────────────────────

class MessageRequestsScreen extends StatelessWidget {
  const MessageRequestsScreen({super.key});

  Future<void> _accept(
      BuildContext context, ChatRoomModel room, String myUid) async {
    final chatVm = context.read<ChatViewModel>();
    final chatRepo = context.read<IChatRepository>();
    final accepted = await chatVm.acceptRequest(room.roomId);
    if (!context.mounted) return;
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İstek kabul edilemedi. Lütfen tekrar deneyin.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ChatThreadViewModel>(
          create: (_) => ChatThreadViewModel(
            chatRepository: chatRepo,
            roomId: room.roomId,
            currentUserId: myUid,
          ),
          child: ChatScreen(
            chatTitle: room.otherParticipantName(myUid),
            otherUserPhoto: room.otherParticipantPhoto(myUid),
          ),
        ),
      ),
    );
  }

  void _decline(BuildContext context, ChatRoomModel room) {
    context.read<ChatViewModel>().declineRequest(room.roomId);
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
          'Gelen İstekler',
          style: GoogleFonts.baloo2(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: Colors.black,
          ),
        ),
      ),
      body: Consumer<ChatViewModel>(
        builder: (context, chatVm, _) {
          final requests = chatVm.pendingRequests;
          final myUid = chatVm.currentUserId;
          if (requests.isEmpty) return const _EmptyRequests();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final room = requests[index];
              return RequestChatTile(
                avatarUrl: room.otherParticipantPhoto(myUid),
                username: room.otherParticipantName(myUid),
                messageSnippet: room.lastMessage.isEmpty
                    ? 'Sohbete başlamak istiyor'
                    : room.lastMessage,
                onAccept: () => _accept(context, room, myUid),
                onDecline: () => _decline(context, room),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mail_lock_rounded,
              size: 64, color: Colors.black),
          const SizedBox(height: 12),
          Text(
            'Bekleyen istek yok',
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
