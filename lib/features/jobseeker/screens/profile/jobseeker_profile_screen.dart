import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/skill_icon.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/services/profile_service.dart';
import '../../../../data/services/storage_service.dart';
import '../../models/jobseeker_models.dart';
import '../../providers/candidate_subscription_provider.dart';
import '../../providers/jobseeker_providers.dart';
import 'widgets/achievements_grid.dart';
import 'widgets/gamification_progress_card.dart';

// ── Main screen ───────────────────────────────────────────────────────────────

class JobseekerProfileScreen extends ConsumerStatefulWidget {
  const JobseekerProfileScreen({super.key});

  @override
  ConsumerState<JobseekerProfileScreen> createState() =>
      _JobseekerProfileScreenState();
}

class _JobseekerProfileScreenState
    extends ConsumerState<JobseekerProfileScreen> {
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(candidateProfileProvider.notifier).load();
      ref.read(cvProvider.notifier).load();
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A2235) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Xác nhận đăng xuất',
              style: TextStyle(
                  color: isDark ? Colors.white : AppColors.nearBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          content: Text('Bạn có chắc chắn muốn đăng xuất không?',
              style: TextStyle(color: AppColors.gray500, fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy',
                  style: TextStyle(color: Color(0xFF6B7280))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đăng xuất',
                  style: TextStyle(
                      color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoggingOut = true);
    await ref.read(authProvider.notifier).logout();
  }

  void _showEditProfileSheet(
      BuildContext context, CandidateProfileData data) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _EditCandidateProfileSheet(data: data),
    );
  }

  void _showCvSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n   = context.l10n;
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) {
        final bg = isDark ? const Color(0xFF1A2235) : Colors.white;
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
              color:        bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(children: [
                const Icon(PhosphorIconsBold.fileText,
                    size: 16, color: AppColors.brandPurple),
                const SizedBox(width: 8),
                Text('CV & Resume',
                    style: TextStyle(
                        color: isDark ? Colors.white : AppColors.nearBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: isDark ? AppColors.gray400 : AppColors.gray500),
                    onPressed: () => Navigator.of(context).pop()),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, MediaQuery.of(context).padding.bottom + 24),
                child: _CvSection(isDark: isDark, l10n: l10n),
              ),
            ),
          ]),
        );
      },
    );
  }

  void _showSkillsSheet(
      BuildContext context, CandidateProfileData data) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _SkillsSheet(initialSkills: data.techStack),
    );
  }

  void _showGamificationSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) {
        final bg = isDark ? const Color(0xFF1A2235) : Colors.white;
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
              color:        bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(children: [
                const Icon(PhosphorIconsBold.lightning,
                    size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text('XP & Cấp độ',
                    style: TextStyle(
                        color: isDark ? Colors.white : AppColors.nearBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: isDark ? AppColors.gray400 : AppColors.gray500),
                    onPressed: () => Navigator.of(context).pop()),
              ]),
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: GamificationProgressCard(),
              ),
            ),
          ]),
        );
      },
    );
  }

  void _showAchievementsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) {
        final bg = isDark ? const Color(0xFF1A2235) : Colors.white;
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
              color:        bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(children: [
                const Icon(PhosphorIconsBold.trophy,
                    size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text('Thành tích',
                    style: TextStyle(
                        color: isDark ? Colors.white : AppColors.nearBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: isDark ? AppColors.gray400 : AppColors.gray500),
                    onPressed: () => Navigator.of(context).pop()),
              ]),
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: AchievementsGrid(),
              ),
            ),
          ]),
        );
      },
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => const _CandidateChangePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final themeMode    = ref.watch(themeProvider);
    final profileState = ref.watch(candidateProfileProvider);

    if (profileState.isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: CandidateProfileSkeleton(isDark: isDark),
      );
    }

    if (profileState.error != null && profileState.profile == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _ErrorView(
          error:   profileState.error!,
          isDark:  isDark,
          onRetry: () => ref.read(candidateProfileProvider.notifier).load(),
        ),
      );
    }

    final data = profileState.profile ??
        const CandidateProfileData(fullName: '', email: '');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // ── Hero card ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _CandidateHeroCard(data: data, isDark: isDark)
                .animate()
                .fadeIn(duration: 350.ms)
                .slideY(begin: -0.05, curve: Curves.easeOut),
          ),

          // ── Menu sections ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Hồ sơ của tôi ─────────────────────────────────────────
                _SectionLabel('Hồ sơ của tôi', isDark: isDark),
                const SizedBox(height: 8),
                _MenuCard(isDark: isDark, children: [
                  _MenuItem(
                    icon:   PhosphorIconsBold.userCircle,
                    label:  'Thông tin cá nhân',
                    isDark: isDark,
                    onTap:  () => _showEditProfileSheet(context, data),
                  ),
                  _MenuDivider(isDark: isDark),
                  _MenuItem(
                    icon:   PhosphorIconsBold.fileText,
                    label:  'CV & Resume',
                    isDark: isDark,
                    onTap:  () => _showCvSheet(context),
                  ),
                  _MenuDivider(isDark: isDark),
                  _MenuItem(
                    icon:     PhosphorIconsBold.code,
                    label:    'Kỹ năng & Tech Stack',
                    isDark:   isDark,
                    trailing: data.techStack.isNotEmpty
                        ? _CountBadge(count: data.techStack.length)
                        : null,
                    onTap: () => _showSkillsSheet(context, data),
                  ),
                ]).animate().fadeIn(delay: 60.ms),
                const SizedBox(height: 20),

                // ── Tiến độ ───────────────────────────────────────────────
                _SectionLabel('Tiến độ', isDark: isDark),
                const SizedBox(height: 8),
                _MenuCard(isDark: isDark, children: [
                  _MenuItem(
                    icon:   PhosphorIconsBold.lightning,
                    label:  'XP & Cấp độ',
                    isDark: isDark,
                    onTap:  () => _showGamificationSheet(context),
                  ),
                  _MenuDivider(isDark: isDark),
                  _MenuItem(
                    icon:   PhosphorIconsBold.trophy,
                    label:  'Thành tích',
                    isDark: isDark,
                    onTap:  () => _showAchievementsSheet(context),
                  ),
                ]).animate().fadeIn(delay: 110.ms),
                const SizedBox(height: 20),

                // ── Cài đặt ───────────────────────────────────────────────
                _SectionLabel('Cài đặt', isDark: isDark),
                const SizedBox(height: 8),
                _MenuCard(isDark: isDark, children: [
                  _MenuItem(
                    icon:   PhosphorIconsBold.bell,
                    label:  'Thông báo',
                    isDark: isDark,
                    onTap:  () {},
                  ),
                  _MenuDivider(isDark: isDark),
                  _MenuItem(
                    icon:   PhosphorIconsBold.globe,
                    label:  'Ngôn ngữ',
                    isDark: isDark,
                    onTap:  () {},
                  ),
                  _MenuDivider(isDark: isDark),
                  _MenuItem(
                    icon:        PhosphorIconsBold.moon,
                    label:       'Giao diện (Sáng/Tối)',
                    isDark:      isDark,
                    showChevron: false,
                    trailing: Switch.adaptive(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (v) => ref
                          .read(themeProvider.notifier)
                          .setTheme(v ? ThemeMode.dark : ThemeMode.light),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.brandPurple,
                    ),
                    onTap: null,
                  ),
                ]).animate().fadeIn(delay: 160.ms),
                const SizedBox(height: 20),

                // ── Bảo mật ───────────────────────────────────────────────
                _SectionLabel('Bảo mật', isDark: isDark),
                const SizedBox(height: 8),
                _MenuCard(isDark: isDark, children: [
                  _MenuItem(
                    icon:   PhosphorIconsBold.lockKey,
                    label:  'Đổi mật khẩu',
                    isDark: isDark,
                    onTap:  () => _showChangePasswordSheet(context),
                  ),
                ]).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 28),

                // ── Logout ────────────────────────────────────────────────
                SizedBox(
                  width:  double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFFEF4444)))
                        : const Icon(PhosphorIconsBold.signOut,
                            size: 17, color: Color(0xFFEF4444)),
                    label: Text(
                      _isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất',
                      style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ).animate().fadeIn(delay: 240.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Candidate hero card ───────────────────────────────────────────────────────

class _CandidateHeroCard extends ConsumerWidget {
  final CandidateProfileData data;
  final bool isDark;
  const _CandidateHeroCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamState   = ref.watch(gamificationProvider);
    final earnedCnt  = gamState.earnedCount;
    final level      = gamState.progress?.level;
    final authUser   = ref.watch(authProvider).user;
    final isPremium  = ref.watch(candidateSubscriptionProvider).isPremium;
    final avatarUrl  = (data.avatarUrl != null && data.avatarUrl!.isNotEmpty)
        ? data.avatarUrl
        : authUser?.avatarUrl;
    final displayName = data.fullName.isNotEmpty
        ? data.fullName
        : (authUser?.name ?? '');

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft:  Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.of(context).padding.top + 20,
            24,
            28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF2D1B69), const Color(0xFF1A1040)]
                : [const Color(0xFF7C3AED), const Color(0xFF4F46E5)],
          ),
        ),
        child: Stack(children: [
          const Positioned.fill(
            child: RepaintBoundary(child: _HeroDriftOrbs()),
          ),
          Column(children: [
            // Avatar
            UserAvatar(
              name:        displayName.isNotEmpty ? displayName : 'User',
              imageUrl:    avatarUrl,
              size:        80,
              showGlowRing: true,
              fontScale:   0.42,
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.03,
                    duration: 2400.ms, curve: Curves.easeInOut),
            const SizedBox(height: 14),
            Text(
              displayName.isNotEmpty ? displayName : 'Candidate',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (data.targetRole?.isNotEmpty == true)
              Text(
                data.targetRole!,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            // Plan badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isPremium
                    ? const Color(0xFFFFD700).withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isPremium
                      ? const Color(0xFFFFD700).withValues(alpha: 0.60)
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.workspace_premium_rounded,
                    size: 12,
                    color: isPremium ? const Color(0xFFFFD700) : Colors.white),
                const SizedBox(width: 4),
                Text(
                  isPremium ? 'Premium' : 'Free Plan',
                  style: TextStyle(
                      color: isPremium
                          ? const Color(0xFFFFD700)
                          : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
              decoration: BoxDecoration(
                color:        Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _HeroStat(
                        value: '${data.techStack.length}',
                        label: 'Kỹ năng'),
                    Container(
                        width: 1, height: 28,
                        color: Colors.white.withValues(alpha: 0.2)),
                    _HeroStat(
                        value: '$earnedCnt',
                        label: 'Thành tích'),
                    Container(
                        width: 1, height: 28,
                        color: Colors.white.withValues(alpha: 0.2)),
                    _HeroStat(
                        value: level != null ? 'Lv.$level' : '—',
                        label: 'Cấp độ'),
                  ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Hero animation widgets ────────────────────────────────────────────────────

class _HeroDriftOrbs extends StatefulWidget {
  const _HeroDriftOrbs();

  @override
  State<_HeroDriftOrbs> createState() => _HeroDriftOrbsState();
}

class _HeroDriftOrbsState extends State<_HeroDriftOrbs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
          painter: _HeroOrbPainter(_ctrl.value),
          child: const SizedBox.expand()),
    );
  }
}

class _HeroOrbPainter extends CustomPainter {
  final double t;
  _HeroOrbPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    void orb({required double cx, required double cy,
        required double r, required double alpha}) {
      canvas.drawCircle(
          Offset(cx, cy), r,
          Paint()
            ..color = Colors.white.withValues(alpha: alpha)
            ..style = PaintingStyle.fill);
    }

    final s1 = t * 6.28318;
    final s2 = t * 6.28318 + 2.1;
    final s3 = t * 6.28318 + 4.0;
    orb(cx: size.width * 0.88 + 18 * math.cos(s1),
        cy: size.height * 0.08 + 14 * math.sin(s1 * 0.7),
        r: 70 + 8 * math.sin(s1),
        alpha: 0.055 + 0.025 * (0.5 + 0.5 * math.sin(s1)));
    orb(cx: size.width * 0.12 + 22 * math.cos(s2 * 0.8),
        cy: size.height * 0.92 + 16 * math.sin(s2),
        r: 60 + 10 * math.cos(s2),
        alpha: 0.04 + 0.02 * (0.5 + 0.5 * math.cos(s2)));
    orb(cx: size.width * 0.78 + 12 * math.sin(s3),
        cy: size.height * 0.42 + 20 * math.cos(s3 * 0.9),
        r: 28 + 6 * math.sin(s3 * 1.2),
        alpha: 0.07 + 0.03 * (0.5 + 0.5 * math.sin(s3)));
  }

  @override
  bool shouldRepaint(covariant _HeroOrbPainter old) => old.t != t;
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color:      Colors.white.withValues(alpha: 0.65),
                  fontSize:   11,
                  fontWeight: FontWeight.w500)),
        ],
      );
}

