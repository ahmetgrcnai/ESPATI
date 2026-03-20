/// Enum representing the type of pet.
enum PetType {
  dog,
  cat,
  bird,
  fish,
  rabbit,
  hamster,
  turtle,
  other;

  /// Creates a [PetType] from its string name.
  static PetType fromString(String value) {
    return PetType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PetType.other,
    );
  }
}

/// Enum representing the gender of a pet.
enum PetGender {
  male,
  female,
  unknown;

  /// Creates a [PetGender] from its string name.
  static PetGender fromString(String value) {
    return PetGender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PetGender.unknown,
    );
  }
}

/// Pet model representing an animal registered on the ESPATI platform.
///
/// Supports JSON serialization for Firebase/REST API integration,
/// immutable state updates via [copyWith], and safe empty state via [PetModel.empty].
class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final int age;
  final PetGender gender;
  final String medicalHistorySummary;
  final PetType petType;

  const PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.medicalHistorySummary,
    required this.petType,
  });

  /// Creates an empty [PetModel] to avoid null-pointer errors in the UI.
  factory PetModel.empty() {
    return const PetModel(
      id: '',
      ownerId: '',
      name: '',
      breed: '',
      age: 0,
      gender: PetGender.unknown,
      medicalHistorySummary: '',
      petType: PetType.other,
    );
  }

  /// Creates a [PetModel] from a JSON map (e.g. Firestore document or REST response).
  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      breed: json['breed'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      gender: PetGender.fromString(json['gender'] as String? ?? ''),
      medicalHistorySummary: json['medicalHistorySummary'] as String? ?? '',
      petType: PetType.fromString(json['petType'] as String? ?? ''),
    );
  }

  /// Converts this [PetModel] to a JSON map for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'breed': breed,
      'age': age,
      'gender': gender.name,
      'medicalHistorySummary': medicalHistorySummary,
      'petType': petType.name,
    };
  }

  /// Returns a copy of this [PetModel] with the given fields replaced.
  PetModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? breed,
    int? age,
    PetGender? gender,
    String? medicalHistorySummary,
    PetType? petType,
  }) {
    return PetModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      medicalHistorySummary:
          medicalHistorySummary ?? this.medicalHistorySummary,
      petType: petType ?? this.petType,
    );
  }

  /// Whether this instance represents an empty / placeholder pet.
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  String toString() =>
      'PetModel(id: $id, name: $name, breed: $breed, petType: ${petType.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
