import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_colors.dart';

/// A list tile for the Messages screen showing avatar, name, last message,
/// time, and unread badge.
class ChatTile extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final bool isGroup;
  final int unreadCount;
  final VoidCallback? onTap;

  const ChatTile({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.isGroup = false,
    this.unreadCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.peachLight,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Icon(Icons.person, color: AppColors.peach),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.person, color: AppColors.peach),
                    ),
                  ),
                ),
                if (isGroup)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.group,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Name and last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight:
                          unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: unreadCount > 0
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withOpacity(0.5),
                      fontWeight:
                          unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time + unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: unreadCount > 0
                        ? AppColors.primary
                        : AppColors.textPrimary.withOpacity(0.4),
                    fontWeight:
                        unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                if (unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
