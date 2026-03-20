import 'package:flutter/material.dart';
import '../data/models/chat_message.dart';
import '../core/gemini_service.dart';

/// ViewModel for the AI/Vet chat screen.
///
/// Uses [GeminiService] for real AI responses (when API key is configured)
/// or falls back to mock responses automatically.
class AIVetViewModel extends ChangeNotifier {
  final GeminiService _geminiService;

  AIVetViewModel({GeminiService? geminiService})
      : _geminiService = geminiService ?? GeminiService() {
    // Start with a welcome message from the AI.
    _messages.add(ChatMessage(
      id: 'welcome',
      text:
          'Hello! 🐾 I\'m Espati AI, your pet care assistant. Ask me anything about your pet\'s health, nutrition, behavior, or training!',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  // ── State Fields ──

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Whether the AI service has a real API key configured.
  bool get isAIConfigured => _geminiService.isConfigured;

  // ── Public Methods ──

  /// Sends a user message and gets an AI response via GeminiService.
  ///
  /// Steps:
  /// 1. Adds the user's message immediately
  /// 2. Sets [isLoading] to true (shows typing indicator)
  /// 3. Calls GeminiService for a response
  /// 4. Adds the AI response
  /// 5. Sets [isLoading] to false
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _errorMessage = null;

    // 1. Add user message
    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    // 2. Show loading state (typing indicator)
    _isLoading = true;
    notifyListeners();

    try {
      // 3. Get AI response from GeminiService
      final responseText = await _geminiService.generateResponse(text.trim());

      // 4. Add AI response
      final aiMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);
    } on Exception catch (e) {
      _errorMessage = 'Failed to get AI response: ${e.toString()}';
    } finally {
      // 5. Hide loading
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the error message after the UI has displayed it.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears all messages and resets the chat with a welcome message.
  void resetChat() {
    _messages.clear();
    _messages.add(ChatMessage(
      id: 'welcome',
      text:
          'Hello! 🐾 I\'m Espati AI, your pet care assistant. Ask me anything about your pet\'s health, nutrition, behavior, or training!',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
