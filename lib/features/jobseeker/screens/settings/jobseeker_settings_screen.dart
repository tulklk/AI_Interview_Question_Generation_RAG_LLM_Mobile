import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../hr_generate/data/generation_api.dart';
import '../../providers/candidate_subscription_provider.dart';
import '../profile/jobseeker_profile_screen.dart';
import '../subscription/candidate_subscription_screen.dart';

// ── Privacy provider ──────────────────────────────────────────────────────────

final _privacyRecruiterProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  try {
    final dio = buildGenerationDio();
    final res = await dio.get('/api/candidate/privacy-settings');
    final raw = res.data;
    final map = raw is Map
        ? Map<String, dynamic>.from(raw['data'] is Map ? raw['data'] : raw)
        : <String, dynamic>{};
    final v = map['allowRecruiterRecommendation'] ??
        map['AllowRecruiterRecommendation'];
    if (v is bool) return v;
    return true;
  } catch (_) {
    return true;
  }
});

// ── Tab definitions ───────────────────────────────────────────────────────────

class _Tab {
  final IconData icon;
  final String label;
  const _Tab(this.icon, this.label);
}

/// Built dynamically so labels respond to language changes.
List<_Tab> _buildTabs(AppLocalizations l10n) => [
  _Tab(Icons.person_rounded,       l10n.profileTab),
  _Tab(Icons.tune_rounded,         l10n.generalTab),
  _Tab(Icons.shield_outlined,      l10n.securityTab),
  _Tab(Icons.privacy_tip_outlined, l10n.privacyTab),
  _Tab(Icons.bolt_rounded,         l10n.xpHistoryTab),
  _Tab(Icons.credit_card_rounded,  l10n.billingTab),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class JobseekerSettingsScreen extends ConsumerStatefulWidget {
  const JobseekerSettingsScreen({super.key});

  @override
  ConsumerState<JobseekerSettingsScreen> createState() =>
      _JobseekerSettingsScreenState();
}

class _JobseekerSettingsScreenState
    extends ConsumerState<JobseekerSettingsScreen> {
  int  _tab            = 0;
  int  _prevTab        = 0;   // used for slide direction
  bool _emailReminders = true;
  bool _weeklyProgress = false;
  bool _aiTips         = true;
  bool _savingPrivacy  = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(candidateSubscriptionProvider.notifier).refresh();
    });
  }

  Future<void> _setRecruiterRecommendation(bool value) async {
    setState(() => _savingPrivacy = true);
    try {
      final dio = buildGenerationDio();
      await dio.put('/api/candidate/privacy-settings',
          data: {'allowRecruiterRecommendation': value});
      ref.invalidate(_privacyRecruiterProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:  Text(context.l10n.saveFailed(e)),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _savingPrivacy = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final l10n         = context.l10n;
    final language     = ref.watch(languageProvider);
    final theme        = ref.watch(themeProvider);
    final subState     = ref.watch(candidateSubscriptionProvider);
    final isPremium    = subState.isPremium ||
        (subState.subscription?.entitlements.canPersistHrRecommendation ?? false);
    final privacyAsync = ref.watch(_privacyRecruiterProvider);
    final cardBg       = AppColors.cardBg(isDark);
    final borderC      = AppColors.borderColor(isDark);
    final muted        = AppColors.textMuted(isDark);

    // Tabs 0 (Hồ sơ) and 5 (Thanh toán) embed full screens — no wrapper.
    final isFullScreenTab = _tab == 0 || _tab == 5;

    final tabs = _buildTabs(l10n);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsTitle,
                  style: TextStyle(
                    color:        AppColors.textPrimary(isDark),
                    fontSize:     26,
                    fontWeight:   FontWeight.w800,
                    letterSpacing: -0.4,
                    height:       1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.settingsSubtitle,
                  style: TextStyle(color: muted, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),

          // ── Tab bar — liquid glass pill style ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1D2E).withValues(alpha: 0.70)
                        : const Color(0xFFFFFFFF).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.09)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  child: ListView.separated(
                    scrollDirection:  Axis.horizontal,
                    padding:          const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    itemCount:        tabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 2),
                    itemBuilder: (_, i) => _GlassTabPill(
                      icon:     tabs[i].icon,
                      label:    tabs[i].label,
                      selected: _tab == i,
                      isDark:   isDark,
                      onTap:    () => setState(() {
                        _prevTab = _tab;
                        _tab     = i;
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              // Top-align children so scrollable tabs don't get centered
              // vertically in the Expanded space (default is Alignment.center).
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              transitionBuilder: (child, anim) {
                final dir = _tab >= _prevTab ? 1.0 : -1.0;
                final slide = Tween<Offset>(
                  begin: Offset(dir, 0),
                  end:   Offset.zero,
                ).animate(CurvedAnimation(
                  parent: anim,
                  curve:  Curves.easeOutCubic,
                ));
                return SlideTransition(
                  position: slide,
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: anim,
                        curve:  const Interval(0.0, 0.65),
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: isFullScreenTab
                  // Full-screen embeds (handle own Scaffold + scroll)
                  ? KeyedSubtree(
                      key: ValueKey(_tab),
                      child: _tab == 0
                          ? const JobseekerProfileScreen()
                          : const CandidateSubscriptionScreen(embedded: true),
                    )
                  // Scrollable tab content
                  : KeyedSubtree(
                      key: ValueKey(_tab),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 52),
                        child: _tabContent(
                          isDark:       isDark,
                          l10n:         l10n,
                          language:     language,
                          theme:        theme,
                          isPremium:    isPremium,
                          subState:     subState,
                          privacyAsync: privacyAsync,
                          cardBg:       cardBg,
                          borderC:      borderC,
                          muted:        muted,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab content dispatcher (tabs 1–4) ─────────────────────────────────────

  Widget _tabContent({
    required bool     isDark,
    required AppLocalizations l10n,
    required String   language,
    required ThemeMode theme,
    required bool     isPremium,
    required CandidateSubscriptionState subState,
    required AsyncValue<bool> privacyAsync,
    required Color    cardBg,
    required Color    borderC,
    required Color    muted,
  }) {
    switch (_tab) {
      // ── 1: Chung ──────────────────────────────────────────────────────────
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              cardBg: cardBg, borderC: borderC,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    title:    l10n.languageSection,
                    subtitle: l10n.languageDesc,
                    isDark:   isDark,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceChip(
                          label:    l10n.vietnamese,
                          icon:     Icons.language_rounded,
                          selected: language == 'vi',
                          isDark:   isDark,
                          borderC:  borderC,
                          onTap:    () => ref
                              .read(languageProvider.notifier)
                              .setLanguage('vi'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ChoiceChip(
                          label:    l10n.english,
                          icon:     Icons.translate_rounded,
                          selected: language == 'en',
                          isDark:   isDark,
                          borderC:  borderC,
                          onTap:    () => ref
                              .read(languageProvider.notifier)
                              .setLanguage('en'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              cardBg: cardBg, borderC: borderC,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    title:    l10n.appearanceSection,
                    subtitle: l10n.appearanceSectionDesc,
                    isDark:   isDark,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceChip(
                          label:    l10n.lightTheme,
                          icon:     Icons.light_mode_rounded,
                          selected: theme == ThemeMode.light,
                          isDark:   isDark,
                          borderC:  borderC,
                          onTap:    () => ref
                              .read(themeProvider.notifier)
                              .setTheme(ThemeMode.light),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ChoiceChip(
                          label:    l10n.darkTheme,
                          icon:     Icons.dark_mode_rounded,
                          selected: theme == ThemeMode.dark,
                          isDark:   isDark,
                          borderC:  borderC,
                          onTap:    () => ref
                              .read(themeProvider.notifier)
                              .setTheme(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ChoiceChip(
                          label:    l10n.systemTheme_,
                          icon:     Icons.phone_iphone_rounded,
                          selected: theme == ThemeMode.system,
                          isDark:   isDark,
                          borderC:  borderC,
                          onTap:    () => ref
                              .read(themeProvider.notifier)
                              .setTheme(ThemeMode.system),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              cardBg: cardBg, borderC: borderC,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    title:    l10n.notificationsSection,
                    subtitle: l10n.notificationsSectionDesc,
                    isDark:   isDark,
                  ),
                  const SizedBox(height: 6),
                  _SettingsList(
                    isDark: isDark, borderC: borderC,
                    children: [
                      _ToggleRow(
                        title:     l10n.emailReminders,
                        value:     _emailReminders,
                        isDark:    isDark,
                        onChanged: (v) => setState(() => _emailReminders = v),
                      ),
                      _ToggleRow(
                        title:     l10n.weeklyProgress,
                        value:     _weeklyProgress,
                        isDark:    isDark,
                        onChanged: (v) => setState(() => _weeklyProgress = v),
                      ),
                      _ToggleRow(
                        title:     l10n.aiTips,
                        value:     _aiTips,
                        isDark:    isDark,
                        onChanged: (v) => setState(() => _aiTips = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

      // ── 2: Bảo mật ───────────────────────────────────────────────────────
      case 2:
        return _SecurityTab(isDark: isDark, cardBg: cardBg, borderC: borderC);

      // ── 3: Quyền riêng tư ─────────────────────────────────────────────────
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              cardBg: cardBg, borderC: borderC,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    title:    l10n.privacySection,
                    subtitle: l10n.privacySectionDesc,
                    isDark:   isDark,
                  ),
                  const SizedBox(height: 12),
                  privacyAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(
                          minHeight: 2, color: AppColors.brandPurple),
                    ),
                    error: (_, __) => _RecruiterRecommendTile(
                      value:     false,
                      isPremium: isPremium,
                      isDark:    isDark,
                      borderC:   borderC,
                      saving:    false,
                      onChanged: null,
                      onUpgrade: () => setState(() => _tab = 5),
                    ),
                    data: (allow) => _RecruiterRecommendTile(
                      value:     allow,
                      isPremium: isPremium,
                      isDark:    isDark,
                      borderC:   borderC,
                      saving:    _savingPrivacy,
                      onChanged: isPremium ? _setRecruiterRecommendation : null,
                      onUpgrade: () => setState(() => _tab = 5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              cardBg: cardBg, borderC: borderC,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    title:    l10n.accountData,
                    subtitle: l10n.accountDataDesc,
                    isDark:   isDark,
                  ),
                  const SizedBox(height: 10),
                  _SettingsList(
                    isDark: isDark, borderC: borderC,
                    children: [
                      _NavRow(
                        title:     l10n.downloadData,
                        icon:      Icons.download_rounded,
                        iconColor: AppColors.brandPurple,
                        isDark:    isDark,
                        onTap:     () => _showSnack(context, l10n.downloadData),
                      ),
                      _NavRow(
                        title:     l10n.deleteHistory,
                        icon:      Icons.history_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        isDark:    isDark,
                        onTap:     () => _confirmDestructive(
                            context, l10n.deleteHistory, isDark),
                      ),
                      _NavRow(
                        title:     l10n.deleteAccount,
                        icon:      Icons.delete_outline_rounded,
                        iconColor: const Color(0xFFEF4444),
                        danger:    true,
                        isDark:    isDark,
                        onTap:     () => _confirmDestructive(
                            context, l10n.deleteAccount, isDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

      // ── 4: Lịch sử XP ────────────────────────────────────────────────────
      case 4:
      default:
        return _XpHistoryTab(isDark: isDark, cardBg: cardBg, borderC: borderC);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _confirmDestructive(BuildContext ctx, String action, bool isDark) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(action,
            style: TextStyle(
                color:      AppColors.textPrimary(isDark),
                fontWeight: FontWeight.w700)),
        content: Text(
          ctx.l10n.actionCannotUndo,
          style: TextStyle(color: AppColors.textMuted(isDark), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.cancel,
                style: TextStyle(color: AppColors.textMuted(isDark))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(action,
                style: const TextStyle(
                    color:      Color(0xFFEF4444),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Tab: Bảo mật ─────────────────────────────────────────────────────────────

class _SecurityTab extends StatelessWidget {
  final bool  isDark;
  final Color cardBg;
  final Color borderC;
  const _SecurityTab(
      {required this.isDark, required this.cardBg, required this.borderC});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionCard(
          cardBg: cardBg, borderC: borderC,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                title:    l10n.accountSecurity,
                subtitle: l10n.accountSecurityDesc,
                isDark:   isDark,
              ),
              const SizedBox(height: 12),
              _SettingsList(
                isDark: isDark, borderC: borderC,
                children: [
                  _NavRow(
                    title:     l10n.changePassword,
                    icon:      Icons.lock_reset_rounded,
                    iconColor: AppColors.brandPurple,
                    isDark:    isDark,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:  Text(l10n.comingSoon),
                        behavior: SnackBarBehavior.floating,
                      ),
                    ),
                  ),
                  _NavRow(
                    title:     l10n.loginSessions,
                    icon:      Icons.devices_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    isDark:    isDark,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:  Text(l10n.comingSoon),
                        behavior: SnackBarBehavior.floating,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          cardBg: cardBg, borderC: borderC,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                title:    l10n.twoFactorAuth,
                subtitle: l10n.twoFactorAuthDesc,
                isDark:   isDark,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        const Color(0xFF6C47FF).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(
                      color: const Color(0xFF6C47FF).withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.brandPurple),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.twoFactorComingSoon,
                        style: TextStyle(
                            color:   AppColors.textMuted(isDark),
                            fontSize: 13,
                            height:   1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab: Lịch sử XP ──────────────────────────────────────────────────────────

class _XpHistoryTab extends StatelessWidget {
  final bool  isDark;
  final Color cardBg;
  final Color borderC;
  const _XpHistoryTab(
      {required this.isDark, required this.cardBg, required this.borderC});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF1A1F3A), Color(0xFF141929)]
                  : const [Color(0xFFFFF7E6), Color(0xFFFEF3CD)],
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color:  const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded,
                    size: 28, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.xpTitle,
                      style: TextStyle(
                          color:      isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                          fontSize:   15,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.xpDesc,
                      style: TextStyle(
                          color:   AppColors.textMuted(isDark),
                          fontSize: 12,
                          height:   1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          cardBg: cardBg, borderC: borderC,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                title:    l10n.xpHistoryTab,
                subtitle: l10n.xpHistoryDesc,
                isDark:   isDark,
              ),
              const SizedBox(height: 12),
              _SettingsList(
                isDark: isDark, borderC: borderC,
                children: [
                  _NavRow(
                    title:     l10n.viewDashboard,
                    icon:      Icons.dashboard_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    isDark:    isDark,
                    onTap:     () => context.go('/jobseeker/dashboard'),
                  ),
                  _NavRow(
                    title:     l10n.achievementsBadges,
                    icon:      Icons.emoji_events_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    isDark:    isDark,
                    onTap:     () => context.push('/jobseeker/profile'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._xpTiers(isDark, l10n),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _xpTiers(bool isDark, AppLocalizations l10n) {
    final tiers = [
      (label: l10n.levelLabel(1), xp: '0 XP',     color: const Color(0xFF9CA3AF)),
      (label: l10n.levelLabel(2), xp: '100 XP',   color: const Color(0xFF10B981)),
      (label: l10n.levelLabel(3), xp: '300 XP',   color: const Color(0xFF3B82F6)),
      (label: l10n.levelLabel(4), xp: '600 XP',   color: const Color(0xFF8B5CF6)),
      (label: l10n.level5Plus,    xp: '1000+ XP', color: const Color(0xFFF59E0B)),
    ];
    return [
      Text(l10n.levelTable,
          style: TextStyle(
              color:         AppColors.textMuted(isDark),
              fontSize:      12,
              fontWeight:    FontWeight.w600,
              letterSpacing: 0.3)),
      const SizedBox(height: 8),
      Wrap(
        spacing:    8,
        runSpacing: 8,
        children: tiers
            .map((t) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:        t.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.color.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: t.color),
                      const SizedBox(width: 4),
                      Text('${t.label}  ${t.xp}',
                          style: TextStyle(
                              color:      t.color,
                              fontSize:   11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
            .toList(),
      ),
    ];
  }
}

// ── Recruiter recommendation tile ─────────────────────────────────────────────

class _RecruiterRecommendTile extends StatelessWidget {
  final bool                value;
  final bool                isPremium;
  final bool                isDark;
  final Color               borderC;
  final bool                saving;
  final ValueChanged<bool>? onChanged;
  final VoidCallback        onUpgrade;

  const _RecruiterRecommendTile({
    required this.value,
    required this.isPremium,
    required this.isDark,
    required this.borderC,
    required this.saving,
    required this.onChanged,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.textMuted(isDark);
    final l10n  = context.l10n;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:        isPremium ? null : onUpgrade,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPremium
                  ? borderC
                  : AppColors.brandPurple.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.recruiterRecommendTitle,
                      style: TextStyle(
                          color:      AppColors.textPrimary(isDark),
                          fontSize:   14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded,
                              size: 11, color: AppColors.brandPurple),
                          SizedBox(width: 4),
                          Text('Premium',
                              style: TextStyle(
                                  color:      AppColors.brandPurple,
                                  fontSize:   10,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )
                  else if (saving)
                    const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Switch.adaptive(
                      value:            value,
                      onChanged:        onChanged,
                      activeTrackColor: AppColors.brandPurple,
                      activeThumbColor: Colors.white,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isPremium
                    ? l10n.recruiterRecommendPremiumDesc
                    : l10n.recruiterRecommendFreeDesc,
                style: TextStyle(color: muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared building blocks ────────────────────────────────────────────────────

/// Liquid-glass-style tab pill
class _GlassTabPill extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         selected;
  final bool         isDark;
  final VoidCallback onTap;

  const _GlassTabPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.brandPurple;
    final fg = selected
        ? Colors.white
        : isDark
            ? const Color(0xFF8A94A6)
            : const Color(0xFF9AA3B2);

    return GestureDetector(
      onTap:    onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve:    Curves.easeOut,
        padding:  const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:      accent.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset:     const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                icon,
                key:   ValueKey(selected),
                size:  selected ? 14 : 13,
                color: fg,
              ),
            ),
            const SizedBox(width: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color:         fg,
                fontSize:      13,
                fontWeight:    selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: selected ? -0.2 : 0,
                decoration:    TextDecoration.none,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  // Legacy params accepted but ignored — glass style is now self-contained.
  final Color? cardBg;
  final Color? borderC;

  const _SectionCard({
    required this.child,
    this.cardBg,
    this.borderC,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      isDark:       isDark,
      padding:      const EdgeInsets.all(16),
      borderRadius: 16,
      child:        child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String  title;
  final String? subtitle;
  final bool    isDark;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color:         AppColors.textPrimary(isDark),
                fontSize:      15,
                fontWeight:    FontWeight.w700,
                letterSpacing: -0.15)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!,
              style: TextStyle(
                  color:   AppColors.textMuted(isDark),
                  fontSize: 12.5,
                  height:   1.35)),
        ],
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         selected;
  final bool         isDark;
  final Color        borderC;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.borderC,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? AppColors.brandPurple
        : AppColors.textPrimary(isDark);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve:    Curves.easeOut,
          padding:  const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandPurple
                    .withValues(alpha: isDark ? 0.16 : 0.08)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : const Color(0xFFF9FAFB)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.brandPurple.withValues(alpha: 0.7)
                  : borderC,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines:  1,
                overflow:  TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color:      fg,
                    fontSize:   12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  final bool         isDark;
  final Color        borderC;
  final List<Widget> children;

  const _SettingsList({
    required this.isDark,
    required this.borderC,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderC),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height:    1,
                thickness: 1,
                indent:    14,
                endIndent: 14,
                color:     borderC.withValues(alpha: 0.85),
              ),
          ],
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String             title;
  final bool               value;
  final bool               isDark;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color:      AppColors.textPrimary(isDark),
                    fontSize:   14,
                    fontWeight: FontWeight.w500)),
          ),
          Switch.adaptive(
            value:            value,
            onChanged:        onChanged,
            activeTrackColor: AppColors.brandPurple,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String       title;
  final IconData     icon;
  final Color        iconColor;
  final bool         isDark;
  final bool         danger;
  final VoidCallback onTap;

  const _NavRow({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final muted  = AppColors.textMuted(isDark);
    final tColor = danger
        ? const Color(0xFFEF4444)
        : AppColors.textPrimary(isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        color:      tColor,
                        fontSize:   14,
                        fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.chevron_right_rounded,
                  size:  20,
                  color: muted.withValues(alpha: 0.65)),
            ],
          ),
        ),
      ),
    );
  }
}
