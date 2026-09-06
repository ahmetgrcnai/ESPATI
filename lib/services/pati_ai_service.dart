import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/i_ai_service.dart';
import '../data/models/chat_message.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PATI AI SERVICE (replaces ClaudeService — Anthropic key kept failing auth,
// and pati_ai_backend's Gemini key was already verified working in
// production). Talks to pati_ai_backend's `/chat` endpoint, which owns the
// Pati-AI persona, the PDF-grounded RAG context, and (unlike the old
// Claude+PatiKnowledgeService split) the retrieval step itself — this
// service just forwards conversation turns and an optional image.
// ─────────────────────────────────────────────────────────────────────────────

// ── Image Compression Policy — ported from the deleted ClaudeService ────────
const int _kApiMaxBytes = 1536 * 1024; // 1.5 MB
const int _kApiJpegQuality = 85;
const int _kApiJpegQualityFallback = 60;
const int _kApiMaxDimension = 1024; // px on the long edge

/// Singleton AI service — communicates with `pati_ai_backend`'s `/chat`
/// endpoint over HTTP.
///
/// `PATI_BACKEND_URL`/`PATI_BACKEND_API_KEY` are loaded at runtime from the
/// `.env` file (via flutter_dotenv). `dotenv.load()` must have completed (in
/// `main()`) before this singleton is first accessed.
class PatiAiService implements IAIService {
  // ── Singleton ─────────────────────────────────────────────────────────────

  static PatiAiService? _instance;
  static PatiAiService get instance => _instance ??= PatiAiService._init();

  late final String _baseUrl;
  late final String _apiKey;

  PatiAiService._init() {
    _baseUrl = (dotenv.env['PATI_BACKEND_URL'] ?? '').trim();
    _apiKey = dotenv.env['PATI_BACKEND_API_KEY'] ?? '';
    if (!isConfigured) {
      debugPrint(
        '[PatiAiService] ⚠️ PATI_BACKEND_URL is missing from .env. '
        'Falling back to mock responses.',
      );
    } else {
      debugPrint('[PatiAiService] ✅ Initialized. Backend: $_baseUrl');
    }
  }

  @override
  bool get isConfigured => _baseUrl.isNotEmpty;

  // ── Public API (IAIService) ─────────────────────────────────────────────────

  @override
  Future<String> generateResponse(List<ChatMessage> history) async {
    if (!isConfigured) return _getMockResponse();

    final turns = _buildHistory(history);
    if (turns.isEmpty || turns.last['role'] != 'user') {
      debugPrint('[PatiAiService] ⚠️ Invalid history state — aborting API call.');
      return _buildErrorMessage('Lütfen bir soru yazın.');
    }

    return _callChat(turns);
  }

  @override
  Future<String> analyzePetIssue(
    File? imageFile,
    String prompt,
    List<ChatMessage> priorHistory,
  ) async {
    if (!isConfigured) return _getMockResponse();

    final turns = _buildHistory(priorHistory)..add({'role': 'user', 'text': prompt});

    String? imageBase64;
    if (imageFile != null) {
      try {
        final bytes = await _compressImageForApi(imageFile);
        imageBase64 = base64Encode(bytes);
      } catch (e) {
        debugPrint('[PatiAiService] ❌ Image compress error: $e');
      }
    }

    return _callChat(turns, imageBase64: imageBase64);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// POSTs the conversation (and optional image) to `/chat` and parses the
  /// response. Render's free plan spins down when idle, so a cold start can
  /// take up to ~50s — the timeout below accounts for that.
  Future<String> _callChat(
    List<Map<String, String>> turns, {
    String? imageBase64,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {
              'Content-Type': 'application/json',
              if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
            },
            body: jsonEncode({
              'history': turns,
              if (imageBase64 != null) 'image_base64': imageBase64,
              if (imageBase64 != null) 'image_mime_type': 'image/jpeg',
            }),
          )
          .timeout(const Duration(seconds: 45));

      return _parseResponse(response);
    } catch (e) {
      debugPrint('[PatiAiService] ❌ Exception: $e');
      return _buildErrorMessage(
          'Bağlantı hatası. İnternet bağlantınızı kontrol edin.');
    }
  }

