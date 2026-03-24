import '../../models/academy_guide_model.dart';
import '../../../core/result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ACADEMY REPOSITORY INTERFACE
// ─────────────────────────────────────────────────────────────────────────────

/// Contract for fetching educational guides shown in the Pati Akademi tab.
///
/// Swap [MockAcademyRepository] for a real implementation without touching the
/// ViewModel or UI layer.
abstract class IAcademyRepository {
  /// Returns all guides. Results are ordered by category then title.
  Future<Result<List<AcademyGuideModel>>> getGuides();

  /// Returns the single guide identified by [id], or [Failure] if not found.
  Future<Result<AcademyGuideModel>> getGuideById(String id);
}
