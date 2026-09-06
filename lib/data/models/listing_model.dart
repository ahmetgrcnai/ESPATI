import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart' show EspatiColors;

/// Status of a pet listing on the ESPATI platform.
enum ListingStatus {
  kayip,          // Lost pet
  sahiplendirme,  // Adoption
  bakici,         // Pet-sitter / caregiver service listing
}

/// Centralized per-status display tokens (label, form title, accent color,
/// icon) — the single source of truth every screen that renders a
/// [ListingModel] reaches for, instead of each screen re-deriving its own
/// `status == ListingStatus.kayip ? a : b` ternary. That ad hoc pattern is
/// how a third status like [ListingStatus.bakici] used to silently fall
/// into whichever branch was written as "not kayip" — an exhaustive
/// `switch` here means the compiler catches every call site that still
/// needs a case added.
extension ListingStatusX on ListingStatus {
  String get label {
    switch (this) {
      case ListingStatus.kayip:
        return 'Kayıp';
      case ListingStatus.sahiplendirme:
        return 'Sahiplendirme';
      case ListingStatus.bakici:
        return 'Bakıcı';
    }
  }

  /// Full listing-type title used by the create form's banner/app bar and
  /// anywhere else a spelled-out type name (rather than the short [label])
  /// reads better.
  String get title {
    switch (this) {
      case ListingStatus.kayip:
        return 'Kayıp/Buluntu İlanı';
      case ListingStatus.sahiplendirme:
        return 'Sahiplendirme İlanı';
      case ListingStatus.bakici:
        return 'Bakıcı İlanı';
    }
  }

  /// Canonical accent color for this status — status chips, card labels,
  /// the create-form banner/submit button.
  Color get accentColor {
    switch (this) {
      case ListingStatus.kayip:
        return EspatiColors.red;
      case ListingStatus.sahiplendirme:
        return EspatiColors.terracotta;
      case ListingStatus.bakici:
        return EspatiColors.lightBlue;
    }
  }

  /// Canonical icon for this status.
  IconData get icon {
    switch (this) {
      case ListingStatus.kayip:
        return Icons.search_rounded;
      case ListingStatus.sahiplendirme:
        return Icons.favorite_rounded;
      case ListingStatus.bakici:
        return Icons.volunteer_activism_rounded;
    }
  }
}

/// Represents a single pet listing (lost or adoption) in the İlanlar tab.
///
/// Immutable value object. Supports JSON serialization for future
/// Firestore / REST API integration.
class ListingModel {
  final String id;
  final String name;
  final String type;          // Breed / species description
  /// Structured species facet ("Kedi", "Köpek", ...) for Discovery filtering.
  /// [type] stays free-text ("Kedi — Tekir Kedi") since it's display copy;
  /// this is the exact-match field filters/queries key off.
  final String species;
  final ListingStatus status;
  final String location;      // Eskişehir neighbourhood
  final String date;          // Human-readable Turkish date

  /// Storage download URLs, in upload order. First entry is the cover photo
  /// shown on cards/map pins ([imageUrl]); [FeedDetailScreen] renders the
  /// full set as a gallery.
  final List<String> imageUrls;
  final String description;
  final DateTime createdAt;

  /// GPS coordinates for the Interactive Map (Sprint 9). Zero for legacy
  /// listings created before geolocation existed — [hasLocation] guards
  /// map-pin rendering so those listings simply don't get a marker.
  final double latitude;
  final double longitude;

  /// Firebase Auth UID of the user who created this listing. Empty for
  /// legacy/seed listings created before messaging existed — the "Mesaj
  /// Gönder" button hides itself when this is empty, since there's no one
  /// to start a chat room with.
  final String authorId;
  final String authorName;
  final String authorPhoto;

  /// Marks a [ListingStatus.kayip] listing as time-critical — surfaced via
  /// the "Acil" filter chip on the Forum tab. Meaningless for
  /// [ListingStatus.sahiplendirme] listings; the create form only exposes
  /// the toggle for Kayıp. Defaults to `false` for every listing written
  /// before this field existed.
  final bool isUrgent;

  /// Community group this listing is routed to (Topluluk / Sub-Reddit
  /// architecture). `null` means unrouted — treated as "Genel" by feed
  /// filters, never written as a literal sentinel string.
  final String? groupId;

  /// AI content moderation gate (Madde 8 — safety mandate). `true` unless a
  /// moderation pass explicitly flags this listing; feed screens must only
  /// render items where this is `true`. Defaults to `true` so every listing
  /// written before moderation existed keeps rendering — the create-flow
  /// gate ([ContentModerationService]) already rejects bad text client-side
  /// before a listing can ever reach Firestore with `isApproved: false`.
  final bool isApproved;