// ── Edit candidate profile sheet ──────────────────────────────────────────────

class _EditCandidateProfileSheet extends ConsumerStatefulWidget {
  final CandidateProfileData data;
  const _EditCandidateProfileSheet({required this.data});

  @override
  ConsumerState<_EditCandidateProfileSheet> createState() =>
      _EditCandidateProfileSheetState();
}

class _EditCandidateProfileSheetState
    extends ConsumerState<_EditCandidateProfileSheet> {
  late final _nameCtrl       = TextEditingController(text: widget.data.fullName);
  late final _bioCtrl        = TextEditingController(text: widget.data.bio ?? '');
  late final _targetRoleCtrl =
      TextEditingController(text: widget.data.targetRole ?? '');
  late final _linkedinCtrl =
      TextEditingController(text: widget.data.linkedInUrl ?? '');
  late final _githubCtrl =
      TextEditingController(text: widget.data.githubUrl ?? '');
  String? _seniorityLevel;
  bool _saving = false;
  String? _msg;
  bool _success = false;

  static const _levels = ['Junior', 'Mid-level', 'Senior', 'Lead', 'Principal'];

  @override
  void initState() {
    super.initState();
    _seniorityLevel = widget.data.seniorityLevel;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _targetRoleCtrl.dispose();
    _linkedinCtrl.dispose();
    _githubCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _msg = null; });
    final updated = widget.data.copyWith(
      fullName:      _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : widget.data.fullName,
      bio:           _bioCtrl.text.trim().isNotEmpty
          ? _bioCtrl.text.trim()
          : widget.data.bio,
      targetRole:    _targetRoleCtrl.text.trim().isNotEmpty
          ? _targetRoleCtrl.text.trim()
          : widget.data.targetRole,
      linkedInUrl:   _linkedinCtrl.text.trim().isNotEmpty
          ? _linkedinCtrl.text.trim()
          : widget.data.linkedInUrl,
      githubUrl:     _githubCtrl.text.trim().isNotEmpty
          ? _githubCtrl.text.trim()
          : widget.data.githubUrl,
      seniorityLevel: _seniorityLevel ?? widget.data.seniorityLevel,
    );
    try {
      await ref.read(candidateProfileProvider.notifier).save(updated);
      if (!mounted) return;
      setState(() { _success = true; _msg = 'Đã cập nhật thông tin thành công.'; });
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() { _success = false; _msg = 'Có lỗi xảy ra. Vui lòng thử lại.'; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF1A2235) : Colors.white;
    final borderC = AppColors.borderColor(isDark);
    final labelC  = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final textC   = AppColors.textPrimary(isDark);
    final mq      = MediaQuery.of(context);

    return Container(
      height: mq.size.height * 0.92,
      decoration: BoxDecoration(
          color:        bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        _SheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(children: [
            Text('Thông tin cá nhân',
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.nearBlack,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
                icon: Icon(Icons.close_rounded,
                    color: isDark ? AppColors.gray400 : AppColors.gray500),
                onPressed: () => Navigator.of(context).pop()),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, mq.padding.bottom + 20),
            child: Column(children: [
              if (_msg != null) ...[
                _StatusBanner(message: _msg!, success: _success),
                const SizedBox(height: 14),
              ],
              _SheetField(
                  label:      'Họ và tên *',
                  ctrl:       _nameCtrl,
                  hint:       'Nguyễn Văn A',
                  isDark:     isDark,
                  borderC:    borderC,
                  labelC:     labelC,
                  textC:      textC),
              _SheetField(
                  label:      'Mục tiêu nghề nghiệp',
                  ctrl:       _targetRoleCtrl,
                  hint:       'Flutter Developer, Backend Engineer...',
                  isDark:     isDark,
                  borderC:    borderC,
                  labelC:     labelC,
                  textC:      textC),
              _SheetTextArea(
                  label:      'Giới thiệu bản thân',
                  ctrl:       _bioCtrl,
                  hint:       'Mô tả ngắn về bạn...',
                  isDark:     isDark,
                  borderC:    borderC,
                  labelC:     labelC,
                  textC:      textC),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cấp độ kinh nghiệm',
                        style: TextStyle(
                            color: labelC,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value:     _seniorityLevel,
                      hint:      Text('Chọn cấp độ',
                          style: TextStyle(color: labelC, fontSize: 14)),
                      style:     TextStyle(color: textC, fontSize: 14),
                      dropdownColor: AppColors.cardBg(isDark),
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderC)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.brandPurple)),
                        filled:    true,
                        fillColor: isDark
                            ? const Color(0xFF0D1117)
                            : const Color(0xFFF9FAFB),
                      ),
                      items: _levels
                          .map((l) => DropdownMenuItem(
                              value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _seniorityLevel = v),
                    ),
                  ],
                ),
              ),
              _SheetField(
                  label:      'LinkedIn URL',
                  ctrl:       _linkedinCtrl,
                  hint:       'https://linkedin.com/in/...',
                  isDark:     isDark,
                  borderC:    borderC,
                  labelC:     labelC,
                  textC:      textC),
              _SheetField(
                  label:      'GitHub URL',
                  ctrl:       _githubCtrl,
                  hint:       'https://github.com/...',
                  isDark:     isDark,
                  borderC:    borderC,
                  labelC:     labelC,
                  textC:      textC),
              const SizedBox(height: 8),
              AppGradientButton(
                label:     'Lưu thay đổi',
                isLoading: _saving,
                onTap:     _saving ? null : _save,
                height:    50,
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Skills sheet ──────────────────────────────────────────────────────────────

class _SkillsSheet extends ConsumerStatefulWidget {
  final List<String> initialSkills;
  const _SkillsSheet({required this.initialSkills});

  @override
  ConsumerState<_SkillsSheet> createState() => _SkillsSheetState();
}

class _SkillsSheetState extends ConsumerState<_SkillsSheet> {
  late List<String> _skills;
  final _ctrl    = TextEditingController();
  bool  _saving  = false;

  @override
  void initState() {
    super.initState();
    _skills = List.from(widget.initialSkills);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final current = ref.read(candidateProfileProvider).profile ??
        const CandidateProfileData(fullName: '', email: '');
    try {
      await ref
          .read(candidateProfileProvider.notifier)
          .save(current.copyWith(techStack: _skills));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF1A2235) : Colors.white;
    final borderC = AppColors.borderColor(isDark);
    final mq      = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: mq.size.height * 0.75,
        decoration: BoxDecoration(
            color:        bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(children: [
              const Icon(PhosphorIconsBold.code,
                  size: 16, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Text('Kỹ năng & Tech Stack',
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.nearBlack,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: isDark ? AppColors.gray400 : AppColors.gray500),
                  onPressed: () => Navigator.of(context).pop()),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, mq.padding.bottom + 20),
              child: Column(children: [
                // Skill chips
                Wrap(
                  spacing:   8,
                  runSpacing: 6,
                  children: _skills
                      .map((s) => buildSkillTag(
                          label:    s,
                          isDark:   isDark,
                          onRemove: () => setState(() => _skills.remove(s))))
                      .toList(),
                ),
                const SizedBox(height: 14),
                // Add skill row
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller:  _ctrl,
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty && !_skills.contains(v.trim())) {
                          setState(() => _skills.add(v.trim()));
                          _ctrl.clear();
                        }
                      },
                      style: TextStyle(
                          color: AppColors.textPrimary(isDark), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Nhập kỹ năng rồi nhấn Enter...',
                        hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF4A5578)
                                : const Color(0xFF9CA3AF),
                            fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderC)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: AppColors.brandPurple)),
                        filled:    true,
                        fillColor: isDark
                            ? const Color(0xFF0D1117)
                            : const Color(0xFFF9FAFB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final v = _ctrl.text.trim();
                      if (v.isNotEmpty && !_skills.contains(v)) {
                        setState(() => _skills.add(v));
                        _ctrl.clear();
                      }
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                    child: const Text('Thêm',
                        style: TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 20),
                AppGradientButton(
                    label:     'Lưu kỹ năng',
                    isLoading: _saving,
                    onTap:     _saving ? null : _save,
                    height:    50),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Change password sheet (candidate) ────────────────────────────────────────

class _CandidateChangePasswordSheet extends ConsumerStatefulWidget {
  const _CandidateChangePasswordSheet();

  @override
  ConsumerState<_CandidateChangePasswordSheet> createState() =>
      _CandidateChangePasswordSheetState();
}

class _CandidateChangePasswordSheetState
    extends ConsumerState<_CandidateChangePasswordSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _curPwCtrl  = TextEditingController();
  final _newPwCtrl  = TextEditingController();
  final _confCtrl   = TextEditingController();
  bool _saving      = false;
  bool _showCur     = false;
  bool _showNew     = false;
  bool _showConf    = false;
  String? _msg;
  bool _success     = false;

  @override
  void dispose() {
    _curPwCtrl.dispose(); _newPwCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _msg = null; });
    try {
      final token = await StorageService.getAccessToken();
      if (token == null || token.isEmpty) throw Exception('Phiên đăng nhập hết hạn.');
      await ProfileService.changePassword(
        token:           token,
        currentPassword: _curPwCtrl.text,
        newPassword:     _newPwCtrl.text,
      );
      _curPwCtrl.clear(); _newPwCtrl.clear(); _confCtrl.clear();
      if (!mounted) return;
      setState(() { _success = true; _msg = 'Mật khẩu đã được thay đổi thành công.'; });
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop();
    } on ProfileException catch (e) {
      if (mounted) setState(() { _success = false; _msg = e.message; });
    } catch (_) {
      if (mounted) setState(() { _success = false; _msg = 'Có lỗi xảy ra. Vui lòng thử lại.'; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF1A2235) : Colors.white;
    final borderC = AppColors.borderColor(isDark);
    final labelC  = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final textC   = AppColors.textPrimary(isDark);
    final mq      = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
            color:        bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.fromLTRB(20, 6, 20, mq.padding.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _SheetHandle(),
          const SizedBox(height: 12),
          Row(children: [
            Text('Đổi mật khẩu',
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.nearBlack,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
                icon: Icon(Icons.close_rounded,
                    color: isDark ? AppColors.gray400 : AppColors.gray500),
                onPressed: () => Navigator.of(context).pop()),
          ]),
          const SizedBox(height: 8),
          if (_msg != null) ...[
            _StatusBanner(message: _msg!, success: _success),
            const SizedBox(height: 12),
          ],
          Form(
            key: _formKey,
            child: Column(children: [
              _PwField(
                label:    'Mật khẩu hiện tại *',
                ctrl:     _curPwCtrl,
                show:     _showCur,
                isDark:   isDark,
                borderC:  borderC,
                labelC:   labelC,
                textC:    textC,
                onToggle: () => setState(() => _showCur = !_showCur),
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
              ),
              _PwField(
                label:    'Mật khẩu mới *',
                ctrl:     _newPwCtrl,
                show:     _showNew,
                isDark:   isDark,
                borderC:  borderC,
                labelC:   labelC,
                textC:    textC,
                onToggle: () => setState(() => _showNew = !_showNew),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Vui lòng nhập mật khẩu mới';
                  if (v!.length < 6) return 'Tối thiểu 6 ký tự';
                  return null;
                },
              ),
              _PwField(
                label:    'Xác nhận mật khẩu mới *',
                ctrl:     _confCtrl,
                show:     _showConf,
                isDark:   isDark,
                borderC:  borderC,
                labelC:   labelC,
                textC:    textC,
                onToggle: () => setState(() => _showConf = !_showConf),
                validator: (v) =>
                    v != _newPwCtrl.text
                        ? 'Mật khẩu xác nhận không khớp'
                        : null,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          AppGradientButton(
              label:     'Đổi mật khẩu',
              isLoading: _saving,
              onTap:     _saving ? null : _save,
              height:    50),
        ]),
      ),
    );
  }
}

// ── Shared UI atoms ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 2),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color:         isDark ? AppColors.gray500 : AppColors.gray400,
        fontSize:      11,
        fontWeight:    FontWeight.w700,
        letterSpacing: 0.9,
      ),
    ),
  );
}

