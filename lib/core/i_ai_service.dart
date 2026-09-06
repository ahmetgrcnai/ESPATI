import 'dart:io';

import '../data/models/chat_message.dart';

/// Abstract contract for the ESPATI AI backend.
///
/// Both methods accept conversation history so every request carries full
/// session context — enabling multi-turn diagnostic conversations.
abstract interface class IAIService {
  bool get isConfigured;

  /// Sends the full conversation [history] to the AI for a text-only reply.
  ///
  /// The last message in [history] must be a user turn ([ChatMessage.isUser]
  /// == true). The service builds the Gemini `contents` array from the list,
  /// so the model remembers every prior exchange within the session.
  Future<String> generateResponse(List<ChatMessage> history);

  /// Sends prior conversation context plus a compressed image to the AI.
  ///
  /// [imageFile] is the image for the **current** request; it is compressed
  /// by the service before base64 encoding (PREREQ-02).
  /// [prompt] is the text query accompanying the image.
  /// [priorHistory] is the conversation **before** the current user turn —
  /// the service appends the image turn internally so the image bytes are not
  /// duplicated in the message list.
  Future<String> analyzePetIssue(
    File? imageFile,
    String prompt,
    List<ChatMessage> priorHistory,
  );
}
