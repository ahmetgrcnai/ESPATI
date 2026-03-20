import '../../../core/result.dart';
import '../../models/map_point.dart';

/// Abstract interface for map-related data operations.
///
/// Implementations can fetch from local mock data, REST API, or Firebase.
abstract class IMapRepository {
  /// Fetches all pet-friendly map points in Eskişehir.
  Future<Result<List<MapPoint>>> getMapPoints();

  /// Fetches map points filtered by [category].
  Future<Result<List<MapPoint>>> getMapPointsByCategory(
      MapPointCategory category);
}