class _MenuCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _MenuCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:        AppColors.cardBg(isDark),
      borderRadius: BorderRadius.circular(14),
      border:       Border.all(color: AppColors.borderColor(isDark)),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color:      Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset:     const Offset(0, 2),
              )
            ],
    ),
    child: Column(children: children),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData   icon;
  final String     label;
  final bool       isDark;
  final bool       showChevron;
  final Widget?    trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isDark,
    this.showChevron = true,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color:        Colors.transparent,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Container(
            width:  38, height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.textPrimary(isDark)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color:      AppColors.textPrimary(isDark),
                    fontSize:   14,
                    fontWeight: FontWeight.w500)),
          ),
          if (trailing != null)
            trailing!
          else if (showChevron)
            Icon(Icons.chevron_right_rounded,
                size:  20,
                color: isDark ? AppColors.gray500 : AppColors.gray400),
        ]),
      ),
    ),
  );
}

class _MenuDivider extends StatelessWidget {
  final bool isDark;
  const _MenuDivider({required this.isDark});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 64, color: AppColors.borderColor(isDark));
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 10),
      width: 36, height: 4,
      decoration: BoxDecoration(
        color:        Colors.grey.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color:        AppColors.brandPurple.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$count',
      style: const TextStyle(
          color:      AppColors.brandPurple,
          fontSize:   11,
          fontWeight: FontWeight.w700),
    ),
  );
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool   success;
  const _StatusBanner({required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF10B981) : AppColors.error;
    final icon  = success
        ? PhosphorIconsBold.checkCircle
        : PhosphorIconsBold.warningCircle;
    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: TextStyle(
                  color:      color,
                  fontSize:   12,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String                label;
  final TextEditingController ctrl;
  final String?               hint;
  final bool                  isDark;
  final Color                 borderC;
  final Color                 labelC;
  final Color                 textC;

  const _SheetField({
    required this.label,
    required this.ctrl,
    required this.isDark,
    required this.borderC,
    required this.labelC,
    required this.textC,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(color: labelC, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        style:      TextStyle(color: textC, fontSize: 14),
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: TextStyle(color: labelC, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          isDense: true,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderC)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.brandPurple)),
          filled:    true,
          fillColor: isDark
              ? const Color(0xFF0D1117)
              : const Color(0xFFF9FAFB),
        ),
      ),
    ]),
  );
}

