import 'package:flutter/material.dart';

/// Category of pets a community group is focused on.
enum PetCategory { cat, dog, bird, rabbit, fish, all }

extension PetCategoryX on PetCategory {
  String get label {
    switch (this) {
      case PetCategory.cat:     return 'Kedi';
      case PetCategory.dog:     return 'Köpek';
      case PetCategory.bird:    return 'Kuş';
      case PetCategory.rabbit:  return 'Tavşan';
      case PetCategory.fish:    return 'Balık & Sürüngen';
      case PetCategory.all:     return 'Genel';
    }
  }

  IconData get icon {
    switch (this) {
      case PetCategory.cat:     return Icons.pets_rounded;
      case PetCategory.dog:     return Icons.pets_rounded;
      case PetCategory.bird:    return Icons.flutter_dash;
      case PetCategory.rabbit:  return Icons.cruelty_free_rounded;
      case PetCategory.fish:    return Icons.water_rounded;
      case PetCategory.all:     return Icons.groups_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case PetCategory.cat:     return const Color(0xFF4DB6AC); // softTeal
      case PetCategory.dog:     return const Color(0xFFFFB6A0); // peach
      case PetCategory.bird:    return const Color(0xFF42A5F5); // blue
      case PetCategory.rabbit:  return const Color(0xFFBA68C8); // purple
      case PetCategory.fish:    return const Color(0xFF26A69A); // dark teal
      case PetCategory.all:     return const Color(0xFF78909C); // grey
    }
  }
}

/// A community group on the ESPATI platform (e.g. "Kedi Sahipleri") —
/// [CommunityHubScreen]'s "Topluluk" directory entry, backed by the
/// `communityGroups` Firestore collection.
///
/// [isPinned] is a real, admin-curated flag (a document field anyone with
/// Firestore write access can set) used to keep a handful of groups
/// (e.g. "ESPATI Genel") at the top of the list — unrelated to messaging.
///
/// Earlier versions of this model also carried `lastMessage`/
/// `lastActivityLabel`/`unreadCount`, inherited from an old Forum "Gruplar"
/// sub-tab that had a chat-thread concept behind it. That chat thread never
/// actually existed (tapping a group only marked it locally read, nothing
/// was ever sent or persisted) — [GroupDetailScreen] is a content feed, not
/// a chat, so those fields were dropped rather than migrated to Firestore
/// as dead weight.
///
/// Immutable. JSON serialization ready for Firestore/REST integration.
class ChatGroupModel {
  final String id;
  final String name;
  final String description;
  final PetCategory petCategory;
  final int memberCount;
  final bool isPinned;

  /// UID of the user who created this group via [CreateGroupScreen] —
  /// empty for every pre-existing/admin-seeded group (they have no single
  /// owner). Holds permanent kick/moderator-granting authority; never
  /// reassigned. See [GroupMemberRole.owner].
  final String creatorId;

  /// Free-text category the creator typed themselves ("Sohbet", "Eğitim
  /// İpuçları", ...) — `null` for admin-seeded groups, which keep
  /// [petCategory]'s fixed label/icon/color instead. User-created groups
  /// always store [petCategory] as [PetCategory.all] under the hood (so
  /// they still show up under the "Genel" browse filter) and use this
  /// field for their own display label.
  final String? customCategory;

  /// Group cover photo — Storage download URL, empty until the creator
  /// picks one on [CreateGroupScreen]. Falls back to [petCategory]'s icon
  /// wherever this is empty.
  final String coverImageUrl;

  /// Extra denylist words the creator set for this group specifically, on
  /// top of [ContentModerationService]'s app-wide list — checked by every
  /// post/topic submitted into this group (see [CreatePostViewModel]).
  final List<String> bannedWords;

  const ChatGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.petCategory,
    required this.memberCount,
    this.isPinned = false,
    this.creatorId = '',
    this.customCategory,
    this.coverImageUrl = '',
    this.bannedWords = const [],
  });

  /// Display label — the creator's own free-text category if they set one,
  /// otherwise the fixed [PetCategory.label].
  String get categoryLabel {
    final custom = customCategory;
    return (custom != null && custom.isNotEmpty) ? custom : petCategory.label;
  }

  factory ChatGroupModel.fromJson(Map<String, dynamic> json) {
    return ChatGroupModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      petCategory: PetCategory.values.firstWhere(
        (e) => e.name == json['petCategory'],
        orElse: () => PetCategory.all,
      ),
      memberCount: json['memberCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      creatorId: json['creatorId'] as String? ?? '',
      customCategory: json['customCategory'] as String?,
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      bannedWords: List<String>.from(
        json['bannedWords'] as List<dynamic>? ?? const [],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'petCategory': petCategory.name,
        'memberCount': memberCount,
        'isPinned': isPinned,
        'creatorId': creatorId,
        'customCategory': customCategory,
        'coverImageUrl': coverImageUrl,
        'bannedWords': bannedWords,
      };

  ChatGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    PetCategory? petCategory,
    int? memberCount,
    bool? isPinned,
    String? creatorId,
    String? customCategory,
    String? coverImageUrl,
    List<String>? bannedWords,
  }) {
    return ChatGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      petCategory: petCategory ?? this.petCategory,
      memberCount: memberCount ?? this.memberCount,
      isPinned: isPinned ?? this.isPinned,
      creatorId: creatorId ?? this.creatorId,
      customCategory: customCategory ?? this.customCategory,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      bannedWords: bannedWords ?? this.bannedWords,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatGroupModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ChatGroupModel(id: $id, name: $name, members: $memberCount)';
}
