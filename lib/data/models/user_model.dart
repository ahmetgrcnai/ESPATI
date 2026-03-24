/// User model representing a pet owner on the ESPATI platform.
///
/// Supports JSON serialization for Firebase/REST API integration,
/// immutable state updates via [copyWith], and safe empty state via [UserModel.empty].
class UserModel {
  final String id;
  final String email;
  final String name;
  final String bio;
  final String profilePicture;
  final String locationDistrict;
  final List<String> ownedPetIds;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.bio,
    required this.profilePicture,
    required this.locationDistrict,
    required this.ownedPetIds,
  });

  /// Creates an empty [UserModel] to avoid null-pointer errors in the UI.
  factory UserModel.empty() {
    return const UserModel(
      id: '',
      email: '',
      name: '',
      bio: '',
      profilePicture: '',
      locationDistrict: '',
      ownedPetIds: [],
    );
  }

  /// Creates a [UserModel] from a JSON map (e.g. Firestore document or REST response).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profilePicture: json['profilePicture'] as String? ?? '',
      locationDistrict: json['locationDistrict'] as String? ?? '',
      ownedPetIds: (json['ownedPetIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Converts this [UserModel] to a JSON map for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'bio': bio,
      'profilePicture': profilePicture,
      'locationDistrict': locationDistrict,
      'ownedPetIds': ownedPetIds,
    };
  }

  /// Returns a copy of this [UserModel] with the given fields replaced.
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    String? profilePicture,
    String? locationDistrict,
    List<String>? ownedPetIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      profilePicture: profilePicture ?? this.profilePicture,
      locationDistrict: locationDistrict ?? this.locationDistrict,
      ownedPetIds: ownedPetIds ?? this.ownedPetIds,
    );
  }

  /// Whether this instance represents an empty / placeholder user.
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  String toString() =>
      'UserModel(id: $id, email: $email, name: $name, locationDistrict: $locationDistrict)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
