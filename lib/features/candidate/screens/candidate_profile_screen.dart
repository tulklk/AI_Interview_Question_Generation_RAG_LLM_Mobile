import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_elevated_card.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_skill_chip.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/storage_service.dart';

const _expLevels = [
  'Intern',
  'Fresher',
  'Junior',
  'Middle',
  'Senior',
  'Lead / Expert',
];

class CandidateProfileScreen extends ConsumerStatefulWidget {
  const CandidateProfileScreen({super.key});

  @override
  ConsumerState<CandidateProfileScreen> createState() =>
      _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends ConsumerState<CandidateProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _pwFormKey      = GlobalKey<FormState>();

  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _posCtrl      = TextEditingController();
  final _stackCtrl    = TextEditingController(); // comma-separated
  final _curPwCtrl    = TextEditingController();
  final _newPwCtrl    = TextEditingController();
  final _confPwCtrl   = TextEditingController();

  String? _expLevel;
  bool _isEditing    = false;
  bool _isSaving     = false;
  bool _isSavingPw   = false;
  bool _isLoggingOut = false;
  bool _showCurPw  = false;
  bool _showNewPw  = false;
  bool _showConfPw = false;

  String? _profileMsg;
  bool _profileSuccess = false;
  String? _pwMsg;
  bool _pwSuccess = false;

  @override
  void initState() {
    super.initState();
    _populateFromUser();
  }

