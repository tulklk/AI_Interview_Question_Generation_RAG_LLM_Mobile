import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../gen_colors.dart';

int viewToStep(String view, String pollingPhase) {
  switch (view) {
    case 'form':          return 1;
    case 'polling':       return pollingPhase == 'plan' ? 2 : 4;
    case 'plan_review':   return 3;
    case 'question_review':
    case 'draft_view':    return 5;
    default:              return 2;
  }
}

class StepIndicator extends StatelessWidget {
  final int currentStep;
  const StepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final c      = GenColors.of(context);
    final labels = context.l10n.stepLabels;

    return Container(
      color:   c.bg,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftStep = (i ~/ 2) + 1;
            final done     = currentStep > leftStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  gradient: done
                      ? const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF6C47FF)])
                      : null,
                  color:        done ? null : c.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final step   = (i ~/ 2) + 1;
          final done   = currentStep > step;
          final active = currentStep == step;
          return _StepDot(
            step:   step,
            label:  labels[step - 1],
            done:   done,
            active: active,
            c:      c,
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int    step;
  final String label;
  final bool   done;
  final bool   active;
  final GenColors c;

  const _StepDot({
    required this.step,
    required this.label,
    required this.done,
    required this.active,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor = done
        ? const Color(0xFF10B981)
        : active
            ? GenColors.primary
            : c.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width:  active ? 28 : 22,
          height: active ? 28 : 22,
          decoration: BoxDecoration(
            color:  dotColor,
            shape:  BoxShape.circle,
            boxShadow: active
                ? [BoxShadow(
                    color:      GenColors.primary.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1)]
                : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : Text(
                    '$step',
                    style: TextStyle(
                      color:      active ? Colors.white : c.muted,
                      fontSize:   active ? 11 : 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color:      active
                ? c.text
                : done
                    ? const Color(0xFF10B981)
                    : c.muted,
            fontSize:   9,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
