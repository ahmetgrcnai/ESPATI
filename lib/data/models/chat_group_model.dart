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
      case PetCategory.cat:     return Icons.cruelty_free_rounded;
      case PetCategory.dog:     return Icons.pets_rounded;
      case PetCategory.bird:    return Icons.flutter_dash;
      case PetCategory.rabbit:  return Icons.eco_rounded;
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

/// A community group on the ESPATI platform (e.g. "Kedi Sahipleri").
///
/// Immutable. JSON serialization ready for Firestore/REST integration.
class ChatGroupModel {
  final String id;
  final String name;
  final String description;
  final PetCategory petCategory;
  final int memberCount;
  final String lastMessage;
  final String lastActivityLabel; // e.g. "3 dk önce"
  final int unreadCount;
  final bool isPinned;

  const ChatGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.petCategory,
    required this.memberCount,
    required this.lastMessage,
    required this.lastActivityLabel,
    this.unreadCount = 0,
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
      lastMessage: json['lastMessage'] as String? ?? '',
      lastActivityLabel: json['lastActivityLabel'] as String? ?? '',
      unreadCount: json['unreadCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'petCategory': petCategory.name,
        'memberCount': memberCount,
        'lastMessage': lastMessage,
        'lastActivityLabel': lastActivityLabel,
        'unreadCount': unreadCount,
        'isPinned': isPinned,
      };

  ChatGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    PetCategory? petCategory,
    int? memberCount,
    String? lastMessage,
    String? lastActivityLabel,
    int? unreadCount,
    bool? isPinned,
  }) {
    return ChatGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      petCategory: petCategory ?? this.petCategory,
      memberCount: memberCount ?? this.memberCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivityLabel: lastActivityLabel ?? this.lastActivityLabel,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  bool get hasUnread => unreadCount > 0;

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
