import '../../../core/result.dart';
import '../../models/listing_model.dart';
import '../../models/chat_group_model.dart';
import '../../models/direct_message_model.dart';

/// Abstract interface for all data operations on the Form Hub screen.
///
/// Covers three domains: pet listings (İlanlar), community groups (Gruplar),
/// and direct message conversations (Mesajlar).
///
/// Swap [MockFormRepository] with a real implementation to connect to
/// Firestore or a REST API without touching any ViewModel or UI code.
abstract class IFormRepository {
  /// Returns all pet listings (both [ListingStatus.kayip] and
  /// [ListingStatus.sahiplendirme]) sorted by [ListingModel.createdAt] desc.
  Future<Result<List<ListingModel>>> getListings();

  /// Returns all community groups, pinned groups first.
  Future<Result<List<ChatGroupModel>>> getChatGroups();

  /// Returns all direct message conversations sorted by most recent activity.
  Future<Result<List<DirectMessageModel>>> getDirectMessages();

  /// Persists a new [listing] and returns void on success.
  ///
  /// The caller is responsible for providing a unique [ListingModel.id].
  Future<Result<void>> createListing(ListingModel listing);
}