class _SheetTextArea extends StatelessWidget {
  final String                label;
  final TextEditingController ctrl;
  final String?               hint;
  final bool                  isDark;
  final Color                 borderC;
  final Color                 labelC;
  final Color                 textC;

  const _SheetTextArea({
    required this.label,
    required this.ctrl,
    required this.isDark,
    required this.borderC,
    required this.labelC,
    required this.textC,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(color: labelC, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines:   4,
        style:      TextStyle(color: textC, fontSize: 14),
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: TextStyle(color: labelC, fontSize: 14),
          contentPadding: const EdgeInsets.all(12),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderC)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.brandPurple)),
          filled:    true,
          fillColor: isDark
              ? const Color(0xFF0D1117)
              : const Color(0xFFF9FAFB),
        ),
      ),
    ]),
  );
}

class _PwField extends StatelessWidget {
  final String                label;
  final TextEditingController ctrl;
  final bool                  show;
  final bool                  isDark;
  final Color                 borderC;
  final Color                 labelC;
  final Color                 textC;
  final VoidCallback          onToggle;
  final FormFieldValidator<String> validator;

  const _PwField({
    required this.label,
    required this.ctrl,
    required this.show,
    required this.isDark,
    required this.borderC,
    required this.labelC,
    required this.textC,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(color: labelC, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller:  ctrl,
        obscureText: !show,
        style:       TextStyle(color: textC, fontSize: 14),
        validator:   validator,
        decoration: InputDecoration(
          hintText:  '••••••••',
          hintStyle: TextStyle(color: labelC, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          isDense: true,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderC)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.brandPurple)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error)),
          filled:    true,
          fillColor: isDark
              ? const Color(0xFF0D1117)
              : const Color(0xFFF9FAFB),
          suffixIcon: IconButton(
            icon: Icon(
                show
                    ? PhosphorIconsBold.eyeSlash
                    : PhosphorIconsBold.eye,
                size: 17,
                color: AppColors.gray400),
            onPressed: onToggle,
          ),
        ),
      ),
    ]),
  );
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String       error;
  final bool         isDark;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded,
          size: 48, color: Color(0xFFEF4444)),
      const SizedBox(height: 12),
      Text(error,
          style: TextStyle(
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
              fontSize: 14),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
    ]),
  );
}

