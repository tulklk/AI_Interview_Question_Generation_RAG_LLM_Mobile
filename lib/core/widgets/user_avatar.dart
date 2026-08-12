import 'package:flutter/material.dart';

/// Purple gradient avatar with initials fallback (matches web candidate app).
class UserAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool showGlowRing;
  final double fontScale;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 32,
    this.showGlowRing = false,
    this.fontScale = 0.35,
  });

  static String initialsFrom(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts =
        trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (trimmed.length >= 2) {
      return trimmed.substring(0, 2).toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  Widget _initialsCircle(String initials) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B72FF), Color(0xFF6C47FF)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * fontScale,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _innerAvatar() {
    final initials = initialsFrom(name);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsCircle(initials),
        ),
      );
    }
    return _initialsCircle(initials);
  }

  @override
  Widget build(BuildContext context) {
    if (!showGlowRing) return _innerAvatar();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: _innerAvatar(),
    );
  }
}
