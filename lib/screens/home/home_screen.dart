import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/social_viewmodel.dart';
import '../../widgets/story_circle.dart';
import '../../widgets/post_card.dart';
import '../notifications/notification_screen.dart';

/// Home screen — the main feed with stories, posts, and notification bell.
///
/// All business logic is delegated to [HomeViewModel] and [SocialViewModel].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.pets, color: AppColors.peach, size: 28),
            const SizedBox(width: 8),
            Text(
              'Espati',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: cs.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? cs.surface : AppColors.peachLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.favorite_border, color: cs.onSurface, size: 20),
            ),
            onPressed: () {},
          ),

          // ── Notification Bell with Badge ──
          Consumer<NotificationViewModel>(
            builder: (context, notifVM, child) {
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? cs.surface : AppColors.peachLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.notifications_none_rounded,
                          color: cs.onSurface, size: 20),
                    ),
                    if (notifVM.hasUnread)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            notifVM.unreadCount > 9
                                ? '9+'
                                : '${notifVM.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer2<HomeViewModel, SocialViewModel>(
        builder: (context, homeVM, socialVM, child) {
          // ── Error State ──
          if (homeVM.errorMessage != null && !homeVM.isLoading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 56, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      homeVM.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => homeVM.refresh(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Loading State ──
          if (homeVM.isLoading && homeVM.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Data State ──
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => homeVM.refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // ── Stories ──
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: homeVM.stories.length,
                    itemBuilder: (context, index) {
                      final story = homeVM.stories[index];
                      return StoryCircle(
                        imageUrl: story['avatar']!,
                        name: story['name']!,
                        isOwn: story['isOwn'] == 'true',
                        hasBorder: story['isOwn'] != 'true',
                      );
                    },
                  ),
                ),

                Divider(
                    color: theme.dividerColor,
                    height: 24,
                    indent: 16,
                    endIndent: 16),

                // ── Feed Posts ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: homeVM.posts.map((post) {
                      return PostCard(
                        username: post.userName,
                        avatarUrl: post.userProfileImage,
                        imageUrl: post.imageUrl,
                        caption: post.content,
                        likes: post.likesCount,
                        comments: post.commentsCount,
                        timeAgo: _formatTimeAgo(post.timestamp),
                        postId: post.id,
                        isLiked: socialVM.isPostPati(post.id),
                        onLike: () => socialVM.togglePati(post.id),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Create new post'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        child: const Icon(Icons.add_a_photo_rounded),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
