import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service for interacting with the Google Gemini (Generative AI) API.
///
/// ## Secure API Key Storage
///
/// The API key is loaded from the `.env` file via `flutter_dotenv`:
///
/// ```
/// # .env (project root — add to .gitignore!)
/// GEMINI_API_KEY=your_key_here
/// ```
///
/// Make sure to:
/// 1. Add `.env` to `.gitignore`
/// 2. Add `.env` to `pubspec.yaml` assets
/// 3. Call `await dotenv.load()` in `main()` before `runApp()`
class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  /// API key loaded from .env file via flutter_dotenv.
  late final String _apiKey;

  GeminiService() {
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// Whether the service has a valid API key configured.
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Sends a prompt to Gemini and returns the AI response text.
  ///
  /// The prompt is automatically wrapped with a pet-care context
  /// so the AI responds as a friendly veterinary assistant.
  Future<String> generateResponse(String userMessage) async {
    if (!isConfigured) {
      return _getMockResponse(userMessage);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': _buildPrompt(userMessage),
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 512,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String? ?? 'No response received.';
          }
        }
        return 'I could not generate a response. Please try again.';
      } else {
        return _getMockResponse(userMessage);
      }
    } on Exception {
      return _getMockResponse(userMessage);
    }
  }

  /// Constructs a system-prompted request for pet care assistance.
  String _buildPrompt(String userMessage) {
    return '''You are "Espati AI", a friendly, knowledgeable veterinary assistant for a pet social media app based in Eskişehir, Turkey. 

Your role:
- Answer questions about pet health, nutrition, behavior, and training
- Be warm, empathetic, and use occasional pet emojis 🐾🐶🐱
- If a question is about a serious medical condition, always recommend visiting a real veterinarian
- Keep responses concise (2-4 paragraphs max)
- Respond in the same language as the user's message

User's question: $userMessage''';
  }

  /// Fallback mock responses when API key is not configured or API fails.
  static const _mockResponses = [
    'Great question! 🐾 Based on my knowledge, maintaining a balanced diet and regular exercise is key for pet health. I\'d recommend consulting with your local vet in Eskişehir for a personalized answer. 🐶',
    'That\'s a common concern among pet owners! Here are some tips: ensure fresh water is always available, keep a consistent feeding schedule, and provide plenty of enrichment activities. 🐱',
    'I understand your concern! ❤️ While I can provide general guidance, for serious symptoms please visit a veterinary clinic as soon as possible. Your pet\'s health comes first!',
    'Interesting question! 🍽️ Pet nutrition is crucial — the key is finding a high-quality food appropriate for your pet\'s age, breed, and activity level.',
    'Regular check-ups are the best way to stay on top of your pet\'s health. 🏥 I recommend visiting your vet at least once a year for routine wellness exams.',
  ];

  static int _mockIndex = 0;

  String _getMockResponse(String userMessage) {
    final response = _mockResponses[_mockIndex % _mockResponses.length];
    _mockIndex++;
    return response;
  }
}
