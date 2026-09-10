/// User model representing a pet owner on the ESPATI platform.
///
/// Supports JSON serialization for Firebase/REST API integration,
/// immutable state updates via [copyWith], and safe empty state via [UserModel.empty].
class UserModel {
  final String id;
  final String email;
  final String name;

  /// Handle shown as "@username" (Step 55). Not yet enforced unique across
  /// accounts — that needs a reservation-doc pattern (a `usernames/{name}`
  /// collection written in the same transaction as the profile update) to
  /// do safely, which is a bigger change than this step's scope; today two
  /// users can save the same handle.
  final String username;
  final String bio;
  final String profilePicture;

  /// External link shown on the profile (Step 55) — freeform text, not
  /// validated as a well-formed URL.
  final String link;
  final String locationDistrict;
  final List<String> ownedPetIds;

  /// Number of users who follow this account.
  /// Denormalized counter maintained server-side by the follow transaction.
  final int followersCount;

  /// Number of users this account follows.
  /// Denormalized counter maintained server-side by the follow transaction.
  final int followingCount;

  /// Weighted interest signal per content tag/category (e.g. "Kedi", "Acil",
  /// "Golden") — accumulated by [InteractionTrackingService.logInteraction]
  /// from views/likes/saves. Powers the future Summit A recommendation feed
  /// ranking (see [AlgorithmicFeedScreen]); nothing reads this yet. Defaults
  /// to an empty map for every user until they generate their first signal.
  final Map<String, double> interestScores;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.username = '',
    required this.bio,
    required this.profilePicture,
    this.link = '',
    required this.locationDistrict,
    required this.ownedPetIds,
    this.followersCount = 0,
    this.followingCount = 0,
    this.interestScores = const {},
  });

  /// Creates an empty [UserModel] to avoid null-pointer errors in the UI.
  factory UserModel.empty() {
    return const UserModel(
      id: '',
      email: '',
      name: '',
      username: '',
      bio: '',
      profilePicture: '',
      link: '',
      locationDistrict: '',
      ownedPetIds: [],
      followersCount: 0,
      followingCount: 0,
      interestScores: {},
    );
  }

  /// Creates a [UserModel] from a JSON map (e.g. Firestore document or REST response).
  ///
  /// The `name` field is read first; if absent or blank, falls back to
  /// `displayName` (the field used by manually seeded / legacy documents
  /// such as the `test_user_99` integration-test fixture).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String? ?? '';
    final displayName = json['displayName'] as String? ?? '';
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: rawName.isNotEmpty ? rawName : displayName,
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profilePicture: json['profilePicture'] as String? ?? '',
      link: json['link'] as String? ?? '',
      locationDistrict: json['locationDistrict'] as String? ?? '',
      ownedPetIds: (json['ownedPetIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      // These counters are maintained server-side by the follow transaction;
      // they are read from Firestore but never written back via toJson().
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      interestScores: _parseInterestScores(json['interestScores']),
    );
  }

  /// Firestore stores map values as `num` (int or double depending on how
  /// they were last written — e.g. an integer weight round-trips as `int`),
  /// so each value is defensively cast to [double] rather than assumed.
  static Map<String, double> _parseInterestScores(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, v) => MapEntry(key as String, (v as num).toDouble()),
    );
  }

  /// Converts this [UserModel] to a JSON map for persistence.
  ///
  /// `nameLower` is a lowercase copy of [name] written alongside the display
  /// value so Firestore range queries (`isGreaterThanOrEqualTo` /
  /// `isLessThanOrEqualTo`) can perform case-insensitive prefix searches.
  /// It is derived from [name] and never stored separately in the model itself.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'nameLower': name.toLowerCase(),
      'username': username,
      'bio': bio,
      'profilePicture': profilePicture,
      'link': link,
      'locationDistrict': locationDistrict,
      'ownedPetIds': ownedPetIds,
      'interestScores': interestScores,
    };
  }

  /// Returns a copy of this [UserModel] with the given fields replaced.
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? username,
    String? bio,
    String? profilePicture,
    String? link,
    String? locationDistrict,
    List<String>? ownedPetIds,
    int? followersCount,
    int? followingCount,
    Map<String, double>? interestScores,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profilePicture: profilePicture ?? this.profilePicture,
      link: link ?? this.link,
      locationDistrict: locationDistrict ?? this.locationDistrict,
      ownedPetIds: ownedPetIds ?? this.ownedPetIds,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      interestScores: interestScores ?? this.interestScores,
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
