import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../gen_colors.dart';
import '../providers/badge_provider.dart';

class GenerationProgressBadge extends ConsumerWidget {
  const GenerationProgressBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(
      badgeProvider.select((s) => s.shouldShow),
    );
    if (!shouldShow) return const SizedBox.shrink();

    final badge = ref.watch(badgeProvider);

    return _BadgeChip(badge: badge, ref: ref);
  }
}

class _BadgeChip extends StatelessWidget {
  final BadgeState badge;
  final WidgetRef ref;
  const _BadgeChip({required this.badge, required this.ref});

  String _label(AppLocalizations l) {
    switch (badge.currentView) {
      case 'polling':
        return badge.pollingPhase == 'plan'
            ? l.badgePollingPlan
            : l.badgePollingQuestions;
      case 'plan_review':
        return l.badgePlanReady;
      case 'question_review':
        return l.badgeQuestionsReady;
      case 'failed':
        return l.badgeFailed;
      case 'draft_view':
        return l.badgeDraftSaved;
      default:
        return l.badgeProcessing;
    }
  }

  IconData get _icon {
    switch (badge.currentView) {
      case 'polling':
        return Icons.autorenew_rounded;
      case 'plan_review':
        return Icons.assignment_rounded;
      case 'question_review':
        return Icons.check_circle_outline_rounded;
      case 'failed':
        return Icons.error_outline_rounded;
      case 'draft_view':
        return Icons.bookmark_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Color get _color {
    switch (badge.currentView) {
      case 'polling':
        return const Color(0xFF7C3AED);
      case 'plan_review':
        return const Color(0xFF3B82F6);
      case 'question_review':
        return const Color(0xFF10B981);
      case 'failed':
        return const Color(0xFFEF4444);
      case 'draft_view':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c         = GenColors.of(context);
    final l         = context.l10n;
    final isPolling = badge.currentView == 'polling';

    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      elevation:    6,
      shadowColor:  _color.withValues(alpha: 0.25),
      child:        GestureDetector(
        onTap: () {
          final jobId = badge.jobId;
          if (jobId != null && jobId.isNotEmpty) {
            context.go('/hr/generate?jobId=${Uri.encodeComponent(jobId)}');
          } else {
            context.go('/hr/generate');
          }
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            color:        c.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _color.withValues(alpha: 0.45), width: 1.5),
            boxShadow: [
              BoxShadow(
                color:      _color.withValues(alpha: 0.18),
                blurRadius: 12,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          child:   Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isPolling
                    ? SizedBox(
                        key:   const ValueKey('spin'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:  AlwaysStoppedAnimation<Color>(_color),
                        ),
                      )
                    : Icon(
                        _icon,
                        key:   const ValueKey('icon'),
                        color: _color,
                        size:  20,
                      ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _label(l),
                  style: TextStyle(
                    color:      c.text,
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ref.read(badgeProvider.notifier).dismiss(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, color: c.muted, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