// ── CV Section (unchanged, kept in full) ─────────────────────────────────────

const _kAllowedExts   = ['pdf', 'docx', 'jpg', 'jpeg', 'png'];
const _kMaxSizeBytes  = 10 * 1024 * 1024; // 10 MB

class _CvSection extends ConsumerStatefulWidget {
  final bool             isDark;
  final AppLocalizations l10n;
  const _CvSection({required this.isDark, required this.l10n});

  @override
  ConsumerState<_CvSection> createState() => _CvSectionState();
}

class _CvSectionState extends ConsumerState<_CvSection> {
  Future<void> _pickAndUpload({bool replace = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type:              FileType.custom,
      allowedExtensions: _kAllowedExts,
      withData:          false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final ext  = (file.extension ?? '').toLowerCase();
    if (!_kAllowedExts.contains(ext)) {
      _toast(widget.l10n.cvFormatError, isError: true);
      return;
    }
    if (file.size > _kMaxSizeBytes) {
      _toast(widget.l10n.cvSizeError, isError: true);
      return;
    }
    final path = file.path;
    if (path == null) { _toast('Không thể đọc file.', isError: true); return; }
    final error = await ref.read(cvProvider.notifier).upload(path, file.name);
    if (!mounted) return;
    if (error == null) _toast(widget.l10n.cvUploadSuccess);
    else _toast(error, isError: true);
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content:         Text(msg),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final cvState = ref.watch(cvProvider);
    final l10n    = widget.l10n;
    final isDark  = widget.isDark;

    if (cvState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
              color: AppColors.brandPurple, strokeWidth: 2),
        ),
      );
    }
    if (cvState.isUploading) return _UploadingIndicator(isDark: isDark, l10n: l10n);
    if (cvState.hasCV) {
      return _CvCard(cv: cvState.cv!, isDark: isDark, l10n: l10n);
    }
    return _CvEmptyState(isDark: isDark, l10n: l10n, onUpload: _pickAndUpload);
  }
}

