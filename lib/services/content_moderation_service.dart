import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT MODERATION SERVICE (Phase 4 Step 12/13 — CTO safety mandate, Madde 8)
//
// Client-side gate that every content-creation flow (listing / post) must
// run text through before a document is ever written to Firestore. This is
// deliberately a static, near-dependency-free utility — no Firebase, no
// widget/BuildContext coupling — so it can be called synchronously inside
// form validation, the same place [ListingFormScreen] already validates
// required fields and image count.
//
// [containsInappropriateText] is a basic denylist match — good enough to
// reject obvious abuse today, not a real profanity/NLP classifier.
//
// [isImageNSFW] (Step 13) is now a real Google Cloud Vision SafeSearch call
// — the framework Step 12 stubbed out is wired to the actual backend here.
// ─────────────────────────────────────────────────────────────────────────────

class ContentModerationService {
  ContentModerationService._();

  /// Google Cloud Vision API key — loaded from the git-ignored `.env` file
  /// via [dotenv] (`VISION_API_KEY`), same mechanism as
  /// [ClaudeService]'s `ANTHROPIC_API_KEY`. Never hardcode a real key here;
  /// `dotenv.load()` must have completed in `main()` before this is read.
  static String get _visionApiKey => dotenv.env['VISION_API_KEY'] ?? '';

  static const String _visionEndpoint =
      'https://vision.googleapis.com/v1/images:annotate';

  /// Dummy denylist — placeholders for a real Turkish/English profanity
  /// list. Matched case-insensitively as whole words so legitimate text
  /// that merely contains a banned substring inside a longer word isn't
  /// falsely flagged.
  static const List<String> _bannedWords = [
    // English placeholders
    'badword1',
    'badword2',
    // Turkish placeholders
    'küfür1',
    'küfür2',
  ];

  /// Returns `true` if [text] contains any word from [_bannedWords].
  ///
  /// Whole-word match on a lowercased, diacritic-preserving comparison —
  /// e.g. "küfür2" matches "Bu bir küfür2 içerir" but not "küfür20lu".
  static bool containsInappropriateText(String text) {
    if (text.trim().isEmpty) return false;

    final lower = text.toLowerCase();
    for (final banned in _bannedWords) {
      final pattern = RegExp(r'\b' + RegExp.escape(banned) + r'\b');
      if (pattern.hasMatch(lower)) return true;
    }
    return false;
  }

  /// Likelihood values Cloud Vision considers a positive detection —
  /// anything below `POSSIBLE` (`VERY_UNLIKELY`, `UNLIKELY`) or `UNKNOWN`
  /// is treated as safe for that category.
  static const Set<String> _flaggedLikelihoods = {'LIKELY', 'VERY_LIKELY'};

  /// Runs [imagePath] (a local file path) through Google Cloud Vision's
  /// SAFE_SEARCH_DETECTION feature and returns `true` if the image is
  /// inappropriate/NSFW.
  ///
  /// The file is read and base64-encoded internally — callers just pass the
  /// local path (e.g. the compressed file already produced by
  /// [CreatePostViewModel]'s upload pipeline before it's handed to Storage).
  ///
  /// **Strict safety evaluation**: flags the image (`true`) if ANY of
  /// `adult`, `violence`, `racy`, or `medical` comes back `LIKELY` or
  /// `VERY_LIKELY`. `spoof` is intentionally not checked — it detects
  /// memes/edited photos, not unsafe content, and would false-positive on
  /// harmless pet meme posts.
  ///
  /// **Error handling**: any failure (network error, invalid/missing API
  /// key, malformed response) is caught, logged, and defaults to `false`
  /// (safe) — a moderation outage must never brick content creation for
  /// every user. This is a deliberate availability-over-strictness
  /// trade-off; flip the catch-block return to `true` instead if the
  /// product decision is "fail closed" (block uploads) during an outage.
  static Future<bool> isImageNSFW(String imagePath) async {
    final apiKey = _visionApiKey;
    if (apiKey.isEmpty) {
      debugPrint(
        '[ContentModerationService] VISION_API_KEY is missing from .env — '
        'skipping image moderation (fail-open).',
      );
      return false;
    }

    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse('$_visionEndpoint?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'requests': [
                {
                  'image': {'content': base64Image},
                  'features': [
                    {'type': 'SAFE_SEARCH_DETECTION'},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint(
          '[ContentModerationService] Vision API returned '
          '${response.statusCode}: ${response.body}',
        );
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final responses = decoded['responses'] as List<dynamic>?;
      if (responses == null || responses.isEmpty) return false;

      final firstResponse = responses.first as Map<String, dynamic>;

      // Vision reports a per-request `error` object instead of throwing an
      // HTTP error status for some failures (e.g. unreadable image) —
      // treat that the same as a transport failure.
      if (firstResponse.containsKey('error')) {
        debugPrint(
          '[ContentModerationService] Vision API request error: '
          '${firstResponse['error']}',
        );
        return false;
      }

      final annotation =
          firstResponse['safeSearchAnnotation'] as Map<String, dynamic>?;
      if (annotation == null) return false;

      for (final category in ['adult', 'violence', 'racy', 'medical']) {
        final likelihood = annotation[category] as String?;
        if (likelihood != null && _flaggedLikelihoods.contains(likelihood)) {
          return true;
        }
      }
      return false;
    } catch (e, stack) {
      debugPrint('[ContentModerationService] isImageNSFW failed: $e\n$stack');
      return false;
    }
  }
}