  /// Converts [ChatMessage] history to the backend's `{role, text}` turns.
  ///
  /// Rules (ported from ClaudeService._buildMessages):
  ///   • The welcome message (id == 'welcome') is excluded.
  ///   • Messages with empty text are skipped.
  ///   • Consecutive messages with the same role are skipped.
  List<Map<String, String>> _buildHistory(List<ChatMessage> history) {
    final turns = <Map<String, String>>[];

    for (final msg in history) {
      if (msg.id == 'welcome') continue;
      if (msg.text.isEmpty) continue;

      final role = msg.isUser ? 'user' : 'model';

      if (turns.isNotEmpty && turns.last['role'] == role) continue;

      turns.add({'role': role, 'text': msg.text});
    }

    return turns;
  }

  /// [PREREQ-02, carried over] Compresses [source] to ≤ [_kApiMaxBytes]
  /// before API upload. Temp files are deleted immediately after their
  /// bytes are read — no residual files left on device storage.
  Future<Uint8List> _compressImageForApi(File source) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;

    File? compressed;
    try {
      final result1 = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        '${dir.path}/pati_ai_$stamp.jpg',
        quality: _kApiJpegQuality,
        minWidth: _kApiMaxDimension,
        minHeight: _kApiMaxDimension,
        format: CompressFormat.jpeg,
      );

      if (result1 != null) {
        compressed = File(result1.path);
      }

      if (compressed != null && await compressed.length() > _kApiMaxBytes) {
        final result2 = await FlutterImageCompress.compressAndGetFile(
          source.absolute.path,
          '${dir.path}/pati_ai_${stamp}_lo.jpg',
          quality: _kApiJpegQualityFallback,
          minWidth: _kApiMaxDimension,
          minHeight: _kApiMaxDimension,
          format: CompressFormat.jpeg,
        );
        if (result2 != null) {
          try {
            await compressed.delete();
          } catch (_) {}
          compressed = File(result2.path);
        }
      }

      return compressed != null
          ? await compressed.readAsBytes()
          : await source.readAsBytes();
    } finally {
      if (compressed != null) {
        try {
          await compressed.delete();
        } catch (_) {}
      }
    }
  }

  /// Extracts the reply text from a successful `/chat` response, or returns
  /// a user-facing Turkish error string for all failure cases.
  String _parseResponse(http.Response response) {
    debugPrint('[PatiAiService] HTTP ${response.statusCode}');

    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final text = data['answer'] as String?;
      debugPrint('[PatiAiService] ✅ API CALL COMPLETED');
      return text ?? _buildErrorMessage('Boş yanıt alındı.');
    }

    String errMsg = 'Bilinmeyen hata';
    try {
      final errBody = jsonDecode(utf8.decode(response.bodyBytes));
      errMsg = errBody['detail']?.toString() ?? errMsg;
    } catch (_) {}
    debugPrint('[PatiAiService] ❌ API Error ${response.statusCode}: $errMsg');

    if (response.statusCode == 401) {
      return _buildErrorMessage('Yapay zeka servisi yapılandırması hatalı.');
    }
    if (response.statusCode == 502) {
      return _buildErrorMessage(
        'Yapay zeka servisi şu anda yanıt veremiyor. Lütfen tekrar deneyin.',
      );
    }

    return _buildErrorMessage(
      'Yanıt alınamadı (${response.statusCode}). Lütfen tekrar deneyin.',
    );
  }

  String _buildErrorMessage(String detail) => '## ⚠️ Hata\n\n$detail';

  // ── Mock Responses ─────────────────────────────────────────────────────────
  // Returned when isConfigured == false (no backend URL at build time).

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
