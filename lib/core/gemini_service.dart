import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Pati-AI system identity — sent as systemInstruction on every request.
const String _kSystemInstruction = '''
You are "Pati-AI", a Professional Veterinary Consultant and dedicated employee of ESPATI — Eskişehir's premier pet-social ecosystem.

CORE IDENTITY:
- Name: Pati-AI
- Employer: ESPATI (Eskişehir Pet-Social & AI-Assisted Ecosystem)
- Tone: Empathetic, authoritative, and helpful
- Language: Always respond in the same language as the user's message

PROFESSIONAL GUARDRAILS:
1. REFUSAL POLICY: If the user asks about ANY non-pet topic (cooking, politics, sports, general coding, relationships, etc.), respond ONLY with:
   Turkish: "Yalnızca siz ve tüylü dostlarınızla ilgili konularda yardımcı olmak için buradayım. Bugün patilinizle ilgili nasıl yardımcı olabilirim? 🐾"
   English: "I am here to assist you and your furry friends with pet-related concerns only. How can I help with your pet today?"

2. SAFETY PROTOCOL: Every response that includes medical advice or health guidance MUST end with:
   "⚠️ Bu bilgi ön rehber niteliğindedir; kesin teşhis için lütfen lisanslı bir veteriner hekime danışınız."

3. LOCALIZED KNOWLEDGE: You are an expert local guide for Eskişehir:
   - Sazova Bilim Kültür ve Sanat Parkı: large dog-friendly park, leash required
   - Kanlıkavak Parkı: popular for morning walks, dogs must be leashed
   - Porsuk Çayı riverside: scenic walking route, pet-friendly

RESPONSE FORMAT (MOBILE OPTIMIZED):
- Use Markdown: ## headings, **bold** key terms, bullet points (-)
- Short paragraphs (2-3 sentences max per section)
- Digestible sections for mobile screens
''';

/// Singleton AI service — uses the Gemini REST API directly via HTTP.
///
/// HTTP approach is used instead of the google_generative_ai SDK to avoid
/// model-name resolution issues with v1beta. The REST API accepts the exact
/// model ID string and has been confirmed working.
///
/// API key is loaded from `.env` — never hard-coded.
class GeminiService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static GeminiService? _instance;
  static GeminiService get instance => _instance ??= GeminiService._init();

  late final String _apiKey;

  GeminiService._init() {
    _apiKey = const String.fromEnvironment('GEMINI_API_KEY');
    if (_apiKey.isEmpty) {
      debugPrint('[GeminiService] ⚠️  No API key — running in mock mode.');
    } else {
      debugPrint('[GeminiService] ✅ Initialized. Model: gemini-1.5-flash');
    }
  }

  bool get isConfigured => _apiKey.isNotEmpty;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Sends [userMessage] to Gemini and returns the full response as a Future.
  Future<String> generateResponse(String userMessage) async {
    if (!isConfigured) {
      debugPrint('[GeminiService] Mock mode — returning fallback response.');
      return _getMockResponse();
    }

    debugPrint('[GeminiService] ✅ AI CALL INITIATED — "$userMessage"');

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-1.5-flash:generateContent?key=$_apiKey',
      );

      final body = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': _kSystemInstruction}
          ]
        },
        'contents': [
          {
            'parts': [
              {'text': userMessage}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': 400,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      });

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));

      debugPrint('[GeminiService] HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
            as String?;
        debugPrint('[GeminiService] ✅ AI CALL COMPLETED');
        return text ?? _buildErrorMessage('Boş yanıt alındı.');
      }

      // ── Error responses ──────────────────────────────────────────────────
      final err = jsonDecode(response.body);
      final msg = err['error']?['message'] as String? ?? 'Bilinmeyen hata';
      debugPrint('[GeminiService] ❌ API Error ${response.statusCode}: $msg');

      if (response.statusCode == 429) {
        return _buildErrorMessage(
          'Günlük istek limitine ulaşıldı. Lütfen birkaç dakika bekleyin '
          'veya yarın tekrar deneyin.',
        );
      }
      return _getMockResponse();
    } catch (e) {
      debugPrint('[GeminiService] ❌ Exception: $e');
      return _buildErrorMessage(
          'Bağlantı hatası. İnternet bağlantınızı kontrol edin.');
    }
  }

  String _buildErrorMessage(String detail) =>
      '## ⚠️ Hata\n\n$detail';

  // ── Mock Responses ─────────────────────────────────────────────────────────

  static const _mockResponses = [
    '## Genel Sağlık Önerileri\n\nEvcil hayvanınızın sağlığı için dengeli beslenme ve düzenli egzersiz en temel gereksinimlerdir.\n\n- Temiz su her zaman erişilebilir olmalı\n- Yaşa uygun kaliteli mama tercih edin\n- Sazova veya Kanlıkavak\'ta günlük yürüyüşler yapın\n\n⚠️ Bu bilgi ön rehber niteliğindedir; kesin teşhis için lütfen lisanslı bir veteriner hekime danışınız.',
    '## Beslenme Rehberi\n\nDoğru beslenme patilinizin uzun ve sağlıklı bir yaşam sürmesi için kritiktir.\n\n- **Köpekler:** Irk, yaş ve aktivite düzeyine uygun mama seçin\n- **Kediler:** Yüksek proteinli, tahılsız mamalar tercih edilebilir\n\n⚠️ Bu bilgi ön rehber niteliğindedir; kesin teşhis için lütfen lisanslı bir veteriner hekime danışınız.',
    '## Eskişehir\'de Evcil Hayvan Dostu Mekanlar\n\n**Sazova Parkı:** Geniş yeşil alan, tasma zorunlu\n**Kanlıkavak Parkı:** Sabah yürüyüşleri için ideal\n**Porsuk Kenarı:** Manzaralı yürüyüş güzergahı\n\nTüm alanlarda dışkı torbası bulundurmayı unutmayın! 🐾',
  ];

  static int _mockIndex = 0;
  String _getMockResponse() {
    final r = _mockResponses[_mockIndex % _mockResponses.length];
    _mockIndex++;
    return r;
  }
}
