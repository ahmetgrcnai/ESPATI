import 'package:cloud_firestore/cloud_firestore.dart';

/// A confirmed mutual match in the Çiftleşme (mating) module —
/// `matingMatches/{autoId}`, created by [FirestoreMatingRepository.swipe]
/// once both pets have a `liked: true` [MatingSwipeModel] pointing at each
/// other (see that model's own doc comment).
///
/// [chatRoomId] starts empty — the match document itself doesn't create
/// the chat room (that needs [IChatRepository], a repository
/// [IMatingRepository] deliberately doesn't depend on); [MatingViewModel]
/// creates the room right after a match and calls
/// [IMatingRepository.attachChatRoom] to fill this in.
class MatingMatchModel {
  final String id;
  final String petAId;
  final String petBId;
  final String ownerAId;
  final String ownerBId;
  final DateTime matchedAt;
  final String chatRoomId;

  const MatingMatchModel({
    required this.id,
    required this.petAId,
    required this.petBId,
    required this.ownerAId,
    required this.ownerBId,
    required this.matchedAt,
    this.chatRoomId = '',
  });

  bool involvesPet(String petId) => petAId == petId || petBId == petId;

  String otherPetId(String petId) => petAId == petId ? petBId : petAId;
  String otherOwnerId(String ownerId) =>
      ownerAId == ownerId ? ownerBId : ownerAId;

  factory MatingMatchModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final matchedAt = data['matchedAt'];
    return MatingMatchModel(
      id: doc.id,
      petAId: data['petAId'] as String? ?? '',
      petBId: data['petBId'] as String? ?? '',
      ownerAId: data['ownerAId'] as String? ?? '',
      ownerBId: data['ownerBId'] as String? ?? '',
      matchedAt: matchedAt is Timestamp ? matchedAt.toDate() : DateTime.now(),
      chatRoomId: data['chatRoomId'] as String? ?? '',
    );
  }

  /// [petIds]/[ownerIds] are redundant array mirrors of the four id fields
  /// above — written so [FirestoreMatingRepository]'s yearly-limit check
  /// can use a single `array-contains` query per pet instead of two
  /// separate `petAId ==` / `petBId ==` queries merged client-side.
  Map<String, dynamic> toFirestore() => {
        'petAId': petAId,
        'petBId': petBId,
        'ownerAId': ownerAId,
        'ownerBId': ownerBId,
        'petIds': [petAId, petBId],
        'ownerIds': [ownerAId, ownerBId],
        'matchedAt': FieldValue.serverTimestamp(),
        'chatRoomId': chatRoomId,
      };

  MatingMatchModel copyWith({String? chatRoomId}) => MatingMatchModel(
        id: id,
        petAId: petAId,
        petBId: petBId,
        ownerAId: ownerAId,
        ownerBId: ownerBId,
        matchedAt: matchedAt,
        chatRoomId: chatRoomId ?? this.chatRoomId,
      );
}