  void _populateFromUser() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    _nameCtrl.text  = user.name;
    _phoneCtrl.text = user.phone ?? '';
    _posCtrl.text   = user.title ?? '';
    _stackCtrl.text = user.techStack?.join(', ') ?? '';
    _expLevel       = _expLevels.contains(user.experienceLevel)
        ? user.experienceLevel
        : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _posCtrl.dispose();
    _stackCtrl.dispose();
    _curPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confPwCtrl.dispose();
    super.dispose();
  }

  List<String> get _stackList => _stackCtrl.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _profileMsg = null; });
    try {
      final token = await StorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw ProfileException('Phiên đăng nhập hết hạn.');
      }
      await ProfileService.updateCandidateProfile(
        token:           token,
        fullName:        _nameCtrl.text.trim(),
        phone:           _phoneCtrl.text.trim(),
        targetPosition:  _posCtrl.text.trim(),
        experienceLevel: _expLevel,
        techStack:       _stackList.isEmpty ? null : _stackList,
      );
      final user = ref.read(authProvider).user!;
      ref.read(authProvider.notifier).updateUser(user.copyWith(
        name:            _nameCtrl.text.trim(),
        phone:           _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        title:           _posCtrl.text.trim().isEmpty ? null : _posCtrl.text.trim(),
        experienceLevel: _expLevel,
        techStack:       _stackList.isEmpty ? null : _stackList,
      ));
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _profileSuccess = true;
        _profileMsg = 'Hồ sơ đã được cập nhật thành công.';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() { _profileMsg = null; _profileSuccess = false; });
      });
    } on ProfileException catch (e) {
      if (mounted) setState(() { _profileSuccess = false; _profileMsg = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() { _profileSuccess = false; _profileMsg = 'Có lỗi xảy ra. Vui lòng thử lại.'; });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_pwFormKey.currentState!.validate()) return;
    setState(() { _isSavingPw = true; _pwMsg = null; });
    try {
      final token = await StorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw ProfileException('Phiên đăng nhập hết hạn.');
      }
      await ProfileService.changePassword(
        token:           token,
        currentPassword: _curPwCtrl.text,
        newPassword:     _newPwCtrl.text,
      );
      _curPwCtrl.clear();
      _newPwCtrl.clear();
      _confPwCtrl.clear();
      if (!mounted) return;
      setState(() { _pwSuccess = true; _pwMsg = 'Mật khẩu đã được thay đổi thành công.'; });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() { _pwMsg = null; _pwSuccess = false; });
      });
    } on ProfileException catch (e) {
      if (mounted) setState(() { _pwSuccess = false; _pwMsg = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() { _pwSuccess = false; _pwMsg = 'Có lỗi xảy ra. Vui lòng thử lại.'; });
      }
    } finally {
      if (mounted) setState(() => _isSavingPw = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A2235) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Xác nhận đăng xuất',
              style: AppTextStyles.h4.copyWith(
                  color: isDark ? Colors.white : AppColors.nearBlack)),
          content: Text('Bạn có chắc chắn muốn đăng xuất không?',
              style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hủy',
                  style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Đăng xuất',
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
    // GoRouter redirect handles navigation when auth.user becomes null (AC-04, AC-05)
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final isDark     = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _CandidateHeader(user: user, isDark: isDark)),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Profile message banner
                if (_profileMsg != null) ...[
                  _MessageBanner(message: _profileMsg!, success: _profileSuccess)
                      .animate().fadeIn(duration: 250.ms).slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 12),
                ],

                // ── Profile info / edit ────────────────────────────────
                AppElevatedCard(
                  interactive: false,
                  accentColor: AppColors.teal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(children: [
                        _SectionIcon(
                          icon: PhosphorIconsBold.identificationCard,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Thông tin hồ sơ',
                              style: AppTextStyles.h4.copyWith(
                                  color: isDark ? AppColors.white : AppColors.nearBlack)),
                        ),
                        if (!_isEditing)
                          _EditButton(
                            color: AppColors.teal,
                            onTap: () => setState(() => _isEditing = true),
                          ),
                      ]),
                      const SizedBox(height: 16),

                      if (!_isEditing) ...[
                        // View mode
                        _InfoRow('Email', user.email, isDark, locked: true),
                        _InfoRow('Họ tên', user.name.isEmpty ? '—' : user.name, isDark),
                        _InfoRow('Số điện thoại', user.phone ?? '—', isDark),
                        _InfoRow('Vị trí mục tiêu', user.title ?? '—', isDark),
                        _InfoRow('Kinh nghiệm', user.experienceLevel ?? '—', isDark),
                        const SizedBox(height: 4),
                        if (user.techStack != null && user.techStack!.isNotEmpty) ...[
                          Text('Tech Stack',
                              style: AppTextStyles.caption.copyWith(fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: user.techStack!
                                .map((s) => AppSkillChip(label: s))
                                .toList(),
                          ),
                        ] else
                          _InfoRow('Tech Stack', '—', isDark, last: true),
                      ] else ...[
                        // Edit mode
                        Form(
                          key: _profileFormKey,
                          child: Column(children: [
                            AppTextField(
                              label: 'Họ tên *',
                              hint: 'Nguyễn Văn A',
                              controller: _nameCtrl,
                              validator: (v) =>
                                  (v?.trim().isEmpty ?? true) ? 'Vui lòng nhập họ tên' : null,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'Số điện thoại',
                              hint: '+84 xxx xxx xxx',
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'Vị trí mục tiêu',
                              hint: 'Flutter Developer',
                              controller: _posCtrl,
                            ),
                            const SizedBox(height: 12),
                            // Experience level dropdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cấp độ kinh nghiệm',
                                    style: AppTextStyles.label.copyWith(
                                        color: isDark
                                            ? AppColors.white.withValues(alpha: 0.85)
                                            : AppColors.nearBlack)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  key: ValueKey(_expLevel),
                                  initialValue: _expLevel,
                                  hint: const Text('Chọn cấp độ'),
                                  isExpanded: true,
                                  items: _expLevels
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _expLevel = v),
                                  style: AppTextStyles.body.copyWith(
                                    color: isDark ? AppColors.white : AppColors.nearBlack,
                                    fontSize: 14,
                                  ),
                                  dropdownColor: isDark
                                      ? const Color(0xFF1D2440)
                                      : Colors.white,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'Tech Stack (phân cách bởi dấu phẩy)',
                              hint: 'Flutter, Dart, Firebase, REST API',
                              controller: _stackCtrl,
                              maxLines: 2,
                            ),
                            // Live chip preview
                            if (_stackList.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _stackList
                                    .map((s) => AppSkillChip(label: s))
                                    .toList(),
                              ),
                            ],
                          ]),
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                            child: _OutlineButton(
                              label: 'Hủy',
                              onTap: () {
                                _populateFromUser();
                                setState(() { _isEditing = false; _profileMsg = null; });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppGradientButton(
                              label: 'Lưu',
                              isLoading: _isSaving,
                              onTap: _isSaving ? null : _saveProfile,
                              height: 46,
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 80.ms),
                const SizedBox(height: 16),

                // ── Change password ───────────────────────────────────
                AppElevatedCard(
                  interactive: false,
                  accentColor: AppColors.deepBlue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _SectionIcon(
                          icon: PhosphorIconsBold.lockKey,
                          gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF6C47FF)]),
                        ),
                        const SizedBox(width: 10),
                        Text('Đổi mật khẩu',
                            style: AppTextStyles.h4.copyWith(
                                color: isDark ? AppColors.white : AppColors.nearBlack)),
                      ]),
                      const SizedBox(height: 16),
                      if (_pwMsg != null) ...[
                        _MessageBanner(message: _pwMsg!, success: _pwSuccess),
                        const SizedBox(height: 12),
                      ],
                      Form(
                        key: _pwFormKey,
                        child: Column(children: [
                          AppTextField(
                            label: 'Mật khẩu hiện tại *',
                            hint: '••••••••',
                            controller: _curPwCtrl,
                            obscureText: !_showCurPw,
                            suffix: _EyeToggle(
                              show: _showCurPw,
                              onToggle: () => setState(() => _showCurPw = !_showCurPw),
                            ),
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Mật khẩu mới *',
                            hint: '••••••••',
                            controller: _newPwCtrl,
                            obscureText: !_showNewPw,
                            suffix: _EyeToggle(
                              show: _showNewPw,
                              onToggle: () => setState(() => _showNewPw = !_showNewPw),
                            ),
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Vui lòng nhập mật khẩu mới';
                              if (v!.length < 6) return 'Tối thiểu 6 ký tự';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Xác nhận mật khẩu mới *',
                            hint: '••••••••',
                            controller: _confPwCtrl,
                            obscureText: !_showConfPw,
                            suffix: _EyeToggle(
                              show: _showConfPw,
                              onToggle: () => setState(() => _showConfPw = !_showConfPw),
                            ),
                            validator: (v) =>
                                v != _newPwCtrl.text ? 'Mật khẩu xác nhận không khớp' : null,
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      AppGradientButton(
                        label: 'Đổi mật khẩu',
                        isLoading: _isSavingPw,
                        onTap: _isSavingPw ? null : _savePassword,
                        height: 46,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 160.ms),
                const SizedBox(height: 16),

                // ── Settings ─────────────────────────────────────────
                AppElevatedCard(
                  interactive: false,
                  child: _SettingsRow(
                    icon: PhosphorIconsBold.moon,
                    label: 'Dark Mode',
                    gradient: const LinearGradient(
                        colors: [Color(0xFF6C47FF), Color(0xFF3B82F6)]),
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: isDarkMode,
                      onChanged: (v) => ref.read(themeProvider.notifier).setTheme(v ? ThemeMode.dark : ThemeMode.light),
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.brandPurple,
                    ),
                  ),
                ).animate().fadeIn(delay: 220.ms),
                const SizedBox(height: 24),

                AppGradientButton(
                  label: _isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất',
                  isLoading: _isLoggingOut,
                  onTap: _isLoggingOut ? null : _logout,
                  height: 52,
                ).animate().fadeIn(delay: 270.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile header ────────────────────────────────────────────────────────────

class _CandidateHeader extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  const _CandidateHeader({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0B1828), const Color(0xFF080A16)]
              : [const Color(0xFFDDFAF6), AppColors.offWhite],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)]),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.38),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
                child: AppAvatar(name: user.name, size: 82, showRing: false),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 14),
            Text(
              user.name.isEmpty ? 'Candidate' : user.name,
              style: AppTextStyles.h2.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 4),
            Text(
              user.title ?? 'Job Seeker',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.teal, fontWeight: FontWeight.w600),
            ).animate().fadeIn(delay: 140.ms),
            const SizedBox(height: 2),
            Text(
              user.email,
              style: AppTextStyles.caption.copyWith(color: AppColors.gray500),
            ).animate().fadeIn(delay: 170.ms),
          ]),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  const _SectionIcon({required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPurple.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 15, color: Colors.white),
      );
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  const _EditButton({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(PhosphorIconsBold.pencilSimple,
              size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text('Chỉnh sửa',
              style: AppTextStyles.caption.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.gray500 : AppColors.gray200,
          ),
        ),
        child: Center(
          child: Text(label,
              style: AppTextStyles.buttonText.copyWith(
                  color: isDark ? AppColors.white : AppColors.nearBlack)),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool locked;
  final bool last;
  const _InfoRow(this.label, this.value, this.isDark,
      {this.locked = false, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTextStyles.caption.copyWith(fontSize: 12)),
          ),
          Expanded(
            child: Row(children: [
              Flexible(
                child: Text(value,
                    style: AppTextStyles.label.copyWith(
                      color: isDark ? AppColors.white : AppColors.nearBlack,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              if (locked) ...[
                const SizedBox(width: 6),
                const Icon(PhosphorIconsBold.lockSimple,
                    size: 11, color: AppColors.gray400),
              ],
            ]),
          ),
        ]),
        if (!last) ...[
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.gray200.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String message;
  final bool success;
  const _MessageBanner({required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.teal : AppColors.error;
    final icon  = success
        ? PhosphorIconsBold.checkCircle
        : PhosphorIconsBold.warningCircle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: AppTextStyles.caption
                  .copyWith(color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _EyeToggle extends StatelessWidget {
  final bool show;
  final VoidCallback onToggle;
  const _EyeToggle({required this.show, required this.onToggle});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(
          show ? PhosphorIconsBold.eyeSlash : PhosphorIconsBold.eye,
          size: 18,
          color: AppColors.gray400,
        ),
        onPressed: onToggle,
      );
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String label;
  final bool isDark;
  final Widget trailing;
  const _SettingsRow({
    required this.icon,
    required this.gradient,
    required this.label,
    required this.isDark,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPurple.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: AppTextStyles.label.copyWith(
                    color: isDark ? AppColors.white : AppColors.nearBlack)),
          ),
          trailing,
        ]),
      );
}
