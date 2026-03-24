import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ACADEMY GUIDE MODEL
//
// Represents a single educational guide in the Pati Akademi learning center.
// Immutable value type — all mutations produce a new instance via [copyWith].
// ─────────────────────────────────────────────────────────────────────────────

/// Identifiers for guide categories.
///
/// Keep in sync with [AcademyCategory.all] used by [AcademyTabView].
class AcademyCategory {
  AcademyCategory._();

  static const String tumu = 'tumu';
  static const String yeniSahip = 'yeni_sahip';
  static const String kopekEgitimi = 'kopek_egitimi';
  static const String kediBakimi = 'kedi_bakimi';
  static const String saglik = 'saglik';

  /// Ordered list of all categories for the horizontal chip strip.
  static const List<({String id, String label})> all = [
    (id: tumu, label: 'Tümü'),
    (id: yeniSahip, label: 'Yeni Sahip'),
    (id: kopekEgitimi, label: 'Köpek Eğitimi'),
    (id: kediBakimi, label: 'Kedi Bakımı'),
    (id: saglik, label: 'Sağlık'),
  ];
}

/// A single educational guide in the Pati Akademi section.
class AcademyGuideModel {
  /// Unique identifier — stable across sessions.
  final String id;

  /// Category key — one of the [AcademyCategory] constants.
  final String category;

  /// Human-readable category label shown on the card chip.
  final String categoryLabel;

  /// Full guide title displayed on the card and the detail screen.
  final String title;

  /// 1-2 sentence teaser shown on the card. Max ~120 characters.
  final String summary;

  /// Complete guide content in GitHub-flavoured Markdown.
  /// Rendered by [flutter_markdown] in [GuideDetailScreen].
  final String contentMarkdown;

  /// Material icon used as the guide's visual identifier.
  final IconData icon;

  /// Accent colour for the icon container and category pill.
  final Color accentColor;

  /// Estimated reading time in minutes.
  final int readMinutes;

  const AcademyGuideModel({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.summary,
    required this.contentMarkdown,
    required this.icon,
    required this.accentColor,
    required this.readMinutes,
  });

  AcademyGuideModel copyWith({
    String? id,
    String? category,
    String? categoryLabel,
    String? title,
    String? summary,
    String? contentMarkdown,
    IconData? icon,
    Color? accentColor,
    int? readMinutes,
  }) {
    return AcademyGuideModel(
      id: id ?? this.id,
      category: category ?? this.category,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      readMinutes: readMinutes ?? this.readMinutes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcademyGuideModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AcademyGuideModel(id: $id, title: $title)';
}
