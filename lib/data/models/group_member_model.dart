import 'package:cloud_firestore/cloud_firestore.dart';

/// A member's standing inside one Topluluk group —
/// `communityGroups/{groupId}/members/{uid}`.
///
///   • [GroupMemberRole.owner]     — the group's creator. Exactly one per
///     group, set once at creation ([FirestoreFormRepository.createGroup])
///     and never reassigned; can never be kicked or demoted.
///   • [GroupMemberRole.moderator] — a member the owner has granted kick
///     rights to ([ISocialRepository.setGroupModerator]).
///   • [GroupMemberRole.member]    — the default role on joining via
///     [ISocialRepository.toggleGroupMembership].
enum GroupMemberRole { owner, moderator, member }

extension GroupMemberRoleX on GroupMemberRole {
  String get label {
    switch (this) {
      case GroupMemberRole.owner:
        return 'Kurucu';
      case GroupMemberRole.moderator:
        return 'Yönetici';
      case GroupMemberRole.member:
        return 'Üye';
    }
  }

  /// Owner and moderator may both kick a plain member (and each other,
  /// except the owner, who can never be kicked — enforced by the caller,
  /// not this getter).
  bool get canModerate =>
      this == GroupMemberRole.owner || this == GroupMemberRole.moderator;
}

class GroupMemberModel {
  final String uid;

  /// Denormalized at join time (same convention as [PostModel.authorName]/
  /// [CommentModel.authorName]) so the member list renders with zero extra
  /// per-member reads.
  final String name;
  final String photoUrl;

  final GroupMemberRole role;
  final DateTime joinedAt;

  const GroupMemberModel({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMemberModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return GroupMemberModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      role: _roleFromString(data['role'] as String?),
      joinedAt: _parseTimestamp(data['joinedAt']),
    );
  }

  GroupMemberModel copyWith({GroupMemberRole? role}) => GroupMemberModel(
        uid: uid,
        name: name,
        photoUrl: photoUrl,
        role: role ?? this.role,
        joinedAt: joinedAt,
      );

  static GroupMemberRole _roleFromString(String? value) {
    return GroupMemberRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => GroupMemberRole.member,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }
}