class _UploadingIndicator extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  const _UploadingIndicator({required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color:        AppColors.brandPurple.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(
            color: AppColors.brandPurple, strokeWidth: 2),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(l10n.cvUploading,
            style: TextStyle(
                color: isDark
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF374151),
                fontSize: 13)),
      ),
    ]),
  );
}

class _CvEmptyState extends StatelessWidget {
  final bool             isDark;
  final AppLocalizations l10n;
  final VoidCallback     onUpload;
  const _CvEmptyState(
      {required this.isDark, required this.l10n, required this.onUpload});

  @override
  Widget build(BuildContext context) => Container(
    width:   double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
    decoration: BoxDecoration(
      color:        isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(14),
      border:       Border.all(
          color: isDark ? AppColors.darkChip : AppColors.gray200),
    ),
    child: Column(children: [
      Icon(Icons.upload_file_rounded,
          size: 44,
          color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF)),
      const SizedBox(height: 10),
      Text(l10n.noCvYet,
          style: TextStyle(
              color:      AppColors.textPrimary(isDark),
              fontSize:   14,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(l10n.noCvHint,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: isDark
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF9CA3AF),
              fontSize: 12,
              height: 1.5)),
      const SizedBox(height: 4),
      Text(l10n.acceptedFormats,
          style: const TextStyle(color: Color(0xFF4A5578), fontSize: 11)),
      const SizedBox(height: 18),
      ElevatedButton.icon(
        onPressed: onUpload,
        icon:      const Icon(Icons.upload_rounded, size: 16),
        label:     Text(l10n.uploadCv),
        style:     ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPurple,
            foregroundColor: Colors.white,
            elevation:       0,
            shape:           RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:         const EdgeInsets.symmetric(
                horizontal: 20, vertical: 11)),
      ),
    ]),
  );
}

