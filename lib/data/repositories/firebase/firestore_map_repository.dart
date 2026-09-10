import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/result.dart';
import '../../models/map_point.dart';
import '../interfaces/i_map_repository.dart';

/// Firestore implementation of [IMapRepository].
///
/// Reads from the top-level `places` collection.
/// Each document must contain the fields defined in [MapPoint.fromJson].
class FirestoreMapRepository implements IMapRepository {
  final FirebaseFirestore _firestore;
  static const _kPlaces = 'places';

  FirestoreMapRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<List<MapPoint>>> getMapPoints() async {
    try {
      final snapshot = await _firestore.collection(_kPlaces).get();
      final points = snapshot.docs
          .map((doc) => MapPoint.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
      return Success(points);
    } on Exception catch (e) {
      return Failure('Harita noktaları yüklenemedi', exception: e);
    }
  }

  @override
  Future<Result<List<MapPoint>>> getMapPointsByCategory(
      MapPointCategory category) async {
    try {
      final snapshot = await _firestore
          .collection(_kPlaces)
          .where('category', isEqualTo: category.name)
          .get();
      final points = snapshot.docs
          .map((doc) => MapPoint.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
      return Success(points);
    } on Exception catch (e) {
      return Failure('Harita noktaları yüklenemedi', exception: e);
    }
  }
}
