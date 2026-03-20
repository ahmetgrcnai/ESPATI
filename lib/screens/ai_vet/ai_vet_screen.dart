import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../data/sample_data.dart';
import '../../viewmodels/ai_vet_viewmodel.dart';
import '../../widgets/lost_pet_card.dart';

/// AI/Vet screen — three sections: Ask AI, Ask a Vet (Q&A), and Lost Pet Reports.
///
/// The Ask AI tab is powered by [AIVetViewModel] which manages all chat
/// business logic. The UI only reads state and calls [sendMessage].
class AiVetScreen extends StatefulWidget {
  const AiVetScreen({super.key});

  @override
  State<AiVetScreen> createState() => _AiVetScreenState();
}

class _AiVetScreenState extends State<AiVetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'AI & Vet Help',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Tab Bar ──
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
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Ask AI'),
                Tab(text: 'Ask Vet'),
                Tab(text: 'Lost Pets'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Tab Views ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AskAiTab(),
                _AskVetTab(),
                _LostPetsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// ASK AI TAB — powered by AIVetViewModel
// ────────────────────────────────────────────────────────
class _AskAiTab extends StatefulWidget {
  const _AskAiTab();

  @override
  State<_AskAiTab> createState() => _AskAiTabState();
}

class _AskAiTabState extends State<_AskAiTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls to the bottom of the chat list after a new message arrives.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Sends the typed message via [AIVetViewModel].
  void _sendQuestion() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<AIVetViewModel>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIVetViewModel>(
      builder: (context, viewModel, child) {
        // Auto-scroll when messages change
        _scrollToBottom();

        // Show error via SnackBar if present
        if (viewModel.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(viewModel.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
            viewModel.clearError();
          });
        }

        return Column(
          children: [
            // ── Message List ──
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount:
                    viewModel.messages.length + (viewModel.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show typing indicator as the last item when loading
                  if (index == viewModel.messages.length) {
                    return const _TypingIndicator();
                  }

                  final msg = viewModel.messages[index];
                  return _AiChatBubble(
                    text: msg.text,
                    isAi: !msg.isUser,
                  );
                },
              ),
            ),

            // ── Input Bar ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Ask the AI anything about pets...',
                          prefixIcon: Icon(Icons.smart_toy_outlined,
                              color: AppColors.primary, size: 20),
                        ),
                        onSubmitted: (_) => _sendQuestion(),
                        enabled: !viewModel.isLoading,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: viewModel.isLoading
                              ? [Colors.grey, Colors.grey.shade600]
                              : [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: viewModel.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded,
                                color: Colors.white),
                        onPressed: viewModel.isLoading ? null : _sendQuestion,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Typing Indicator ──
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(1),
                const SizedBox(width: 4),
                _dot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// ── Chat Bubble ──
class _AiChatBubble extends StatelessWidget {
  final String text;
  final bool isAi;

  const _AiChatBubble({required this.text, required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAi) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isAi ? AppColors.surface : AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isAi ? 4 : 18),
                bottomRight: Radius.circular(isAi ? 18 : 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isAi ? AppColors.textPrimary : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// ASK VET TAB (unchanged, no ViewModel needed yet)
// ────────────────────────────────────────────────────────
class _AskVetTab extends StatelessWidget {
  const _AskVetTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ask a question button
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Post a question to vets — coming soon!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ask a Veterinarian',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Get expert answers about your pet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),

        // Q&A List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Recent Questions',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text('See All',
                    style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: SampleData.vetQuestions.length,
            itemBuilder: (context, index) {
              final q = SampleData.vetQuestions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            q['category'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.question_answer_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${q['answers']} answers',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimary.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q['question'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'by ${q['author']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────
// LOST PETS TAB (unchanged, no ViewModel needed yet)
// ────────────────────────────────────────────────────────
class _LostPetsTab extends StatelessWidget {
  const _LostPetsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Report button
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Report a lost pet — coming soon!'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.error, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Report a Lost Pet',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.error, size: 16),
                ],
              ),
            ),
          ),
        ),

        // Lost pets list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: SampleData.lostPets.length,
            itemBuilder: (context, index) {
              final pet = SampleData.lostPets[index];
              return LostPetCard(
                name: pet['name'] as String,
                type: pet['type'] as String,
                lastSeen: pet['lastSeen'] as String,
                date: pet['date'] as String,
                imageUrl: pet['image'] as String,
                contact: pet['contact'] as String,
                description: pet['description'] as String,
              );
            },
          ),
        ),
      ],
    );
  }
}
