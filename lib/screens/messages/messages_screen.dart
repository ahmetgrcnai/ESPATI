import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/sample_data.dart';
import '../../widgets/chat_tile.dart';
import 'chat_detail_screen.dart';

/// Messages screen — list of conversations with search and group/private toggle.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getFilteredConversations(bool isGroup) {
    return SampleData.conversations
        .where((c) => (c['isGroup'] == 'true') == isGroup)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.peachLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_rounded, color: AppColors.textPrimary, size: 20),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: Icon(Icons.search, color: AppColors.textPrimary.withOpacity(0.4)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textPrimary.withOpacity(0.4)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // ── Tab Bar (Private / Groups) ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.peachLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.peach,
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textPrimary.withOpacity(0.5),
              labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Private'),
                Tab(text: 'Groups'),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── Conversation Lists ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Private
                _ConversationList(
                  conversations: _getFilteredConversations(false),
                ),
                // Groups
                _ConversationList(
                  conversations: _getFilteredConversations(true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  final List<Map<String, String>> conversations;

  const _ConversationList({required this.conversations});

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.peach.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: AppColors.textPrimary.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conv = conversations[index];
        return ChatTile(
          name: conv['name']!,
          avatarUrl: conv['avatar']!,
          lastMessage: conv['lastMessage']!,
          time: conv['time']!,
          isGroup: conv['isGroup'] == 'true',
          unreadCount: int.tryParse(conv['unread'] ?? '0') ?? 0,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  contactName: conv['name']!,
                  contactAvatar: conv['avatar']!,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
