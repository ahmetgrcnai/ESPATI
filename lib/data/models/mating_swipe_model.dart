import 'package:cloud_firestore/cloud_firestore.dart';

/// One directional swipe in the Çiftleşme (mating) module —
/// `matingSwipes/{fromPetId}_{toPetId}`. The compound, deterministic
/// document ID is what lets [FirestoreMatingRepository.swipe] check for a
/// reverse swipe with a direct `.get()` instead of a query.
///
/// A `liked: true` swipe from A→B plus one from B→A is a mutual match —
/// see [MatingMatchModel]. A `liked: false` swipe ("pas geç") is recorded
/// too, purely so the same pet never resurfaces in a future deck fetch.
class MatingSwipeModel {
  final String fromPetId;
  final String fromOwnerId;
  final String toPetId;
  final String toOwnerId;
  final bool liked;
  final DateTime timestamp;

  const MatingSwipeModel({
    required this.fromPetId,
    required this.fromOwnerId,
    required this.toPetId,
    required this.toOwnerId,
    required this.liked,
    required this.timestamp,
  });

  static String docId(String fromPetId, String toPetId) =>
      '${fromPetId}_$toPetId';

  factory MatingSwipeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final timestamp = data['timestamp'];
    return MatingSwipeModel(
      fromPetId: data['fromPetId'] as String? ?? '',
      fromOwnerId: data['fromOwnerId'] as String? ?? '',
      toPetId: data['toPetId'] as String? ?? '',
      toOwnerId: data['toOwnerId'] as String? ?? '',
      liked: data['liked'] as bool? ?? false,
      timestamp: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fromPetId': fromPetId,
        'fromOwnerId': fromOwnerId,
        'toPetId': toPetId,
        'toOwnerId': toOwnerId,
        'liked': liked,
        'timestamp': FieldValue.serverTimestamp(),
      };
}
