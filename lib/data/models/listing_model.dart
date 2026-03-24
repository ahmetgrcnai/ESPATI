/// Status of a pet listing on the ESPATI platform.
enum ListingStatus {
  kayip,          // Lost pet
  sahiplendirme,  // Adoption
}

extension ListingStatusX on ListingStatus {
  String get label {
    switch (this) {
      case ListingStatus.kayip:
        return 'Kayıp';
      case ListingStatus.sahiplendirme:
        return 'Sahiplendirme';
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
  final ListingStatus status;
  final String location;      // Eskişehir neighbourhood
  final String date;          // Human-readable Turkish date
  final String imageUrl;
  final String contact;
  final String description;
  final DateTime createdAt;

  const ListingModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.contact,
    required this.description,
    required this.createdAt,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: (json['status'] as String?) == 'kayip'
          ? ListingStatus.kayip
          : ListingStatus.sahiplendirme,
      location: json['location'] as String? ?? '',
      date: json['date'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'status': status.name,
        'location': location,
        'date': date,
        'imageUrl': imageUrl,
        'contact': contact,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  ListingModel copyWith({
    String? id,
    String? name,
    String? type,
    ListingStatus? status,
    String? location,
    String? date,
    String? imageUrl,
    String? contact,
    String? description,
    DateTime? createdAt,
  }) {
    return ListingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      location: location ?? this.location,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      contact: contact ?? this.contact,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
