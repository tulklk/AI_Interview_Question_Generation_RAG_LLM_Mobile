import 'package:flutter/material.dart';
import '../../domain/models/candidate_recommendation.dart';

// ── Avatar ─────────────────────────────────────────────────────────────────────

class CandidateAvatarWidget extends StatelessWidget {
  final CandidateRecommendation item;
  final double size;
  const CandidateAvatarWidget({super.key, required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    if (item.candidateAvatarUrl != null &&
        item.candidateAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(item.candidateAvatarUrl!),
        backgroundColor: const Color(0xFF6C47FF),
        onBackgroundImageError: (_, __) {},
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _avatarColors(item.candidateName),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          item.initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static List<Color> _avatarColors(String name) {
    final h = name.codeUnits.fold(0, (a, b) => a + b) % 5;
    const palettes = [
      [Color(0xFF6C47FF), Color(0xFF3B82F6)],
      [Color(0xFF10B981), Color(0xFF059669)],
      [Color(0xFFF59E0B), Color(0xFFEF4444)],
      [Color(0xFFEC4899), Color(0xFF8B5CF6)],
      [Color(0xFF14B8A6), Color(0xFF6366F1)],
    ];
    return palettes[h];
  }
}

// ── Score ring ─────────────────────────────────────────────────────────────────

class ScoreRingWidget extends StatelessWidget {
  final double score;
  final Color color;
  const ScoreRingWidget({super.key, required this.score, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 4,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${score.round()}',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '%',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

// ── Status badge ───────────────────────────────────────────────────────────────

class StatusBadgeWidget extends StatelessWidget {
  final RecommendationStatus status;
  const StatusBadgeWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 11, color: status.color),
          const SizedBox(width: 3),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}
