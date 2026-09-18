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

/// A self-declared character trait for the Çiftleşme (mating) module's
/// swipe deck — shown as chips on [MatingSwipeScreen]'s cards so a swiper
/// sees more than a photo before deciding. Purely descriptive; not used
/// for any automatic compatibility scoring (that's a later phase, see the
/// module's roadmap discussion).
enum PetCharacterTag {
  uysal,
  enerjik,
  dominant,
  sakin,
  oyuncu,
  bagimsiz;

  String get label {
    switch (this) {
      case PetCharacterTag.uysal:
        return 'Uysal';
      case PetCharacterTag.enerjik:
        return 'Enerjik';
      case PetCharacterTag.dominant:
        return 'Dominant';
      case PetCharacterTag.sakin:
        return 'Sakin';
      case PetCharacterTag.oyuncu:
        return 'Oyuncu';
      case PetCharacterTag.bagimsiz:
        return 'Bağımsız';
    }
  }

  static PetCharacterTag? fromString(String value) {
    for (final tag in PetCharacterTag.values) {
      if (tag.name == value) return tag;
    }
    return null;
  }
}

/// Why this pet's owner is looking for a match — a single-select badge
/// shown on the Ruh Eşi (mating) module's swipe card and set from
/// [AddEditPetScreen]'s mating profile section. Purely descriptive intent,
/// distinct from [PetCharacterTag] (character, not intent); wording is
/// deliberately soft/positive and steers clear of anything that could read
/// as a breeding-sale listing.
enum PetMatingPurpose {
  familyBuilding,
  puppyExcitement,
  lookingForFriend;

  String get label {
    switch (this) {
      case PetMatingPurpose.familyBuilding:
        return 'Aile Kuruyor';
      case PetMatingPurpose.puppyExcitement:
        return 'Yavru Heyecanı';
      case PetMatingPurpose.lookingForFriend:
        return 'Arkadaş Arıyor';
    }
  }

  String get description {
    switch (this) {
      case PetMatingPurpose.familyBuilding:
        return 'Aile olma vakti geldi, yuvaya yeni bir üye katılsın istiyoruz.';
      case PetMatingPurpose.puppyExcitement:
        return 'İleride yavrularının olacağı heyecanını yaşıyoruz.';
      case PetMatingPurpose.lookingForFriend:
        return 'Ömür boyu dost olacağı birini arıyoruz.';
    }
  }

  static PetMatingPurpose? fromString(String value) {
    for (final p in PetMatingPurpose.values) {
      if (p.name == value) return p;
    }
    return null;
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
  final String photoUrl;
  final String bio;
  final double weight;

  // ── Çiftleşme (mating) module — see MatingSwipeScreen ─────────────────────

  /// Whether this pet's owner has opted it into the mating swipe deck.
  /// Can only be set `true` alongside [isVaccinated] and a non-empty
  /// [vaccinationCardUrl] — [AddEditPetScreen] enforces that pairing in the
  /// UI; a pet missing either is simply never eligible regardless of this
  /// flag (see [isEligibleForMating]).
  final bool isAvailableForMating;

  /// Self-declared "core vaccines are up to date" statement — required
  /// alongside [vaccinationCardUrl] before [isAvailableForMating] means
  /// anything. Self-declared, not veterinarian-verified; the photo is the
  /// only check beyond the owner's word.
  final bool isVaccinated;

  /// Storage download URL for a photo of the pet's vaccination card —
  /// required proof backing [isVaccinated]. Empty until uploaded.
  final String vaccinationCardUrl;

  /// Self-selected character traits shown on the pet's swipe card —
  /// see [PetCharacterTag].
  final List<PetCharacterTag> characterTags;

  /// Why this pet's owner is looking for a match — see [PetMatingPurpose].
  /// `null` until the owner picks one; not required for [isEligibleForMating].
  final PetMatingPurpose? matingPurpose;

  const PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.medicalHistorySummary,
    required this.petType,
    this.photoUrl = '',
    this.bio = '',
    this.weight = 0,
    this.isAvailableForMating = false,
    this.isVaccinated = false,
    this.vaccinationCardUrl = '',
    this.characterTags = const [],
    this.matingPurpose,
  });

  /// The actual gate [MatingSwipeScreen]'s deck query checks — [PetModel]s
  /// are only truly discoverable once the vaccine declaration + card are
  /// both in place, not on [isAvailableForMating] alone (a pet could have
  /// flipped the flag on before either was set, in theory — this closes
  /// that gap defensively on the read side too, not just the write side).
  bool get isEligibleForMating =>
      isAvailableForMating && isVaccinated && vaccinationCardUrl.isNotEmpty;

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
      photoUrl: '',
      bio: '',
      weight: 0,
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
      photoUrl: json['photoUrl'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      isAvailableForMating: json['isAvailableForMating'] as bool? ?? false,
      isVaccinated: json['isVaccinated'] as bool? ?? false,
      vaccinationCardUrl: json['vaccinationCardUrl'] as String? ?? '',
      characterTags: (json['characterTags'] as List<dynamic>? ?? const [])
          .map((t) => PetCharacterTag.fromString(t as String))
          .whereType<PetCharacterTag>()
          .toList(),
      matingPurpose: json['matingPurpose'] == null
          ? null
          : PetMatingPurpose.fromString(json['matingPurpose'] as String),
    );
  }

  /// Creates a [PetModel] from a Firestore document data map.
  ///
  /// [id] is passed separately because Firestore stores it as the document key,
  /// not inside the data map.
  factory PetModel.fromFirestore(Map<String, dynamic> data,
      {required String id}) {
    return PetModel.fromJson({'id': id, ...data});
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
      'photoUrl': photoUrl,
      'bio': bio,
      'weight': weight,
      'isAvailableForMating': isAvailableForMating,
      'isVaccinated': isVaccinated,
      'vaccinationCardUrl': vaccinationCardUrl,
      'characterTags': characterTags.map((t) => t.name).toList(),
      'matingPurpose': matingPurpose?.name,
    };
  }

  /// Alias for [toJson] — used at Firestore write call-sites for clarity.
  Map<String, dynamic> toFirestore() => toJson();

  /// Sentinel default for [copyWith]'s [matingPurpose] param — lets callers
  /// pass an explicit `null` to clear a previously-set purpose, which a
  /// plain `matingPurpose ?? this.matingPurpose` fallback couldn't
  /// distinguish from "leave unchanged".
  static const Object _unset = Object();

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
    String? photoUrl,
    String? bio,
    double? weight,
    bool? isAvailableForMating,
    bool? isVaccinated,
    String? vaccinationCardUrl,
    List<PetCharacterTag>? characterTags,
    Object? matingPurpose = _unset,
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
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      weight: weight ?? this.weight,
      isAvailableForMating: isAvailableForMating ?? this.isAvailableForMating,
      isVaccinated: isVaccinated ?? this.isVaccinated,
      vaccinationCardUrl: vaccinationCardUrl ?? this.vaccinationCardUrl,
      characterTags: characterTags ?? this.characterTags,
      matingPurpose: identical(matingPurpose, _unset)
          ? this.matingPurpose
          : matingPurpose as PetMatingPurpose?,
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
