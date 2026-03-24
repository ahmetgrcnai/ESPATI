import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/models/chat_message.dart';
import '../data/models/academy_guide_model.dart';
import '../data/repositories/interfaces/i_academy_repository.dart';
import '../core/gemini_service.dart';
import '../core/result.dart';

/// ViewModel for the AI/Vet chat screen.
///
/// Uses [GeminiService.instance] singleton. The [GenerativeModel] (HTTP client)
/// is created exactly once for the app lifetime.
///
/// Also owns the Pati Akademi state (guide list, category filter, search query).
class AIVetViewModel extends ChangeNotifier {
  final GeminiService _geminiService;
  final IAcademyRepository _academyRepository;

  AIVetViewModel({
    GeminiService? geminiService,
    required IAcademyRepository academyRepository,
  })  : _geminiService = geminiService ?? GeminiService.instance,
        _academyRepository = academyRepository {
    _messages.add(ChatMessage(
      id: 'welcome',
      text: '## Merhaba! 🐾\n\nBen **Pati-AI**, ESPATI\'nin uzman veteriner '
          'danışmanınım.\n\nSize ve tüylü dostlarınıza şu konularda yardımcı '
          'olabilirim:\n- 🏥 Sağlık & semptom rehberliği\n- 🍽️ Beslenme & '
          'diyet önerileri\n- 🗺️ Eskişehir\'deki evcil hayvan dostu mekanlar'
          '\n- 🐾 Davranış & eğitim ipuçları\n\nBugün patiliniz için ne '
          'öğrenmek istersiniz?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  // ── Chat State ─────────────────────────────────────────────────────────────

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  bool get isLoading => _isProcessing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAIConfigured => _geminiService.isConfigured;

  // ── Academy State ──────────────────────────────────────────────────────────

  List<AcademyGuideModel> _allGuides = [];
  bool _isLoadingGuides = false;
  bool get isLoadingGuides => _isLoadingGuides;

  String _selectedCategory = AcademyCategory.tumu;
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// Guides filtered by active category and search query.
  List<AcademyGuideModel> get filteredGuides {
    var guides = _allGuides;

    if (_selectedCategory != AcademyCategory.tumu) {
      guides = guides
          .where((g) => g.category == _selectedCategory)
          .toList(growable: false);
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      guides = guides
          .where((g) =>
              g.title.toLowerCase().contains(q) ||
              g.summary.toLowerCase().contains(q))
          .toList(growable: false);
    }

    return guides;
  }

  // ── Academy Public Methods ─────────────────────────────────────────────────

  /// Fetches guides from the repository. No-ops if already loaded.
  Future<void> loadGuides({bool forceRefresh = false}) async {
    if (_allGuides.isNotEmpty && !forceRefresh) return;

    _isLoadingGuides = true;
    notifyListeners();

    final result = await _academyRepository.getGuides();
    switch (result) {
      case Success(:final data):
        _allGuides = data;
      case Failure(:final message):
        debugPrint('[AIVetViewModel] loadGuides error: $message');
    }

    _isLoadingGuides = false;
    notifyListeners();
  }

  void setAcademyCategory(String categoryId) {
    if (_selectedCategory == categoryId) return;
    _selectedCategory = categoryId;
    notifyListeners();
  }

  void setAcademySearch(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  // ── Chat Public Methods ────────────────────────────────────────────────────

  /// Sends a user message and awaits the AI response.
  ///
  /// Double-guarded against concurrent calls:
  ///   1. [_isProcessing] set synchronously before first await
  ///   2. UI Send button disabled via [isProcessing]
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isProcessing) {
      debugPrint('[AIVetViewModel] Blocked — already processing.');
      return;
    }

    _errorMessage = null;

    _messages.add(ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _isProcessing = true;
    notifyListeners();

    try {
      final responseText =
          await _geminiService.generateResponse(text.trim());

      _messages.add(ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _errorMessage = 'Yanıt alınamadı. İnternet bağlantınızı kontrol edin.';
      debugPrint('[AIVetViewModel] Error: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetChat() {
    _messages.clear();
    _isProcessing = false;
    _errorMessage = null;
    _messages.add(ChatMessage(
      id: 'welcome',
      text: '## Merhaba! 🐾\n\nBen **Pati-AI**, ESPATI\'nin uzman veteriner '
          'danışmanınım.\n\nSize ve tüylü dostlarınıza şu konularda yardımcı '
          'olabilirim:\n- 🏥 Sağlık & semptom rehberliği\n- 🍽️ Beslenme & '
          'diyet önerileri\n- 🗺️ Eskişehir\'deki evcil hayvan dostu mekanlar'
          '\n- 🐾 Davranış & eğitim ipuçları\n\nBugün patiliniz için ne '
          'öğrenmek istersiniz?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
