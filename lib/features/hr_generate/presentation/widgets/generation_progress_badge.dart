import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../gen_colors.dart';
import '../providers/badge_provider.dart';

class GenerationProgressBadge extends ConsumerWidget {
  const GenerationProgressBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ref.watch(badgeProvider);
    if (!badge.shouldShow) return const SizedBox.shrink();

    return Positioned(
      bottom: 24,
      left:   16,
      right:  16,
      child:  _BadgeTile(badge: badge, ref: ref),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeState badge;
  final WidgetRef ref;
  const _BadgeTile({required this.badge, required this.ref});

  String get _label {
    switch (badge.currentView) {
      case 'polling':
        return badge.pollingPhase == 'plan'
            ? 'Đang tạo Plan câu hỏi...'
            : 'Đang tạo câu hỏi...';
      case 'plan_review':  return 'Plan đã sẵn sàng — Cần xem xét';
      case 'question_review': return 'Câu hỏi đã tạo xong!';
      case 'failed':       return 'Tạo câu hỏi thất bại';
      case 'draft_view':   return 'Draft đã lưu';
      default:             return 'Đang xử lý...';
    }
  }

  IconData get _icon {
    switch (badge.currentView) {
      case 'polling':        return Icons.autorenew_rounded;
      case 'plan_review':    return Icons.assignment_rounded;
      case 'question_review': return Icons.check_circle_outline_rounded;
      case 'failed':         return Icons.error_outline_rounded;
      case 'draft_view':     return Icons.bookmark_rounded;
      default:               return Icons.hourglass_top_rounded;
    }
  }

  Color get _color {
    switch (badge.currentView) {
      case 'polling':        return const Color(0xFF7C3AED);
      case 'plan_review':    return const Color(0xFF3B82F6);
      case 'question_review': return const Color(0xFF10B981);
      case 'failed':         return const Color(0xFFEF4444);
      case 'draft_view':     return const Color(0xFFF59E0B);
      default:               return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c         = GenColors.of(context);
    final isPolling = badge.currentView == 'polling';

    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child:        GestureDetector(
        onTap: () => context.go('/hr/ai-generator'),
        child: Container(
          decoration: BoxDecoration(
            color:        c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _color.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color:      _color.withValues(alpha: 0.15),
                blurRadius: 16,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child:   Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:    isPolling
                    ? SizedBox(
                        key:   const ValueKey('spin'),
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:  AlwaysStoppedAnimation<Color>(_color),
                        ),
                      )
                    : Icon(_icon,
                        key:   const ValueKey('icon'),
                        color: _color,
                        size:  22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:       MainAxisSize.min,
                  children: [
                    Text(_label,
                        style: TextStyle(
                            color:      c.text,
                            fontSize:   13,
                            fontWeight: FontWeight.w600)),
                    if (badge.session?.statusLabel != null &&
                        badge.currentView == 'polling')
                      Text(badge.session!.statusLabel!,
                          style: TextStyle(color: c.textSub, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.muted, size: 20),
              const SizedBox(width: 2),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ref.read(badgeProvider.notifier).dismiss(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child:   Icon(Icons.close_rounded, color: c.muted, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