  /// Services offered — only meaningful for [ListingStatus.bakici] listings
  /// (e.g. "Gezdirme", "Pansiyon"). Empty for every other status.
  final List<String> serviceTypes;

  /// Free-text price/rate description — only meaningful for
  /// [ListingStatus.bakici] listings (e.g. "150₺/gün"). Empty otherwise.
  final String priceInfo;

  const ListingModel({
    required this.id,
    required this.name,
    required this.type,
    this.species = '',
    required this.status,
    required this.location,
    required this.date,
    required this.imageUrls,
    required this.description,
    required this.createdAt,
    this.authorId = '',
    this.authorName = '',
    this.authorPhoto = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isUrgent = false,
    this.groupId,
    this.isApproved = true,
    this.serviceTypes = const [],
    this.priceInfo = '',
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      species: _readSpecies(json),
      status: ListingStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ListingStatus.sahiplendirme,
      ),
      location: json['location'] as String? ?? '',
      date: json['date'] as String? ?? '',
      imageUrls: _readImageUrls(json),
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorPhoto: json['authorPhoto'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isUrgent: json['isUrgent'] as bool? ?? false,
      groupId: json['groupId'] as String?,
      isApproved: json['isApproved'] as bool? ?? true,
      serviceTypes: (json['serviceTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      priceInfo: json['priceInfo'] as String? ?? '',
    );
  }

  /// Reads the structured `species` field; falls back to the text before
  /// " — " in [type] for documents written before this field existed, so
  /// pre-Phase-2 listings still filter correctly by species.
  static String _readSpecies(Map<String, dynamic> json) {
    final explicit = json['species'] as String?;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final type = json['type'] as String? ?? '';
    final sepIndex = type.indexOf(' — ');
    return sepIndex == -1 ? type : type.substring(0, sepIndex);
  }

  /// Reads `imageUrls` (current schema); falls back to the legacy singular
  /// `imageUrl` field so documents written before the gallery migration
  /// still render their one photo instead of a blank thumbnail.
  static List<String> _readImageUrls(Map<String, dynamic> json) {
    final list = json['imageUrls'] as List<dynamic>?;
    if (list != null) return list.map((e) => e as String).toList();
    final legacy = json['imageUrl'] as String?;
    return (legacy == null || legacy.isEmpty) ? const [] : [legacy];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'species': species,
        'status': status.name,
        'location': location,
        'date': date,
        'imageUrls': imageUrls,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'authorId': authorId,
        'authorName': authorName,
        'authorPhoto': authorPhoto,
        'latitude': latitude,
        'longitude': longitude,
        'isUrgent': isUrgent,
        'groupId': groupId,
        'isApproved': isApproved,
        'serviceTypes': serviceTypes,
        'priceInfo': priceInfo,
        // Denormalized for a future server-side Discovery query
        // (array-contains-any) — not read by fromJson today. See the
        // Phase 2 strategy note on FirestoreFormRepository.searchListings.
        'searchKeywords': _buildSearchKeywords(),
      };

  /// Lowercase, deduplicated tokens from every field a keyword search should
  /// match — the denormalized index for a future `array-contains-any` query.
  List<String> _buildSearchKeywords() {
    final text = '$name $species $type $location'.toLowerCase();
    final tokens = text
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((t) => t.isNotEmpty);
    return tokens.toSet().toList();
  }

  ListingModel copyWith({
    String? id,
    String? name,
    String? type,
    String? species,
    ListingStatus? status,
    String? location,
    String? date,
    List<String>? imageUrls,
    String? description,
    DateTime? createdAt,
    String? authorId,
    String? authorName,
    String? authorPhoto,
    double? latitude,
    double? longitude,
    bool? isUrgent,
    String? groupId,
    bool? isApproved,
    List<String>? serviceTypes,
    String? priceInfo,
  }) {
    return ListingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      species: species ?? this.species,
      status: status ?? this.status,
      location: location ?? this.location,
      date: date ?? this.date,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorPhoto: authorPhoto ?? this.authorPhoto,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isUrgent: isUrgent ?? this.isUrgent,
      groupId: groupId ?? this.groupId,
      isApproved: isApproved ?? this.isApproved,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      priceInfo: priceInfo ?? this.priceInfo,
    );
  }

  /// Cover photo shown on cards and map pins — the first uploaded image, or
  /// empty when the listing has none yet (upload in flight / failed).
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  /// Whether this listing has a valid map pin. `(0, 0)` (Gulf of Guinea)
  /// is never a real Eskişehir listing, so it doubles as "no location set".
  bool get hasLocation => latitude != 0.0 || longitude != 0.0;

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ListingModel(id: $id, name: $name, status: ${status.name})';
}