class _CvCard extends StatefulWidget {
  final CvData           cv;
  final bool             isDark;
  final AppLocalizations l10n;
  const _CvCard({required this.cv, required this.isDark, required this.l10n});

  @override
  State<_CvCard> createState() => _CvCardState();
}

class _CvCardState extends State<_CvCard> {
  static const _maxVisibleSkills = 8;
  bool _showAllSkills = false;

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final cv       = widget.cv;
    final isDark   = widget.isDark;
    final l10n     = widget.l10n;
    final labelC   = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final textC    = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final borderC  = AppColors.borderColor(isDark);

    final allSkills    = [...cv.skills, ...cv.techStack.where((s) => !cv.skills.contains(s))];
    final visibleSk    = _showAllSkills || allSkills.length <= _maxVisibleSkills
        ? allSkills
        : allSkills.take(_maxVisibleSkills).toList();
    final hiddenCnt    = allSkills.length - _maxVisibleSkills;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // File row
      Container(
        padding:    const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color:        isDark
                ? const Color(0xFF0D1117)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: borderC)),
        child: Row(children: [
          Icon(Icons.picture_as_pdf_rounded,
              size: 20,
              color: isDark ? const Color(0xFFA78BFA) : AppColors.brandPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cv.cvFileName ?? 'CV',
                    style: TextStyle(
                        color:      AppColors.textPrimary(isDark),
                        fontSize:   13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                if (cv.parsedAt != null) ...[
                  const SizedBox(height: 2),
                  Text('${l10n.cvParsedAt}: ${_formatDate(cv.parsedAt)}',
                      style: TextStyle(color: labelC, fontSize: 11)),
                ],
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              size: 18, color: Color(0xFF10B981)),
        ]),
      ),
      // Skills
      if (allSkills.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(l10n.cvSkillsLabel,
            style: TextStyle(
                color:         labelC,
                fontSize:      11,
                fontWeight:    FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 5, children: [
          ...visibleSk.map((s) => buildSkillTag(label: s, isDark: isDark)),
          if (!_showAllSkills && hiddenCnt > 0)
            GestureDetector(
              onTap: () => setState(() => _showAllSkills = true),
              child: _MutedSkillChip(label: '+$hiddenCnt', isDark: isDark),
            ),
          if (_showAllSkills && allSkills.length > _maxVisibleSkills)
            GestureDetector(
              onTap: () => setState(() => _showAllSkills = false),
              child: _MutedSkillChip(label: 'Thu gọn', isDark: isDark),
            ),
        ]),
      ],
      // AI Summary
      if (cv.summary != null && cv.summary!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(l10n.cvSummaryLabel,
            style: TextStyle(
                color:         labelC,
                fontSize:      11,
                fontWeight:    FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 6),
        Container(
          width:   double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:        AppColors.brandPurple.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(
                color: AppColors.brandPurple.withValues(alpha: 0.2)),
          ),
          child: Text(cv.summary!,
              style: TextStyle(color: textC, fontSize: 12, height: 1.6)),
        ),
      ],
    ]);
  }
}

class _MutedSkillChip extends StatelessWidget {
  final String label;
  final bool   isDark;
  const _MutedSkillChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color:        AppColors.chipBg(isDark),
      borderRadius: BorderRadius.circular(6),
      border:       Border.all(color: AppColors.borderColor(isDark)),
    ),
    child: Text(label,
        style: TextStyle(
            color: isDark
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
            fontSize:   12,
            fontWeight: FontWeight.w600)),
  );
}
