import 'package:dio/dio.dart';
import '../../data/generation_api.dart';
import '../models/chat_message.dart';
import '../models/question_suggestion.dart';

class AskAiService {
  static Future<List<ChatMessage>> getChatHistory(
    String jobId,
    String questionId,
  ) async {
    try {
      final dio = buildGenerationDio();
      final res = await dio.get(
        '/api/hr/question-generation-jobs/$jobId/questions/$questionId/ai-chat',
      );
      final list = res.data as List? ?? [];
      return list.asMap().entries
          .map((e) => ChatMessage.fromJson(
              e.value as Map<String, dynamic>, e.key))
          .toList();
    } on DioException {
      return [];
    }
  }

  static Future<({String reply, QuestionSuggestion? suggestion})> sendMessage(
    String jobId,
    String questionId,
    String message,
  ) async {
    final dio = buildGenerationDio();
    final res = await dio.post(
      '/api/hr/question-generation-jobs/$jobId/questions/$questionId/ask-ai',
      data: {'message': message},
    );

    final data  = res.data;
    final inner = (data is Map && data['data'] != null) ? data['data'] : data;

    final String reply;
    if (inner is String) {
      reply = inner;
    } else if (inner is Map) {
      reply = (inner['reply']       ??
               inner['response']    ??
               inner['message']     ??
               inner['content']     ??
               inner['answer']      ??
               inner['aiResponse']  ??
               '').toString();
    } else {
      reply = '';
    }

    QuestionSuggestion? suggestion;
    if (inner is Map) {
      final raw = inner['suggestion'];
      if (raw is Map &&
          (raw['question'] ?? '').toString().trim().isNotEmpty) {
        suggestion = QuestionSuggestion.fromJson(raw as Map<String, dynamic>);
      } else if (raw is String && raw.trim().isNotEmpty) {
        suggestion = QuestionSuggestion(question: raw.trim());
      }
    }

    return (reply: reply, suggestion: suggestion);
  }
}
