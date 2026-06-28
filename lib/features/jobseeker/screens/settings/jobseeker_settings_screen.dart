import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';

class JobseekerSettingsScreen extends ConsumerStatefulWidget {
  const JobseekerSettingsScreen({super.key});

  @override
  ConsumerState<JobseekerSettingsScreen> createState() =>
      _JobseekerSettingsScreenState();
}

class _JobseekerSettingsScreenState
    extends ConsumerState<JobseekerSettingsScreen> {
  // Local toggle state (no backend)
  bool _emailReminders = true;
  bool _weeklyProgress = false;
  bool _aiTips = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final language = ref.watch(languageProvider);
    final theme = ref.watch(themeProvider);

    final bg = isDark ? const Color(0xFF070A13) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1A1F35) : Colors.white;
    final borderC =
        isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              l10n.settingsTitle,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.settingsSubtitle,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // Language
            _Section(
              title: l10n.languageSection,
              desc: l10n.languageDesc,
              cardBg: cardBg,
              borderC: borderC,
              isDark: isDark,
              child: Column(
                children: [
                  _RadioTile(
                    title: l10n.english,
                    subtitle: 'English',
                    icon: '🇺🇸',
                    selected: language == 'en',
                    isDark: isDark,
                    borderC: borderC,
                    onTap: () =>
                        ref.read(languageProvider.notifier).setLanguage('en'),
                  ),
                  const SizedBox(height: 8),
                  _RadioTile(
                    title: l10n.vietnamese,
                    subtitle: 'Tiếng Việt',
                    icon: '🇻🇳',
                    selected: language == 'vi',
                    isDark: isDark,
                    borderC: borderC,
                    onTap: () =>
                        ref.read(languageProvider.notifier).setLanguage('vi'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Appearance
            _Section(
              title: l10n.appearanceSection,
              desc: null,
              cardBg: cardBg,
              borderC: borderC,
              isDark: isDark,
              child: Column(
                children: [
                  _RadioTile(
                    title: l10n.lightTheme,
                    subtitle: null,
                    icon: '☀️',
                    selected: theme == ThemeMode.light,
                    isDark: isDark,
                    borderC: borderC,
                    onTap: () =>
                        ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                  ),
                  const SizedBox(height: 8),
                  _RadioTile(
                    title: l10n.darkTheme,
                    subtitle: null,
                    icon: '🌙',
                    selected: theme == ThemeMode.dark,
                    isDark: isDark,
                    borderC: borderC,
                    onTap: () =>
                        ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                  ),
                  const SizedBox(height: 8),
                  _RadioTile(
                    title: l10n.systemTheme_,
                    subtitle: null,
                    icon: '⚙️',
                    selected: theme == ThemeMode.system,
                    isDark: isDark,
                    borderC: borderC,
                    onTap: () =>
                        ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notifications
            _Section(
              title: l10n.notificationsSection,
              desc: null,
              cardBg: cardBg,
              borderC: borderC,
              isDark: isDark,
              child: Column(
                children: [
                  _ToggleTile(
                    title: l10n.emailReminders,
                    isDark: isDark,
                    borderC: borderC,
                    value: _emailReminders,
                    onChanged: (v) => setState(() => _emailReminders = v),
                  ),
                  const SizedBox(height: 8),
                  _ToggleTile(
                    title: l10n.weeklyProgress,
                    isDark: isDark,
                    borderC: borderC,
                    value: _weeklyProgress,
                    onChanged: (v) => setState(() => _weeklyProgress = v),
                  ),
                  const SizedBox(height: 8),
                  _ToggleTile(
                    title: l10n.aiTips,
                    isDark: isDark,
                    borderC: borderC,
                    value: _aiTips,
                    onChanged: (v) => setState(() => _aiTips = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy
            _Section(
              title: l10n.privacySection,
              desc: null,
              cardBg: cardBg,
              borderC: borderC,
              isDark: isDark,
              child: Column(
                children: [
                  _ActionTile(
                    title: l10n.downloadData,
                    icon: Icons.download_rounded,
                    color: AppColors.brandPurple,
                    isDark: isDark,
                    borderC: borderC,
                    onTap: () => _showSnack(context, l10n.downloadData),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    title: l10n.deleteHistory,
                    icon: Icons.history_rounded,
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                    borderC: borderC,
                    onTap: () => _confirmDestructive(
                        context, l10n.deleteHistory, isDark),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    title: l10n.deleteAccount,
                    icon: Icons.delete_forever_rounded,
                    color: const Color(0xFFEF4444),
                    isDark: isDark,
                    borderC: borderC,
                    onTap: () => _confirmDestructive(
                        context, l10n.deleteAccount, isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _confirmDestructive(BuildContext ctx, String action, bool isDark) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1F35) : Colors.white,
        title: Text(action,
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827))),
        content: Text(
          'This action cannot be undone. Are you sure?',
          style: TextStyle(
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(action,
                style: const TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String? desc;
  final Color cardBg;
  final Color borderC;
  final bool isDark;
  final Widget child;

  const _Section({
    required this.title,
    required this.desc,
    required this.cardBg,
    required this.borderC,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (desc != null) ...[
            const SizedBox(height: 4),
            Text(
              desc!,
              style: TextStyle(
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Radio tile ────────────────────────────────────────────────────────────────

class _RadioTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String icon;
  final bool selected;
  final bool isDark;
  final Color borderC;
  final VoidCallback onTap;

  const _RadioTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.borderC,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandPurple.withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.brandPurple : borderC,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? AppColors.brandPurple
                          : (isDark
                              ? Colors.white
                              : const Color(0xFF111827)),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.brandPurple, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Toggle tile ───────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final bool isDark;
  final Color borderC;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.value,
    required this.isDark,
    required this.borderC,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderC),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 14,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.brandPurple,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Color borderC;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.borderC,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.6), size: 18),
          ],
        ),
      ),
    );
  }
}
