import 'package:flutter/material.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/question_type.dart';
import '../../domain/models/generated_question.dart';
import '../../presentation/gen_colors.dart';
import '../models/question_suggestion.dart';

class SuggestionCard extends StatelessWidget {
  final QuestionSuggestion suggestion;
  final GeneratedQuestion original;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.original,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    final questionType = suggestion.questionType?.trim().isNotEmpty == true
        ? HrQuestionType.fromString(suggestion.questionType!)
        : original.questionType;
    final difficulty = suggestion.difficulty?.trim().isNotEmpty == true
        ? HrDifficultyLevel.fromString(suggestion.difficulty)
        : original.difficulty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GenColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: GenColors.primary.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 15, color: GenColors.primary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Đề xuất cải tiến',
                    style: TextStyle(
                        color:      GenColors.primary,
                        fontSize:   13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                GestureDetector(
                  onTap:  onDismiss,
                  child:  Icon(Icons.close_rounded, color: c.muted, size: 18),
                ),
              ],
            ),
          ),

          // Suggested question text
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              suggestion.question,
              style: TextStyle(
                  color:      c.text,
                  fontSize:   14,
                  height:     1.5,
                  fontWeight: FontWeight.w500),
            ),
          ),

          // Type & difficulty badges
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                _Badge(
                    label: questionType.displayName,
                    color: GenColors.primary),
                const SizedBox(width: 6),
                _Badge(
                    label: difficulty.displayName,
                    color: difficulty.badgeColor),
              ],
            ),
          ),

          // Apply button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width:  double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onApply,
                icon:  const Icon(Icons.check_rounded, size: 16),
                label: const Text('Áp dụng',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GenColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color:      color,
              fontSize:   11,
              fontWeight: FontWeight.w600)),
    );
  }
}
