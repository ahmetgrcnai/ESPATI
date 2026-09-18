import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../core/result.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/interfaces/i_chat_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_thread_viewmodel.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';
import '../../widgets/common/neo_brutalist_search_bar.dart';
import '../../widgets/user_search_tile.dart';
import '../chat/chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEW CHAT SEARCH SCREEN (Design System Step 69) — global user search
// dedicated to starting a new DM, triggered by InboxScreen's FAB.
//
// Distinct from `search/search_screen.dart` (Instagram-style discovery with
// a Follow pill, reached from CommunityHubScreen's app bar) — that screen's
// job is "find someone to follow / view a profile", this one's job is
// "find someone to message right now". Different CTA, different intent;
// forking a new screen kept SearchScreen's real, working Follow-pill flow
// untouched rather than bolting a second unrelated action onto it.
//
// Reuses the same real, debounced, Firestore-backed [SearchViewModel] —
// created fresh per-route by the caller (InboxScreen), same factory
// pattern SearchScreen's own push call site already uses.
//
// "Mesaj At" reuses the exact real get-or-create-room flow
// [FeedDetailScreen] already proved out: [IChatRepository
// .getOrCreateChatRoom] then push [ChatScreen] inside a screen-scoped
// [ChatThreadViewModel] provider.
// ─────────────────────────────────────────────────────────────────────────────

class NewChatSearchScreen extends StatefulWidget {
  const NewChatSearchScreen({super.key});

  @override
  State<NewChatSearchScreen> createState() => _NewChatSearchScreenState();
}

class _NewChatSearchScreenState extends State<NewChatSearchScreen> {
  final _searchController = TextEditingController();
  bool _startingChat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchViewModel>().addListener(_onVMChanged);
    });
  }

  @override
  void dispose() {
    context.read<SearchViewModel>().removeListener(_onVMChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onVMChanged() {
    final vm = context.read<SearchViewModel>();
    if (vm.state == SearchState.error && vm.errorMessage != null) {
      _showToast(vm.errorMessage!);
      vm.clearError();
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.nunitoSans(fontSize: 13, color: Colors.white)),
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

  Future<void> _messageUser(UserModel user) async {
    if (_startingChat) return;

    final currentUser = context.read<AuthViewModel>().currentUser;
    if (currentUser == null) {
      _showToast('Mesaj göndermek için giriş yapmalısınız.');
      return;
    }

    setState(() => _startingChat = true);

    final chatRepo = context.read<IChatRepository>();
    final result = await chatRepo.getOrCreateChatRoom(
      currentUserId: currentUser.id,
      currentUserName:
          currentUser.name.isNotEmpty ? currentUser.name : currentUser.email,
      currentUserPhoto: currentUser.profilePicture,
      otherUserId: user.id,
      otherUserName: user.name.isNotEmpty ? user.name : 'Pati Dostu',
      otherUserPhoto: user.profilePicture,
      // Cold DM to a stranger found via search — goes to Gelen İstekler.
      autoAccept: false,
    );

    if (!mounted) return;
    setState(() => _startingChat = false);

    switch (result) {
      case Success(:final data):
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<ChatThreadViewModel>(
              create: (_) => ChatThreadViewModel(
                chatRepository: chatRepo,
                roomId: data.roomId,
                currentUserId: currentUser.id,
              ),
              child: ChatScreen(
                chatTitle: data.otherParticipantName(currentUser.id),
                otherUserPhoto: data.otherParticipantPhoto(currentUser.id),
              ),
            ),
          ),
        );
      case Failure(:final message):
        _showToast(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
              child: Row(
                children: [
                  NeoBrutalistButton(
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
                  const SizedBox(width: 12),
                  Text(
                    'Yeni Mesaj',
                    style: GoogleFonts.baloo2(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: NeoBrutalistSearchBar(
                controller: _searchController,
                hintText: 'Kullanıcı adı ara...',
                autofocus: true,
                large: true,
                onChanged: (v) =>
                    context.read<SearchViewModel>().onQueryChanged(v),
              ),
            ),
            Expanded(
              child: Consumer<SearchViewModel>(
                builder: (context, vm, _) => _body(context, vm),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, SearchViewModel vm) {
    switch (vm.state) {
      case SearchState.initial:
        return const _IdlePrompt();
      case SearchState.loading:
        return const Center(
          child: CircularProgressIndicator(color: EspatiColors.sageGreen),
        );
      case SearchState.success:
        final currentUid = context.read<AuthViewModel>().currentUser?.id;
        final results =
            vm.searchResults.where((u) => u.id != currentUid).toList();
        if (results.isEmpty) return _NoResults(query: vm.lastQuery);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final user = results[index];
            return UserSearchTile(
              avatarUrl: user.profilePicture,
              username: user.name.isNotEmpty ? user.name : user.email,
              onMessageTap: () => _messageUser(user),
            );
          },
        );
      case SearchState.empty:
        return _NoResults(query: vm.lastQuery);
      case SearchState.error:
        // Error already surfaced as a toast — fall back to idle.
        return const _IdlePrompt();
    }
  }
}

class _IdlePrompt extends StatelessWidget {
  const _IdlePrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.manage_search_rounded,
              size: 72, color: Colors.black),
          const SizedBox(height: 16),
          Text(
            'Kime mesaj atmak istiyorsun?',
            style: GoogleFonts.baloo2(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kullanıcı adı yazarak ara',
            style: GoogleFonts.nunitoSans(
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 64, color: Colors.black),
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
