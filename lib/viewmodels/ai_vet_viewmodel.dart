import 'dart:io';

import 'package:flutter/foundation.dart';
import '../data/models/chat_message.dart';
import '../data/models/academy_guide_model.dart';
import '../data/repositories/interfaces/i_academy_repository.dart';
import '../core/i_ai_service.dart';
import '../services/pati_ai_service.dart';
import '../core/result.dart';

/// ViewModel for the AI/Vet chat screen.
///
/// Uses [PatiAiService.instance] singleton, which talks to pati_ai_backend's
/// `/chat` endpoint (Gemini, PDF-grounded RAG, optional image). Replaces the
/// former ClaudeService + PatiKnowledgeService split after the Anthropic key
/// stopped authenticating. The HTTP client is created exactly once for the
/// app lifetime.
///
/// Also owns the Pati Akademi state (guide list, category filter, search query).
class AIVetViewModel extends ChangeNotifier {
  final IAIService _aiService;
  final IAcademyRepository _academyRepository;

  AIVetViewModel({
    IAIService? aiService,
    required IAcademyRepository academyRepository,
  })  : _aiService = aiService ?? PatiAiService.instance,
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

  bool get isAIConfigured => _aiService.isConfigured;

  // ── Pending Image State ────────────────────────────────────────────────────

  File? _pendingImageFile;
  Uint8List? _pendingImageBytes;

  File? get pendingImageFile => _pendingImageFile;
  Uint8List? get pendingImageBytes => _pendingImageBytes;
  bool get hasPendingImage => _pendingImageFile != null;

  Future<void> setPendingImage(File file) async {
    _pendingImageFile = file;
    _pendingImageBytes = await file.readAsBytes();
    notifyListeners();
  }

  void clearPendingImage() {
    _pendingImageFile = null;
    _pendingImageBytes = null;
    notifyListeners();
  }

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

  /// Sends a user message (with optional pending image) and awaits the AI response.
  ///
  /// Text-only messages send the **full conversation history** (via
  /// [IAIService.generateResponse]) — pati_ai_backend's `/chat` endpoint
  /// accepts multi-turn history natively and does its own PDF-grounded
  /// retrieval, so there's no separate knowledge-service call to make here
  /// anymore.
  ///
  /// For image messages, [priorHistory] (the conversation snapshot taken before
  /// the current user turn was appended) is passed to
  /// [IAIService.analyzePetIssue] — the service appends the current text +
  /// image turn itself, preventing duplicate entries.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && !hasPendingImage) return;
    if (_isProcessing) {
      debugPrint('[AIVetViewModel] Blocked — already processing.');
      return;
    }

    _errorMessage = null;

    // Snapshot and clear pending image before the first await.
    final imageFile = _pendingImageFile;
    final imageBytes = _pendingImageBytes;
    _pendingImageFile = null;
    _pendingImageBytes = null;

    // [PREREQ-01] Capture the conversation history BEFORE appending the current
    // user message. This snapshot is passed to analyzePetIssue so the service
    // receives prior context only — it builds the image turn from the File itself.
    final priorHistory = List<ChatMessage>.unmodifiable(_messages);

    _messages.add(ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed.isEmpty ? '📷 Fotoğraf gönderildi' : trimmed,
      isUser: true,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
    ));

    _isProcessing = true;
    notifyListeners();

    try {
      final String responseText;
      if (imageFile != null) {
        // Multimodal path: prior context + compressed image + text prompt.
        // The service handles compression (PREREQ-02) and appends the image
        // turn to the request internally.
        responseText = await _aiService.analyzePetIssue(
          imageFile,
          trimmed.isEmpty
              ? 'Bu evcil hayvan fotoğrafını incele ve genel sağlık durumu hakkında bilgi ver.'
              : trimmed,
          priorHistory,
        );
      } else {
        // Text-only path: full history (including the just-appended user
        // turn) so the backend keeps multi-turn memory.
        responseText = await _aiService.generateResponse(_messages);
      }

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
    _pendingImageFile = null;
    _pendingImageBytes = null;
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
