import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Returns a small tech-stack icon widget for a given skill name.
/// Falls back to `null` when no mapping is found.
Widget? skillIcon(String skill) {
  final s = skill.toLowerCase().trim();

  Widget badge(String text, Color bg, Color fg) {
    final fontSize = text.length > 3
        ? 5.5
        : text.length > 2
            ? 6.0
            : 7.5;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          height: 1,
        ),
      ),
    );
  }

  Widget emoji(String e) => Text(e, style: const TextStyle(fontSize: 13));

  Widget matIcon(IconData icon, {Color color = Colors.white, double size = 14}) =>
      Icon(icon, size: size, color: color);

  // ── Specific Unity / game keywords FIRST (before broad rules) ─────────────
  if (s.contains('scriptableobject') || s.contains('scriptable object')) {
    return matIcon(Icons.description_outlined, color: const Color(0xFFE5E7EB));
  }
  if (s.contains('object pooling') || s.contains('object pool')) {
    return matIcon(Icons.layers_rounded, color: const Color(0xFFE5E7EB));
  }
  if (s.contains('ui system') || s.contains('canvas')) {
    return matIcon(Icons.desktop_windows_rounded, color: const Color(0xFFE5E7EB));
  }
  if (s.contains('particle')) {
    return matIcon(Icons.auto_awesome, color: const Color(0xFFFBBF24));
  }
  if (s.contains('state machine')) {
    return matIcon(Icons.account_tree_rounded, color: const Color(0xFFE5E7EB));
  }
  if (s.contains('navmesh') || s.contains('nav mesh')) {
    return matIcon(Icons.near_me_rounded, color: const Color(0xFFE5E7EB));
  }
  if (s.contains('cinemachine')) {
    return matIcon(Icons.videocam_rounded, color: const Color(0xFFE5E7EB));
  }
  if (s.contains('animation') && !s.contains('css')) {
    return matIcon(Icons.play_circle_outline_rounded,
        color: const Color(0xFFE5E7EB));
  }
  if (s.contains('design pattern')) {
    return matIcon(Icons.layers_rounded, color: const Color(0xFFE5E7EB));
  }
  if (s.contains('clean code')) {
    return matIcon(Icons.code_rounded, color: const Color(0xFF34D399));
  }
  if (s.contains('performance') ||
      s.contains('optimization') ||
      s.contains('optimis')) {
    return matIcon(Icons.bolt_rounded, color: const Color(0xFFFBBF24));
  }
  if (s.contains('firestone') ||
      s.contains('firestore') ||
      s.contains('fireauth') ||
      s.contains('fire auth')) {
    return matIcon(Icons.local_fire_department_rounded,
        color: const Color(0xFFFFA000));
  }

  // ── Architecture / Patterns ───────────────────────────────────────────────
  if (s.contains('jwt') || s.contains('json web token')) {
    return badge('JWT', const Color(0xFF6C47FF), Colors.white);
  }
  if (s.contains('oop') ||
      s.contains('object-oriented') ||
      s.contains('object oriented')) {
    return matIcon(Icons.code_rounded, color: const Color(0xFF34D399));
  }
  if (s.contains('solid')) {
    return badge('SOL', const Color(0xFF6C47FF), Colors.white);
  }
  if (s.contains('microservice')) {
    return badge('μS', const Color(0xFF6C47FF), Colors.white);
  }

  // ── Game / Mobile engines ─────────────────────────────────────────────────
  if (s.contains('unity')) {
    return badge('U', const Color(0xFF222C37), Colors.white);
  }
  if (s.contains('unreal')) {
    return badge('UE', const Color(0xFF0E0E0E), Colors.white);
  }

  // ── Web Frontend ──────────────────────────────────────────────────────────
  if (s.contains('react') && !s.contains('react native')) {
    return badge('⚛', const Color(0xFF61DAFB), const Color(0xFF20232A));
  }
  if (s.contains('vue')) return emoji('💚');
  if (s.contains('angular')) {
    return badge('A', const Color(0xFFDD1B16), Colors.white);
  }
  if (s.contains('svelte')) {
    return badge('S', const Color(0xFFFF3E00), Colors.white);
  }
  if (s.contains('typescript') || s == 'ts') {
    return badge('TS', const Color(0xFF3178C6), Colors.white);
  }
  if (s.contains('javascript') || s == 'js') {
    return badge('JS', const Color(0xFFF7DF1E), Colors.black87);
  }
  if (s.contains('next.js') || (s.contains('next') && s.contains('js'))) {
    return badge('N', Colors.black, Colors.white);
  }
  if (s.contains('nuxt')) {
    return badge('N', const Color(0xFF00DC82), Colors.black87);
  }
  if (s.contains('html')) {
    return badge('H5', const Color(0xFFE34F26), Colors.white);
  }
  if (s.contains('css')) {
    return badge('CSS', const Color(0xFF1572B6), Colors.white);
  }
  if (s.contains('tailwind')) {
    return badge('TW', const Color(0xFF06B6D4), Colors.white);
  }
  if (s.contains('bootstrap')) {
    return badge('B', const Color(0xFF7952B3), Colors.white);
  }

  // ── Backend / Languages ───────────────────────────────────────────────────
  if (s.contains('python')) return emoji('🐍');
  if ((s.contains('java') || s == 'java') &&
      !s.contains('javascript') &&
      !s.contains('typescript')) {
    return badge('Jv', const Color(0xFFED8B00), Colors.white);
  }
  if (s == 'c#' ||
      s.contains('csharp') ||
      s.contains('c sharp') ||
      s.contains('.net c#') ||
      s.endsWith(' c#') ||
      s.contains('c# ')) {
    return badge('C#', const Color(0xFF9B4FEA), Colors.white);
  }
  if (s.contains('ef core') || s.contains('entity framework')) {
    return badge('EF', const Color(0xFF512BD4), Colors.white);
  }
  if (s.contains('asp.net')) {
    return badge('NET', const Color(0xFF512BD4), Colors.white);
  }
  if (s == '.net' ||
      s.contains('.net') ||
      s.contains('dotnet') ||
      s.contains('dot net')) {
    return badge('NET', const Color(0xFF512BD4), Colors.white);
  }
  if (s.contains('php')) return emoji('🐘');
  if (s.contains('ruby')) return emoji('💎');
  if (s == 'go' || s.contains('golang')) {
    return badge('Go', const Color(0xFF00ADD8), Colors.white);
  }
  if (s.contains('rust')) return emoji('🦀');
  if (s.contains('swift')) return emoji('🦅');
  if (s.contains('kotlin')) {
    return badge('K', const Color(0xFF7F52FF), Colors.white);
  }
  if (s.contains('scala')) {
    return badge('Sc', const Color(0xFFDC322F), Colors.white);
  }
  if (s.contains('c++') || s == 'cpp') {
    return badge('C++', const Color(0xFF004482), Colors.white);
  }
  if (s.contains('c lang') || s == 'c') {
    return badge('C', const Color(0xFF283593), Colors.white);
  }

  // ── Backend Frameworks ────────────────────────────────────────────────────
  if (s.contains('node') || s.contains('express')) {
    return badge('Node', const Color(0xFF339933), Colors.white);
  }
  if (s.contains('django')) {
    return badge('Dj', const Color(0xFF0C4B33), Colors.white);
  }
  if (s.contains('flask')) return badge('Fl', Colors.black87, Colors.white);
  if (s.contains('fastapi')) {
    return badge('FA', const Color(0xFF009688), Colors.white);
  }
  if (s.contains('spring')) {
    return badge('Sp', const Color(0xFF6DB33F), Colors.white);
  }
  if (s.contains('laravel')) {
    return badge('L', const Color(0xFFFF2D20), Colors.white);
  }
  if (s.contains('nestjs') || s.contains('nest.js')) {
    return badge('N', const Color(0xFFE0234E), Colors.white);
  }
  if (s.contains('rails') || s.contains('ruby on rails')) {
    return badge('R', const Color(0xFFCC0000), Colors.white);
  }

  // ── Database ──────────────────────────────────────────────────────────────
  if (s.contains('mysql')) {
    return badge('My', const Color(0xFF4479A1), Colors.white);
  }
  if (s.contains('postgres')) {
    return badge('Pg', const Color(0xFF336791), Colors.white);
  }
  if (s.contains('sql server') || s.contains('mssql')) {
    return badge('SQL', const Color(0xFFCC2927), Colors.white);
  }
  if (s.contains('sqlite')) {
    return badge('Sq', const Color(0xFF003B57), Colors.white);
  }
  if (s == 'sql' || (s.contains('sql') && !s.contains('nosql'))) {
    return matIcon(Icons.storage_rounded, color: const Color(0xFF9CA3AF));
  }
  if (s.contains('mongodb') || s.contains('mongo')) {
    return badge('MDB', const Color(0xFF47A248), Colors.white);
  }
  if (s.contains('redis')) {
    return badge('R', const Color(0xFFDC382D), Colors.white);
  }
  if (s.contains('firebase')) {
    return matIcon(Icons.local_fire_department_rounded,
        color: const Color(0xFFFFA000));
  }
  if (s.contains('supabase')) {
    return badge('Su', const Color(0xFF3ECF8E), Colors.black87);
  }
  if (s.contains('elasticsearch') || s.contains('elastic')) {
    return badge('ES', const Color(0xFFFEC514), Colors.black87);
  }
  if (s.contains('cassandra')) {
    return badge('C', const Color(0xFF1287B1), Colors.white);
  }
  if (s.contains('dynamodb') || s.contains('dynamo')) {
    return badge('Dy', const Color(0xFF4053D6), Colors.white);
  }

  // ── DevOps / Cloud ────────────────────────────────────────────────────────
  if (s.contains('docker')) return emoji('🐳');
  if (s.contains('kubernetes') || s == 'k8s') {
    return Text('☸',
        style: const TextStyle(fontSize: 14, color: Color(0xFF326CE5)));
  }
  if (s.contains('aws')) {
    return badge('AWS', const Color(0xFFFF9900), Colors.black87);
  }
  if (s.contains('azure')) {
    return badge('Az', const Color(0xFF0078D4), Colors.white);
  }
  if (s.contains('gcp') || s.contains('google cloud')) {
    return badge('GC', const Color(0xFF4285F4), Colors.white);
  }
  if (s.contains('terraform')) {
    return badge('Tf', const Color(0xFF623CE4), Colors.white);
  }
  if (s.contains('ansible')) {
    return badge('An', const Color(0xFFEE0000), Colors.white);
  }
  if (s.contains('jenkins')) {
    return badge('J', const Color(0xFFD33833), Colors.white);
  }
  if (s.contains('github actions') ||
      (s.contains('github') && s.contains('action'))) {
    return badge('GHA', Colors.black, Colors.white);
  }
  if (s.contains('github')) {
    return badge('GH', Colors.black87, Colors.white);
  }
  if (s.contains('gitlab')) {
    return badge('GL', const Color(0xFFFC6D26), Colors.white);
  }
  if (s.contains('ci/cd') || (s.contains('ci') && s.contains('cd'))) {
    return badge('CI', const Color(0xFF6C47FF), Colors.white);
  }
  if (s.contains('git')) {
    return badge('Git', const Color(0xFFF05032), Colors.white);
  }
  if (s.contains('nginx')) {
    return badge('Nx', const Color(0xFF009639), Colors.white);
  }
  if (s.contains('linux')) return emoji('🐧');

  // ── Mobile ────────────────────────────────────────────────────────────────
  if (s.contains('flutter')) return emoji('💙');
  if (s.contains('react native')) return emoji('⚛');
  if (s.contains('android')) return emoji('🤖');
  if (s.contains('ios')) return emoji('🍎');
  if (s.contains('xamarin')) {
    return badge('X', const Color(0xFF3498DB), Colors.white);
  }
  if (s.contains('ionic')) {
    return badge('I', const Color(0xFF3880FF), Colors.white);
  }

  // ── AI / ML ───────────────────────────────────────────────────────────────
  if (s.contains('tensorflow')) {
    return badge('TF', const Color(0xFFFF6F00), Colors.white);
  }
  if (s.contains('pytorch')) {
    return badge('Pt', const Color(0xFFEE4C2C), Colors.white);
  }
  if (s.contains('openai') || s.contains('chatgpt') || s.contains('gpt')) {
    return badge('AI', Colors.black, Colors.white);
  }
  if (s.contains('machine learning') || s == 'ml') {
    return badge('ML', const Color(0xFF6C47FF), Colors.white);
  }
  if (s.contains('deep learning') || s.contains('dl')) {
    return badge('DL', const Color(0xFF6C47FF), Colors.white);
  }
  if (s.contains('langchain')) {
    return badge('LC', const Color(0xFF1C3C3C), Colors.white);
  }
  if (s.contains('hugging face')) return emoji('🤗');

  // ── Architecture / API ────────────────────────────────────────────────────
  if (s.contains('graphql')) {
    return badge('GQL', const Color(0xFFE10098), Colors.white);
  }
  if (s.contains('grpc')) {
    return badge('gR', const Color(0xFF244C5A), Colors.white);
  }
  if (s.contains('rabbitmq') ||
      s.contains('kafka') ||
      s.contains('message queue')) {
    return badge('MQ', const Color(0xFFFF6600), Colors.white);
  }
  if (s.contains('rest') || s.contains('api')) {
    return badge('API', const Color(0xFF10B981), Colors.white);
  }

  return null;
}

/// Shared skill tag used in profile and marketplace cards.
Widget buildSkillTag({
  required String label,
  required bool isDark,
  Color? accentColor,
  VoidCallback? onRemove,
}) {
  final accent = accentColor ?? AppColors.brandPurple;
  final icon = skillIcon(label);

  // Dark mode: charcoal chip + white text (matches "Kỹ năng chuyên môn")
  final bg = isDark
      ? const Color(0xFF1F2937)
      : accent.withValues(alpha: 0.10);
  final border = isDark
      ? const Color(0xFF374151)
      : accent.withValues(alpha: 0.25);
  final textColor = isDark ? Colors.white : accent;

  return Container(
    padding: EdgeInsets.fromLTRB(
      icon != null ? 6 : 8,
      4,
      onRemove != null ? 4 : 8,
      4,
    ),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: icon),
            ),
          ),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        if (onRemove != null) ...[
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    ),
  );
}
