import 'question_suggestion.dart';

class ChatMessage {
  final String id;
  final String role;   // "ai" | "hr"
  final String content;
  final QuestionSuggestion? suggestion;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.suggestion,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j, int fallbackIndex) =>
      ChatMessage(
        id:      (j['id'] ?? j['Id'] ?? 'msg-$fallbackIndex').toString(),
        role:    (j['role'] ?? 'ai').toString(),
        content: (j['content'] ?? j['message'] ?? j['response'] ?? '').toString(),
      );
}
