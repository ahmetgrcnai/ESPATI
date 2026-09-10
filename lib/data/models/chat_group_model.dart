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

  const ChatGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.petCategory,
    required this.memberCount,
    this.isPinned = false,
  });

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
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'petCategory': petCategory.name,
        'memberCount': memberCount,
        'isPinned': isPinned,
      };

  ChatGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    PetCategory? petCategory,
    int? memberCount,
    bool? isPinned,
  }) {
    return ChatGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      petCategory: petCategory ?? this.petCategory,
      memberCount: memberCount ?? this.memberCount,
      isPinned: isPinned ?? this.isPinned,
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
