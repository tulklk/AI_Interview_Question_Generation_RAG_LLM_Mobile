import 'package:flutter/material.dart';
import '../../presentation/gen_colors.dart';

const _kExamples = [
  'Đề xuất câu hỏi khó hơn',
  'Đơn giản hóa câu hỏi này',
  'Thêm ví dụ thực tế',
  'Đề xuất follow-up questions',
];

class ExampleChips extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const ExampleChips({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  56,
          height: 56,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9F67FA)],
              begin:  Alignment.topLeft,
              end:    Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              size: 26, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Text(
          'Hỏi AI về câu hỏi này',
          style: TextStyle(
              color:      c.text,
              fontSize:   16,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Chọn gợi ý hoặc tự nhập câu hỏi bên dưới',
          style: TextStyle(color: c.textSub, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing:   8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _kExamples
              .map(
                (e) => GestureDetector(
                  onTap: () => onSelect(e),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: GenColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: GenColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      e,
                      style: const TextStyle(
                          color:      GenColors.primary,
                          fontSize:   13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
