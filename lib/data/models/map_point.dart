/// Represents a category of pet-friendly place on the map.
enum MapPointCategory {
  vet,
  park,
  cafe,
  petShop;

  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case MapPointCategory.vet:
        return 'Veteriner';
      case MapPointCategory.park:
        return 'Park';
      case MapPointCategory.cafe:
        return 'Kafe';
      case MapPointCategory.petShop:
        return 'Pet Mağazası';
    }
  }

  /// Creates a [MapPointCategory] from its string representation.
  ///
  /// Accepts both the Dart enum name (e.g. `'vet'`) and the Turkish
  /// UI label (e.g. `'Veteriner'`), so Firestore documents can be
  /// authored in either format without breaking the parser.
  static MapPointCategory fromString(String value) {
    return MapPointCategory.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => MapPointCategory.cafe,
    );
  }
}

/// A single point-of-interest on the Eskişehir Pati Haritası.
///
/// Supports JSON serialization for Firebase integration,
/// immutable updates via [copyWith], and a safe [empty] factory.
class MapPoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final MapPointCategory category;
  final double rating;
  final String address;
  final String description;
  final String imageUrl;

  const MapPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.rating,
    required this.address,
    this.description = '',
    this.imageUrl = '',
  });

  /// Creates an empty [MapPoint] to avoid null-pointer errors.
  factory MapPoint.empty() {
    return const MapPoint(
      id: '',
      name: '',
      latitude: 0,
      longitude: 0,
      category: MapPointCategory.cafe,
      rating: 0,
      address: '',
    );
  }

  /// Creates a [MapPoint] from a JSON map.
  factory MapPoint.fromJson(Map<String, dynamic> json) {
    return MapPoint(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      category: MapPointCategory.fromString(json['category'] as String? ?? ''),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  /// Converts this [MapPoint] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'category': category.name,
      'rating': rating,
      'address': address,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  /// Returns a copy with the given fields replaced.
  MapPoint copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    MapPointCategory? category,
    double? rating,
    String? address,
    String? description,
    String? imageUrl,
  }) {
    return MapPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      address: address ?? this.address,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Icon type string for use in PlaceCard widget.
  String get iconType {
    switch (category) {
      case MapPointCategory.vet:
        return 'vet';
      case MapPointCategory.park:
        return 'park';
      case MapPointCategory.cafe:
        return 'coffee';
      case MapPointCategory.petShop:
        return 'shop';
    }
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  String toString() =>
      'MapPoint(id: $id, name: $name, category: ${category.label})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPoint && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
