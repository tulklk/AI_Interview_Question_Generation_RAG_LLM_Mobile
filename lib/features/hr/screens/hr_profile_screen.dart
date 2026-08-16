import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/storage_service.dart';
import '../../subscription/subscription_provider.dart';

// ── Main screen ───────────────────────────────────────────────────────────────

class HRProfileScreen extends ConsumerStatefulWidget {
  const HRProfileScreen({super.key});

  @override
  ConsumerState<HRProfileScreen> createState() => _HRProfileScreenState();
}

class _HRProfileScreenState extends ConsumerState<HRProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A2235) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.signOutTitle,
              style: AppTextStyles.h4.copyWith(
                  color: isDark ? Colors.white : AppColors.nearBlack)),
          content: Text(l10n.signOutBody,
              style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel,
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.logout,
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.error, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoggingOut = true);
    await ref.read(authProvider.notifier).logout();
  }

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context:             context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user:       ref.read(authProvider).user!,
        onSaved:   () {},
        authNotifier: ref.read(authProvider.notifier),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _showPersonalInfoSheet(BuildContext context, dynamic user, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) {
        final bg = isDark ? const Color(0xFF1A2235) : Colors.white;
        return Container(
          decoration: BoxDecoration(
              color:        bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).padding.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            Text(l10n.personalInformation,
                style: AppTextStyles.h4.copyWith(
                    color: isDark ? Colors.white : AppColors.nearBlack)),
            const SizedBox(height: 20),
            _InfoTile(label: 'Email',              value: user.email,                        isDark: isDark, locked: true),
            _InfoTile(label: l10n.fullName,        value: user.name.isEmpty ? '—' : user.name, isDark: isDark),
            _InfoTile(label: l10n.phoneNumber,     value: user.phone ?? '—',                 isDark: isDark),
            _InfoTile(label: l10n.company,         value: user.company ?? '—',               isDark: isDark),
            _InfoTile(label: l10n.jobTitle,        value: user.title ?? '—',                 isDark: isDark, last: true),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user      = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);
    final lang      = ref.watch(languageProvider);
    final l10n      = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // ── Profile header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeaderCard(user: user, isDark: isDark)
                .animate().fadeIn(duration: 300.ms),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Account ─────────────────────────────────────────────────
                _SectionLabel(l10n.account, isDark: isDark),
                const SizedBox(height: 8),
                _MenuCard(isDark: isDark, children: [
                  _MenuItem(
                    icon:   PhosphorIconsBold.userCircle,
                    label:  l10n.manageProfile,
                    isDark: isDark,
                    onTap:  () => _showEditProfileSheet(context),
                  ),
                  _MenuDivider(isDark: isDark),
                  _MenuItem(
                    icon:   PhosphorIconsBold.identificationCard,
                    label:  l10n.personalInformation,
                    isDark: isDark,
                    onTap:  () => _showPersonalInfoSheet(context, user, isDark),
                  ),
                ]).animate().fadeIn(delay: 60.ms),
                const SizedBox(height: 20),

                // ── Subscription ─────────────────────────────────────────────
                _SectionLabel(l10n.subscriptionPlan, isDark: isDark),
                const SizedBox(height: 8),
                _MenuCard(isDark: isDark, children: [
                  _MenuItem(
                    icon:        PhosphorIconsBold.crown,
                    label:       l10n.currentPlan,
                    isDark:      isDark,
                    showChevron: false,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PlanBadgeWidget(),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size:  20,
                          color: isDark ? AppColors.gray500 : AppColors.gray400,
                        ),
                      ],
                    ),
                    onTap: () => context.go('/hr/subscription'),
                  ),
                ]).animate().fadeIn(delay: 90.ms),
                const SizedBox(height: 20),

                // ── Preferences ──────────────────────────────────────────────
                _SectionLabel(l10n.settings, isDark: isDark),
                const SizedBox(height: 8),
                _MenuCard(isDark: isDark, children: [
                  _MenuItem(
                    icon:   PhosphorIconsBold.bell,
                    label:  l10n.notificationsSection,
                    isDark: isDark,
                    onTap:  () {},
                  ),
                  _MenuDivider(isDark: isDark),
                  _MenuItem(
                    icon:        PhosphorIconsBold.globe,
                    label:       l10n.language,
                    isDark:      isDark,
                    showChevron: false,
                    trailing: GestureDetector(
                      onTap: () => ref.read(languageProvider.notifier).toggle(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandPurple.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                              color: AppColors.brandPurple.withValues(alpha: 0.28)),
                        ),
                        child: Text(
                          lang == 'vi' ? 'VI' : 'EN',
                          style: TextStyle(
                            color:      AppColors.brandPurple,
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    onTap: () => ref.read(languageProvider.notifier).toggle(),
                  ),
                  _MenuDivider(isDark: isDark),
                  _MenuItem(
                    icon:        PhosphorIconsBold.moon,
                    label:       l10n.theme,
                    isDark:      isDark,
                    showChevron: false,
                    trailing: Switch.adaptive(
                      value:    themeMode == ThemeMode.dark,
                      onChanged: (v) => ref.read(themeProvider.notifier)
                          .setTheme(v ? ThemeMode.dark : ThemeMode.light),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.brandPurple,
                    ),
                    onTap: null,
                  ),
                ]).animate().fadeIn(delay: 120.ms),
                const SizedBox(height: 20),

                // ── Security ─────────────────────────────────────────────────
                _SectionLabel(l10n.securityTab, isDark: isDark),
                const SizedBox(height: 8),
                _MenuCard(isDark: isDark, children: [
                  _MenuItem(
                    icon:   PhosphorIconsBold.lockKey,
                    label:  l10n.changePassword,
                    isDark: isDark,
                    onTap:  () => _showChangePasswordSheet(context),
                  ),
                ]).animate().fadeIn(delay: 160.ms),
                const SizedBox(height: 28),

                // ── Logout ───────────────────────────────────────────────────
                SizedBox(
                  width:  double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width:  16,
                            height: 16,
                            child:  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:       Color(0xFFEF4444)))
                        : const Icon(PhosphorIconsBold.signOut,
                            size: 17, color: Color(0xFFEF4444)),
                    label: Text(
                      _isLoggingOut ? l10n.signingOut : l10n.logout,
                      style: const TextStyle(
                          color:      Color(0xFFEF4444),
                          fontSize:   14,
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile header card ───────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  const _ProfileHeaderCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF0F1629) : const Color(0xFFF8F7FF),
      padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.of(context).padding.top + 20,
          24,
          28),
      child: Column(children: [
        // Avatar with gradient ring
        Container(
          padding:    const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color:      AppColors.brandPurple.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: -4,
                offset:     const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding:    const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.white),
            child: AppAvatar(name: user.name, size: 78, showRing: false),
          ),
        ).animate().scale(duration: 380.ms, curve: Curves.elasticOut),
        const SizedBox(height: 14),
        Text(
          user.name.isEmpty ? 'HR Manager' : user.name,
          style: AppTextStyles.h2.copyWith(
              color: isDark ? Colors.white : AppColors.nearBlack,
              fontSize: 20),
        ).animate().fadeIn(delay: 80.ms),
        const SizedBox(height: 3),
        if (user.title != null && user.title!.isNotEmpty) ...[
          Text(
            user.title!,
            style: AppTextStyles.body.copyWith(
                color: AppColors.brandPurple, fontWeight: FontWeight.w600),
          ).animate().fadeIn(delay: 110.ms),
          const SizedBox(height: 2),
        ],
        Text(
          user.email,
          style: AppTextStyles.caption.copyWith(color: AppColors.gray500),
        ).animate().fadeIn(delay: 130.ms),
        const SizedBox(height: 14),
        // Company chip
        if (user.company != null && user.company!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color:        AppColors.brandPurple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.brandPurple.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(PhosphorIconsBold.buildings,
                  size: 11, color: AppColors.brandPurple),
              const SizedBox(width: 5),
              Text(user.company!,
                  style: TextStyle(
                      color:      AppColors.brandPurple,
                      fontSize:   12,
                      fontWeight: FontWeight.w600)),
            ]),
          ).animate().fadeIn(delay: 150.ms),
      ]),
    );
  }
}

