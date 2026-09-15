import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../data/models/notification_model.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../widgets/common/neo_brutalist_button.dart';

/// Dedicated notification screen with full list and "Tümünü okundu
/// işaretle" button — Neo-Brutalist pass, aligned to the app's current
/// design system (same [NeoBrutal] tokens as Keşfet/[ProfileScreen]).
///
/// All state is managed by [NotificationViewModel].
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: _NotificationAppBar(),
      body: Consumer<NotificationViewModel>(
        builder: (context, vm, _) {
          // ── Empty State ──
          if (vm.notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        border: NeoBrutal.border(2.5),
                      ),
                      child: Icon(Icons.notifications_off_rounded,
                          size: 44, color: Colors.black.withValues(alpha: 0.35)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Henüz bildirim yok',
                      style: GoogleFonts.baloo2(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gönderi ve etkinliklerle etkileşime geçtiğinde\nbildirimler burada görünecek.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Notification List ──
          return Column(
            children: [
              if (vm.hasUnread)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: EspatiColors.terracotta,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(2),
                    boxShadow: NeoBrutal.shadow(const Offset(3, 3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                          color: Colors.black, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${vm.unreadCount} okunmamış bildirim',
                        style: GoogleFonts.nunitoSans(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: vm.notifications.length,
                  itemBuilder: (context, index) {
                    final notif = vm.notifications[index];
                    return _NotificationCard(
                      notification: notif,
                      onTap: () => vm.markAsRead(notif.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP BAR — sharp back block + Fredoka title + "Tümünü okundu işaretle"
// action, thick black bottom border on the [NeoBrutal.scaffoldBg] canvas.
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: NeoBrutal.scaffoldBg,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: NeoBrutal.borderWidth),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              NeoBrutalistButton(
                semanticLabel: 'Geri',
                onPressed: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: NeoBrutal.border(2.5),
                    boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.black, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bildirimler',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Consumer<NotificationViewModel>(
                builder: (context, vm, _) {
                  if (vm.notifications.isEmpty) return const SizedBox.shrink();
                  return NeoBrutalistButton(
                    semanticLabel: 'Tümünü okundu işaretle',
                    onPressed: () => vm.markAllAsRead(),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: EspatiColors.sageGreen,
                        borderRadius: BorderRadius.zero,
                        border: NeoBrutal.border(2.5),
                        boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
                      ),
                      child: const Icon(Icons.done_all_rounded,
                          color: Colors.black, size: 20),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION CARD — white block, thick black border; unread cards get an
// accent-tinted fill, hard shadow, and a square accent dot.
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.like:
        return Icons.favorite_rounded;
      case NotificationType.comment:
        return Icons.chat_bubble_rounded;
      case NotificationType.event:
        return Icons.event_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
      case NotificationType.groupKick:
        return Icons.person_remove_rounded;
    }
  }

  Color get _accentColor {
    switch (notification.type) {
      case NotificationType.like:
        return EspatiColors.red;
      case NotificationType.comment:
        return EspatiColors.lightBlue;
      case NotificationType.event:
        return EspatiColors.sageGreen;
      case NotificationType.system:
        return EspatiColors.terracotta;
      case NotificationType.groupKick:
        return EspatiColors.red;
    }
  }

  String _formatTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}sa önce';
    return '${diff.inDays}g önce';
  }

  @override
  Widget build(BuildContext context) {
    return NeoBrutalistButton(
      semanticLabel: notification.title,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : _accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.zero,
          border: NeoBrutal.border(2),
          boxShadow:
              notification.isRead ? null : NeoBrutal.shadow(const Offset(3, 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.zero,
                border: NeoBrutal.border(2),
              ),
              child: Icon(_icon, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.nunitoSans(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(notification.timestamp),
                        style: GoogleFonts.nunitoSans(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  color: _accentColor,
                  border: Border.all(color: Colors.black, width: 1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
