import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;
import '../../core/neo_brutalist_tokens.dart';
import '../../core/result.dart';
import '../../data/models/chat_group_model.dart';
import '../../data/models/group_member_model.dart';
import '../../data/repositories/interfaces/i_social_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/form_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GROUP MEMBERS SCREEN — "Üyeler"
//
// Opened from [GroupDetailScreen]'s "N üye" row. Reads
// [ISocialRepository.watchGroupMembers] directly (no dedicated ViewModel —
// this state is only ever needed on this one screen, same "screen-scoped
// repository read" pattern [GroupDetailScreen]/[MessageRequestsScreen] use
// for their own one-off actions) and shows every [GroupMemberModel], owner
// first.
//
// Moderation actions are gated by the *viewer's own* role in the member
// list (found by matching their uid), never trusted from client state:
//   • Owner    — can kick anyone except themself, and grant/revoke
//                "Yönetici" (moderator) on any non-owner member.
//   • Moderator — can kick any plain member (not the owner, not another
//                moderator), cannot grant/revoke roles.
//   • Member    — no actions; leaves via [GroupDetailScreen]'s "Üyesin"
//                toggle instead, not from here.
// Real enforcement of all of this lives in Firestore security rules, not
// in this screen — see the `communityGroups/{groupId}/members` block in
// firestore.rules.
// ─────────────────────────────────────────────────────────────────────────────

class GroupMembersScreen extends StatelessWidget {
  final ChatGroupModel group;

  const GroupMembersScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthViewModel>().currentUser?.id ?? '';
    final socialRepo = context.read<ISocialRepository>();

    return Scaffold(
      backgroundColor: NeoBrutal.scaffoldBg,
      appBar: AppBar(
        backgroundColor: NeoBrutal.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Üyeler',
          style: GoogleFonts.baloo2(
            fontWeight: FontWeight.w600,
            fontSize: 19,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GroupMemberModel>>(
        stream: socialRepo.watchGroupMembers(group.id),
        builder: (context, snapshot) {
          final members = snapshot.data ?? const <GroupMemberModel>[];
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: EspatiColors.mintGreen,
              ),
            );
          }
          if (members.isEmpty) {
            return Center(
              child: Text(
                'Henüz üye yok.',
                style: GoogleFonts.nunitoSans(
                    fontSize: 13, color: Colors.black.withValues(alpha: 0.5)),
              ),
            );
          }

          final me = members.where((m) => m.uid == myUid).firstOrNull;
          final myRole = me?.role ?? GroupMemberRole.member;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final member = members[i];
                    return _MemberTile(
                      member: member,
                      isSelf: member.uid == myUid,
                      myRole: myRole,
                      onKick: () => _kick(context, member),
                      onToggleModerator: () => _toggleModerator(context, member),
                    );
                  },
                ),
              ),
              if (myRole == GroupMemberRole.owner)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: GestureDetector(
                    onTap: () => _deleteGroup(context),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: EspatiColors.red, width: 2.5),
                      ),
                      child: Text(
                        'Grubu Sil',
                        style: GoogleFonts.baloo2(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: EspatiColors.red,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteGroup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: Text('"${group.name}" grubu tamamen silinsin mi?',
            style: GoogleFonts.baloo2(fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text(
          'Bu işlem geri alınamaz. Grup ve üye listesi kalıcı olarak silinir '
          '(paylaşılan gönderiler/ilanlar etkilenmez).',
          style: GoogleFonts.nunitoSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Sil', style: TextStyle(color: EspatiColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    HapticFeedback.mediumImpact();
    final ok = await context.read<FormViewModel>().deleteGroup(group.id);
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<FormViewModel>().createGroupError ?? 'Grup silinemedi.',
            style: GoogleFonts.nunitoSans(fontSize: 13),
          ),
          backgroundColor: EspatiColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _kick(BuildContext context, GroupMemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: Text('${member.name} gruptan çıkarılsın mı?',
            style: GoogleFonts.baloo2(fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text(
          'Bu kullanıcı gruba yeniden katılabilir.',
          style: GoogleFonts.nunitoSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Çıkar', style: TextStyle(color: EspatiColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    HapticFeedback.mediumImpact();
    final result = await context
        .read<ISocialRepository>()
        .kickGroupMember(group.id, member.uid, groupName: group.name);
    if (!context.mounted) return;
    if (result case Failure(:final message)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.nunitoSans(fontSize: 13)),
          backgroundColor: EspatiColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleModerator(
      BuildContext context, GroupMemberModel member) async {
    final makingModerator = member.role != GroupMemberRole.moderator;
    HapticFeedback.selectionClick();
    final result = await context.read<ISocialRepository>().setGroupModerator(
          group.id,
          member.uid,
          makingModerator,
        );
    if (!context.mounted) return;
    if (result case Failure(:final message)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.nunitoSans(fontSize: 13)),
          backgroundColor: EspatiColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEMBER TILE
// ─────────────────────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final GroupMemberModel member;
  final bool isSelf;
  final GroupMemberRole myRole;
  final VoidCallback onKick;
  final VoidCallback onToggleModerator;

  const _MemberTile({
    required this.member,
    required this.isSelf,
    required this.myRole,
    required this.onKick,
    required this.onToggleModerator,
  });

  // I may kick this member if: I'm the owner and they're not (owner can
  // kick moderators and members, never themself), or I'm a moderator and
  // they're a plain member (moderators can't kick each other or the owner).
  bool get _canKick {
    if (isSelf || member.role == GroupMemberRole.owner) return false;
    if (myRole == GroupMemberRole.owner) return true;
    if (myRole == GroupMemberRole.moderator) {
      return member.role == GroupMemberRole.member;
    }
    return false;
  }

  // Only the owner may grant/revoke moderator, and never on themself.
  bool get _canToggleModerator =>
      myRole == GroupMemberRole.owner &&
      !isSelf &&
      member.role != GroupMemberRole.owner;

  Color get _roleBadgeColor {
    switch (member.role) {
      case GroupMemberRole.owner:
        return EspatiColors.peach;
      case GroupMemberRole.moderator:
        return EspatiColors.sageGreen;
      case GroupMemberRole.member:
        return Colors.white;
    }
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.name,
                  style: GoogleFonts.baloo2(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 14),
              if (_canToggleModerator)
                _ActionRow(
                  icon: member.role == GroupMemberRole.moderator
                      ? Icons.remove_moderator_rounded
                      : Icons.add_moderator_rounded,
                  label: member.role == GroupMemberRole.moderator
                      ? 'Yöneticilikten Al'
                      : 'Yönetici Yap',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onToggleModerator();
                  },
                ),
              if (_canKick)
                _ActionRow(
                  icon: Icons.person_remove_rounded,
                  label: 'Gruptan Çıkar',
                  color: EspatiColors.red,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onKick();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showMenu = _canKick || _canToggleModerator;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: NeoBrutal.border(2),
        boxShadow: NeoBrutal.shadow(const Offset(2, 2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: member.photoUrl.isEmpty
                ? const Icon(Icons.person_rounded, color: Colors.black, size: 22)
                : CachedNetworkImage(
                    imageUrl: member.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const Icon(Icons.person_rounded, color: Colors.black),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.person_rounded, color: Colors.black),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.name.isEmpty ? 'Kullanıcı' : member.name,
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _roleBadgeColor,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text(
              member.role.label,
              style: GoogleFonts.nunitoSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          if (showMenu) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.black, size: 20),
              onPressed: () => _showActions(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    this.color = Colors.black,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.baloo2(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