// ── Edit profile bottom sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final dynamic user;
  final VoidCallback onSaved;
  final dynamic authNotifier;
  const _EditProfileSheet({
    required this.user,
    required this.onSaved,
    required this.authNotifier,
  });

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey    = GlobalKey<FormState>();
  late final _nameCtrl    = TextEditingController(text: widget.user.name);
  late final _phoneCtrl   = TextEditingController(text: widget.user.phone ?? '');
  late final _companyCtrl = TextEditingController(text: widget.user.company ?? '');
  late final _titleCtrl   = TextEditingController(text: widget.user.title ?? '');
  bool _saving = false;
  String? _msg;
  bool _success = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _companyCtrl.dispose(); _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() { _saving = true; _msg = null; });
    try {
      final token = await StorageService.getAccessToken();
      if (token == null || token.isEmpty) throw ProfileException(l10n.sessionExpired);
      await ProfileService.updateHRProfile(
        token:    token,
        fullName: _nameCtrl.text.trim(),
        phone:    _phoneCtrl.text.trim(),
        company:  _companyCtrl.text.trim(),
        jobTitle: _titleCtrl.text.trim(),
      );
      final user = ref.read(authProvider).user!;
      ref.read(authProvider.notifier).updateUser(user.copyWith(
        name:    _nameCtrl.text.trim(),
        phone:   _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        company: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
        title:   _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      ));
      if (!mounted) return;
      setState(() { _success = true; _msg = l10n.profileUpdated; });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    } on ProfileException catch (e) {
      if (mounted) setState(() { _success = false; _msg = e.message; });
    } catch (_) {
      if (mounted) setState(() { _success = false; _msg = AppLocalizations.of(context)!.genericError; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF1A2235) : Colors.white;
    final mq     = MediaQuery.of(context);
    final l10n   = AppLocalizations.of(context)!;

    return Container(
      height:     mq.size.height * 0.88,
      decoration: BoxDecoration(
          color:        bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        _SheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(children: [
            Text(l10n.manageProfile,
                style: AppTextStyles.h4.copyWith(
                    color: isDark ? Colors.white : AppColors.nearBlack)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close_rounded,
                  color: isDark ? AppColors.gray400 : AppColors.gray500),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, mq.padding.bottom + 20),
            child: Form(
              key: _formKey,
              child: Column(children: [
                if (_msg != null) ...[
                  _StatusBanner(message: _msg!, success: _success),
                  const SizedBox(height: 14),
                ],
                AppTextField(
                  label:     '${l10n.fullName} *',
                  hint:      'Nguyễn Văn A',
                  controller: _nameCtrl,
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Vui lòng nhập họ tên' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label:        l10n.phoneNumber,
                  hint:         '+84 xxx xxx xxx',
                  controller:   _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label:      l10n.company,
                  hint:       'FPT Software',
                  controller: _companyCtrl,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label:      l10n.jobTitle,
                  hint:       'Senior HR Manager',
                  controller: _titleCtrl,
                ),
                const SizedBox(height: 20),
                AppGradientButton(
                  label:     l10n.saveChanges_,
                  isLoading: _saving,
                  onTap:     _saving ? null : _save,
                  height:    50,
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Change password bottom sheet ──────────────────────────────────────────────

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey      = GlobalKey<FormState>();
  final _curPwCtrl    = TextEditingController();
  final _newPwCtrl    = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _saving       = false;
  bool _showCur      = false;
  bool _showNew      = false;
  bool _showConf     = false;
  String? _msg;
  bool _success      = false;

  @override
  void dispose() {
    _curPwCtrl.dispose(); _newPwCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() { _saving = true; _msg = null; });
    try {
      final token = await StorageService.getAccessToken();
      if (token == null || token.isEmpty) throw ProfileException(l10n.sessionExpired);
      await ProfileService.changePassword(
        token:           token,
        currentPassword: _curPwCtrl.text,
        newPassword:     _newPwCtrl.text,
      );
      _curPwCtrl.clear(); _newPwCtrl.clear(); _confirmCtrl.clear();
      if (!mounted) return;
      setState(() { _success = true; _msg = l10n.passwordChanged; });
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop();
    } on ProfileException catch (e) {
      if (mounted) setState(() { _success = false; _msg = e.message; });
    } catch (_) {
      if (mounted) setState(() { _success = false; _msg = AppLocalizations.of(context)!.genericError; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF1A2235) : Colors.white;
    final mq     = MediaQuery.of(context);
    final l10n   = AppLocalizations.of(context)!;

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
            Text(l10n.changePassword,
                style: AppTextStyles.h4.copyWith(
                    color: isDark ? Colors.white : AppColors.nearBlack)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close_rounded,
                  color: isDark ? AppColors.gray400 : AppColors.gray500),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
          const SizedBox(height: 8),
          if (_msg != null) ...[
            _StatusBanner(message: _msg!, success: _success),
            const SizedBox(height: 12),
          ],
          Form(
            key: _formKey,
            child: Column(children: [
              AppTextField(
                label:       '${l10n.currentPasswordLabel} *',
                hint:        '••••••••',
                controller:  _curPwCtrl,
                obscureText: !_showCur,
                suffix: IconButton(
                  icon: Icon(
                    _showCur ? PhosphorIconsBold.eyeSlash : PhosphorIconsBold.eye,
                    size: 18, color: AppColors.gray400),
                  onPressed: () => setState(() => _showCur = !_showCur),
                ),
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label:       '${l10n.newPasswordLabel} *',
                hint:        '••••••••',
                controller:  _newPwCtrl,
                obscureText: !_showNew,
                suffix: IconButton(
                  icon: Icon(
                    _showNew ? PhosphorIconsBold.eyeSlash : PhosphorIconsBold.eye,
                    size: 18, color: AppColors.gray400),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Vui lòng nhập mật khẩu mới';
                  if (v!.length < 6) return 'Tối thiểu 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label:       '${l10n.confirmPasswordLabel} *',
                hint:        '••••••••',
                controller:  _confirmCtrl,
                obscureText: !_showConf,
                suffix: IconButton(
                  icon: Icon(
                    _showConf ? PhosphorIconsBold.eyeSlash : PhosphorIconsBold.eye,
                    size: 18, color: AppColors.gray400),
                  onPressed: () => setState(() => _showConf = !_showConf),
                ),
                validator: (v) =>
                    v != _newPwCtrl.text ? 'Mật khẩu xác nhận không khớp' : null,
              ),
            ]),
          ),
          const SizedBox(height: 20),
          AppGradientButton(
            label:     l10n.changePassword,
            isLoading: _saving,
            onTap:     _saving ? null : _save,
            height:    50,
          ),
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
              ),
            ],
    ),
    child: Column(children: children),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData      icon;
  final String        label;
  final bool          isDark;
  final bool          showChevron;
  final Widget?       trailing;
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
          // Icon container
          Container(
            width:  38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.textPrimary(isDark)),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:      AppColors.textPrimary(isDark),
                fontSize:   14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Trailing widget or chevron
          if (trailing != null)
            trailing!
          else if (showChevron)
            Icon(
              Icons.chevron_right_rounded,
              size:  20,
              color: isDark ? AppColors.gray500 : AppColors.gray400,
            ),
        ]),
      ),
    ),
  );
}

class _MenuDivider extends StatelessWidget {
  final bool isDark;
  const _MenuDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 64,
    color:  AppColors.borderColor(isDark),
  );
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 10),
      width:  36,
      height: 4,
      decoration: BoxDecoration(
        color:        Colors.grey.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool   isDark;
  final bool   locked;
  final bool   last;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.isDark,
    this.locked = false,
    this.last   = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
        child: Row(children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.gray500 : AppColors.gray400,
                    fontSize: 12)),
          ),
          Expanded(
            child: Row(children: [
              Flexible(
                child: Text(value,
                    style: AppTextStyles.label.copyWith(
                      color:      isDark ? Colors.white : AppColors.nearBlack,
                      fontWeight: FontWeight.w500,
                    )),
              ),
              if (locked) ...[
                const SizedBox(width: 5),
                Icon(PhosphorIconsBold.lockSimple,
                    size: 11, color: AppColors.gray400),
              ],
            ]),
          ),
        ]),
      ),
      if (!last)
        Divider(
          height: 1,
          color:  isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.gray200,
        ),
    ],
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
              style: AppTextStyles.caption.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
