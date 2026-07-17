import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/auth_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/company_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_widgets.dart' hide AuthBackground;
import 'google_profile_sheet.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // 0 = HR Manager, 1 = Ứng viên
  int _roleIndex = 0;
  int _step      = 1;
  bool _isLoading = false;
  String? _apiError;

  // Step 1 — credentials
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  // Step 1 — errors
  String? _emailError;
  String? _passError;
  String? _confirmError;

  // Step 2 — HR profile
  final _fullNameCtrl  = TextEditingController();
  final _companyCtrl   = TextEditingController();
  final _jobTitleCtrl  = TextEditingController();
  bool _agreedTerms    = false;
  String? _selectedCompanyId;

  // Step 2 — Candidate profile
  final _targetRoleCtrl = TextEditingController();
  String _seniority     = 'Junior';
  final Set<String> _techStack = {};

  // Step 2 — errors
  String? _fullNameError;
  String? _companyError;
  String? _targetRoleError;

  late AnimationController _stepAnim;

  @override
  void initState() {
    super.initState();
    _stepAnim = AnimationController(
        vsync: this, duration: AuthAnimations.stepSlide);
    _passCtrl.addListener(() => setState(() {}));
    _confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _fullNameCtrl.dispose();
    _companyCtrl.dispose();
    _jobTitleCtrl.dispose();
    _targetRoleCtrl.dispose();
    _stepAnim.dispose();
    super.dispose();
  }

  void _onRoleChanged(int index) {
    if (_roleIndex == index) return;
    setState(() {
      _roleIndex = index;
      _step = 1;
      _apiError = null;
      _clearStep1Errors();
      _clearStep2Errors();
    });
  }

  void _clearStep1Errors() {
    _emailError = null;
    _passError  = null;
    _confirmError = null;
  }

  void _clearStep2Errors() {
    _fullNameError    = null;
    _companyError     = null;
    _targetRoleError  = null;
  }

  // ── Validation ──────────────────────────────────────────────────────────

  bool _validateStep1() {
    final email    = _emailCtrl.text.trim();
    final pass     = _passCtrl.text;
    final confirm  = _confirmCtrl.text;
    final emailRgx = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
    bool ok = true;
    setState(() {
      _emailError   = email.isEmpty   ? 'Vui lòng nhập email'
          : !emailRgx.hasMatch(email) ? 'Địa chỉ email không hợp lệ'
          : null;
      _passError    = pass.isEmpty
          ? 'Vui lòng nhập mật khẩu'
          : pass.length < 8
              ? 'Tối thiểu 8 ký tự'
              : !pass.contains(RegExp(r'[A-Z]'))
                  ? 'Cần ít nhất 1 chữ hoa (A-Z)'
                  : !pass.contains(RegExp(r'[a-z]'))
                      ? 'Cần ít nhất 1 chữ thường (a-z)'
                      : !pass.contains(RegExp(r'[0-9]'))
                          ? 'Cần ít nhất 1 chữ số (0-9)'
                          : !pass.contains(RegExp(r'[^A-Za-z0-9]'))
                              ? 'Cần ít nhất 1 ký tự đặc biệt (!@#...)'
                              : null;
      _confirmError = confirm.isEmpty ? 'Vui lòng xác nhận mật khẩu'
          : confirm != pass           ? 'Mật khẩu xác nhận không khớp'
          : null;
      if (_emailError != null || _passError != null || _confirmError != null) {
        ok = false;
      }
    });
    return ok;
  }

  bool _validateStep2() {
    bool ok = true;
    setState(() {
      _fullNameError = _fullNameCtrl.text.trim().isEmpty
          ? 'Vui lòng nhập họ tên'
          : null;
      if (_roleIndex == 0) {
        _companyError = _companyCtrl.text.trim().isEmpty
            ? 'Vui lòng nhập tên công ty'
            : null;
      } else {
        _targetRoleError = _targetRoleCtrl.text.trim().isEmpty
            ? 'Vui lòng nhập vị trí mục tiêu'
            : null;
      }
      if (_fullNameError != null ||
          _companyError != null ||
          _targetRoleError != null) {
        ok = false;
      }
    });
    return ok;
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  Future<void> _nextStep() async {
    if (_step == 1) {
      if (!_validateStep1()) return;
      setState(() { _step = 2; _apiError = null; });
      return;
    }
    // Step 2 → submit
    if (!_validateStep2()) return;
    setState(() { _isLoading = true; _apiError = null; });
    try {
      if (_roleIndex == 0) {
        await AuthService.registerHR(
          email:           _emailCtrl.text.trim(),
          password:        _passCtrl.text,
          confirmPassword: _confirmCtrl.text,
          fullName:        _fullNameCtrl.text.trim(),
          companyName:     _companyCtrl.text.trim(),
          companyId:       _selectedCompanyId,
          jobTitle:        _jobTitleCtrl.text.trim(),
        );
      } else {
        await AuthService.registerCandidate(
          email:           _emailCtrl.text.trim(),
          password:        _passCtrl.text,
          confirmPassword: _confirmCtrl.text,
          fullName:        _fullNameCtrl.text.trim(),
          targetRole:      _targetRoleCtrl.text.trim(),
          seniorityLevel:  _seniority,
          techStack:       _techStack.toList(),
        );
      }
      if (!mounted) return;
      context.go(
          '/verify-email?email=${Uri.encodeComponent(_emailCtrl.text.trim())}');
    } on AuthException catch (e) {
      if (!mounted) return;
      final isEmailError =
          e.message.toLowerCase().contains('email') ||
          e.type == AuthErrorType.invalidCredentials;
      setState(() {
        _isLoading = false;
        if (isEmailError) {
          _emailError = e.message;
          _step = 1; // go back so user can fix email
        } else {
          _apiError = e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading   = false;
        _apiError    = 'Có lỗi xảy ra. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _continueWithGoogle() async {
    try {
      final account = await GoogleSignIn(
        serverClientId: AppConstants.googleServerClientId,
      ).signIn();
      if (account == null) return;

      final auth    = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        setState(() => _apiError = 'Không thể lấy thông tin từ Google. Vui lòng thử lại.');
        return;
      }

      setState(() { _isLoading = true; _apiError = null; });

      // Verify: check if account already exists
      final verify = await AuthService.verifyGoogleToken(idToken);

      if (!mounted) return;

      if (verify.isExistingUser) {
        // Already registered → log them in directly
        setState(() => _isLoading = false);
        await ref.read(authProvider.notifier).loginWithGoogle(idToken);
        return;
      }

      // New account → show profile completion sheet
      setState(() => _isLoading = false);
      final profile = await showGoogleProfileSheet(
        context,
        email: verify.email ?? account.email,
        name:  verify.name  ?? account.displayName ?? '',
      );
      if (!mounted || profile == null) return;

      // Register + login via Google OAuth
      await ref.read(authProvider.notifier).loginWithGoogle(
        idToken,
        profile: profile,
      );
      // GoRouter redirect handles navigation after user is set
    } on AuthException catch (e) {
      if (mounted) setState(() { _isLoading = false; _apiError = e.message; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _apiError  = 'Đăng ký với Google thất bại. Vui lòng thử lại.';
        });
      }
    }
  }

  void _back() {
    setState(() { _step = 1; _apiError = null; _clearStep2Errors(); });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthBackground(
      isDark: isDark,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Column(children: [
            AuthLogo(isDark: isDark)
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms),
            const SizedBox(height: 24),

            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back (step 2)
                  if (_step == 2) ...[
                    GestureDetector(
                      onTap: _back,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(PhosphorIconsBold.arrowLeft,
                            size: 14, color: AppColors.brandPurple),
                        const SizedBox(width: 4),
                        Text('Quay lại',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.brandPurple,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ).animate().fadeIn(duration: 200.ms),
                    const SizedBox(height: 14),
                  ],

                  // Role tabs
                  _RoleSegmentedTabs(
                    selectedIndex: _roleIndex,
                    onChanged: _onRoleChanged,
                    isDark: isDark,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 20),

                  // Step indicator
                  _WizardStepIndicator(
                    currentStep: _step,
                    isDark: isDark,
                    labels: const ['Tài khoản', 'Hồ sơ'],
                  ).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 20),

                  // Title
                  AnimatedHeading(
                    text: 'Tạo tài khoản',
                    style: AppTextStyles.h1.copyWith(
                        color: isDark ? Colors.white : AppColors.nearBlack,
                        fontSize: 24,
                        fontWeight: FontWeight.w800),
                    initialDelay: 380.ms,
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: AuthAnimations.tabSwitch,
                    child: Text(
                      _step == 1
                          ? (_roleIndex == 0
                              ? 'Kết nối với hàng nghìn nhà tuyển dụng dùng HireGen AI'
                              : 'Bắt đầu hành trình luyện phỏng vấn của bạn')
                          : (_roleIndex == 0
                              ? 'Cho chúng tôi biết thêm về bạn và công ty'
                              : 'Giúp chúng tôi cá nhân hóa trải nghiệm của bạn'),
                      key: ValueKey('$_roleIndex-$_step'),
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.gray500, fontSize: 14),
                    ),
                  ).animate().fadeIn(delay: 550.ms),
                  const SizedBox(height: 24),

                  // API error banner
                  if (_apiError != null) ...[
                    AuthErrorBanner(message: _apiError!, isDark: isDark)
                        .animate()
                        .fadeIn(duration: 250.ms)
                        .slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 14),
                  ],

                  // Form (animated step switch)
                  AnimatedSwitcher(
                    duration: AuthAnimations.stepSlide,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: anim,
                            curve: AuthAnimations.easeOutCubic)),
                        child: child,
                      ),
                    ),
                    child: _step == 1
                        ? _Step1Form(
                            key: const ValueKey('step1'),
                            emailCtrl:      _emailCtrl,
                            passCtrl:       _passCtrl,
                            confirmCtrl:    _confirmCtrl,
                            obscurePass:    _obscurePass,
                            obscureConfirm: _obscureConfirm,
                            isHR:           _roleIndex == 0,
                            password:       _passCtrl.text,
                            confirmText:    _confirmCtrl.text,
                            emailError:     _emailError,
                            passError:      _passError,
                            confirmError:   _confirmError,
                            onTogglePass:   () => setState(() => _obscurePass = !_obscurePass),
                            onToggleConfirm:() => setState(() => _obscureConfirm = !_obscureConfirm),
                          )
                        : _roleIndex == 0
                            ? _HRStep2Form(
                                key: const ValueKey('step2hr'),
                                fullNameCtrl:  _fullNameCtrl,
                                companyCtrl:   _companyCtrl,
                                jobTitleCtrl:  _jobTitleCtrl,
                                agreedTerms:   _agreedTerms,
                                isDark:        isDark,
                                fullNameError: _fullNameError,
                                companyError:  _companyError,
                                onToggleTerms: () =>
                                    setState(() => _agreedTerms = !_agreedTerms),
                                onCompanyPicked: (c) =>
                                    setState(() => _selectedCompanyId = c.id),
                              )
                            : _CandidateStep2Form(
                                key: const ValueKey('step2cand'),
                                fullNameCtrl:    _fullNameCtrl,
                                targetRoleCtrl:  _targetRoleCtrl,
                                seniority:       _seniority,
                                techStack:       _techStack,
                                isDark:          isDark,
                                fullNameError:   _fullNameError,
                                targetRoleError: _targetRoleError,
                                onSeniorityChanged: (v) =>
                                    setState(() => _seniority = v),
                                onTechToggled: (t) => setState(() =>
                                    _techStack.contains(t)
                                        ? _techStack.remove(t)
                                        : _techStack.add(t)),
                              ),
                  ),
                  const SizedBox(height: 20),

                  // Main CTA
                  ShimmerButton(
                    label: _step == 1 ? 'Tiếp tục' : 'Tạo tài khoản',
                    isLoading: _isLoading,
                    onTap: _isLoading ? null : _nextStep,
                    trailingIcon: _step == 1
                        ? PhosphorIconsBold.arrowRight
                        : PhosphorIconsBold.checkCircle,
                  ),
                  const SizedBox(height: 18),

                  // Social (only step 1)
                  if (_step == 1) ...[
                    AuthOrDivider(isDark: isDark, text: 'hoặc tiếp tục với'),
                    const SizedBox(height: 14),
                    AuthSocialButton(
                      label: 'Tiếp tục với Google',
                      leading: const GoogleLogoIcon(),
                      isDark: isDark,
                      onTap: _continueWithGoogle,
                      height: 48,
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Sign-in link
                  Center(
                    child: Wrap(alignment: WrapAlignment.center, children: [
                      Text('Đã có tài khoản? ',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.gray500, fontSize: 13)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text('Đăng nhập',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.brandPurple,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ]),
                  ),
                ],
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 700.ms, curve: AuthAnimations.easeOutCubic)
                .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 700.ms,
                    curve: AuthAnimations.easeOutCubic)
                .scale(
                    begin: const Offset(0.97, 0.97),
                    end: const Offset(1, 1),
                    duration: 700.ms,
                    curve: AuthAnimations.easeOutCubic),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// ─── Role tabs ────────────────────────────────────────────────────────────────

class _RoleSegmentedTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;
  const _RoleSegmentedTabs(
      {required this.selectedIndex,
      required this.onChanged,
      required this.isDark});

  static const _labels = ['HR Manager', 'Ứng viên'];
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final pillW = (constraints.maxWidth - _gap * 3) / 2;
          return Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A2235)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: const Cubic(0.34, 1.56, 0.64, 1),
                left: _gap + selectedIndex * (pillW + _gap),
                top: _gap,
                width: pillW,
                height: 44 - _gap * 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPurple.withValues(alpha: 0.40),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  _labels.length,
                  (i) => Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(i),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        height: 44,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: AppTextStyles.label.copyWith(
                              color: selectedIndex == i
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.50)
                                      : AppColors.gray500),
                              fontWeight: selectedIndex == i
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                            child: Text(_labels[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          );
        },
      );
}

// ─── Wizard step indicator ────────────────────────────────────────────────────

class _WizardStepIndicator extends StatelessWidget {
  final int currentStep;
  final bool isDark;
  final List<String> labels;
  const _WizardStepIndicator(
      {required this.currentStep,
      required this.isDark,
      required this.labels});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _StepBubble(
              number: 1,
              label: labels[0],
              state: currentStep > 1
                  ? _StepState.done
                  : currentStep == 1
                      ? _StepState.active
                      : _StepState.idle,
              isDark: isDark),
          Expanded(
              child: AnimatedContainer(
            duration: AuthAnimations.stepSlide,
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: currentStep >= 2
                  ? AppColors.primaryGradient
                  : LinearGradient(colors: [
                      isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB),
                      isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB),
                    ]),
            ),
          )),
          _StepBubble(
              number: 2,
              label: labels[1],
              state: currentStep > 2
                  ? _StepState.done
                  : currentStep == 2
                      ? _StepState.active
                      : _StepState.idle,
              isDark: isDark),
        ],
      );
}

enum _StepState { idle, active, done }

class _StepBubble extends StatefulWidget {
  final int number;
  final String label;
  final _StepState state;
  final bool isDark;
  const _StepBubble(
      {required this.number,
      required this.label,
      required this.state,
      required this.isDark});

  @override
  State<_StepBubble> createState() => _StepBubbleState();
}

class _StepBubbleState extends State<_StepBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    if (widget.state == _StepState.active) _pulse.repeat();
  }

  @override
  void didUpdateWidget(_StepBubble old) {
    super.didUpdateWidget(old);
    if (widget.state == _StepState.active && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (widget.state != _StepState.active && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.state == _StepState.active;
    final isDone   = widget.state == _StepState.done;
    final color    = isDone
        ? AppColors.success
        : isActive
            ? AppColors.brandPurple
            : (widget.isDark
                ? const Color(0xFF374151)
                : const Color(0xFFD1D5DB));

    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 48,
        height: 48,
        child: Stack(alignment: Alignment.center, children: [
          if (isActive)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final t    = _pulse.value;
                final size = 28.0 + t * 18;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.brandPurple
                          .withValues(alpha: (1 - t) * 0.45),
                      width: 1.5,
                    ),
                  ),
                );
              },
            ),
          if (isActive)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final t    = (_pulse.value + 0.5) % 1.0;
                final size = 28.0 + t * 18;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.brandPurple
                          .withValues(alpha: (1 - t) * 0.25),
                      width: 1.0,
                    ),
                  ),
                );
              },
            ),
          AnimatedContainer(
            duration: AuthAnimations.stepSlide,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isActive || isDone) ? color : Colors.transparent,
              border: Border.all(color: color, width: 1.5),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                          color: AppColors.brandPurple.withValues(alpha: 0.40),
                          blurRadius: 12,
                          spreadRadius: 0)
                    ]
                  : isDone
                      ? [
                          BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.35),
                              blurRadius: 8)
                        ]
                      : null,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : Text('${widget.number}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: (isActive || isDone)
                              ? Colors.white
                              : (widget.isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : AppColors.gray400))),
            ),
          ),
        ]),
      ),
      Text(widget.label,
          style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: isActive
                  ? AppColors.brandPurple
                  : isDone
                      ? AppColors.success
                      : (widget.isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppColors.gray400),
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }
}

// ─── Step 1: credentials ──────────────────────────────────────────────────────

class _Step1Form extends StatelessWidget {
  final TextEditingController emailCtrl, passCtrl, confirmCtrl;
  final bool obscurePass, obscureConfirm, isHR;
  final String password;
  final String confirmText;
  final String? emailError, passError, confirmError;
  final VoidCallback onTogglePass, onToggleConfirm;

  const _Step1Form({
    super.key,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.isHR,
    required this.password,
    required this.confirmText,
    this.emailError,
    this.passError,
    this.confirmError,
    required this.onTogglePass,
    required this.onToggleConfirm,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthInputField(
            controller: emailCtrl,
            label: isHR ? 'Email công việc *' : 'Địa chỉ email *',
            hint: isHR ? 'ban@congty.com' : 'ban@example.com',
            icon: PhosphorIconsBold.envelopeSimple,
            keyboardType: TextInputType.emailAddress,
            error: emailError,
          ),
          const SizedBox(height: 14),
          AuthInputField(
            controller: passCtrl,
            label: 'Mật khẩu *',
            hint: 'Tối thiểu 8 ký tự',
            icon: PhosphorIconsBold.lock,
            obscureText: obscurePass,
            error: passError,
            trailing: GestureDetector(
              onTap: onTogglePass,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  obscurePass
                      ? PhosphorIconsBold.eye
                      : PhosphorIconsBold.eyeSlash,
                  key: ValueKey(obscurePass),
                  size: 18,
                  color: AppColors.gray400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _PasswordStrengthBar(password: password),
          const SizedBox(height: 14),
          AuthInputField(
            controller: confirmCtrl,
            label: 'Xác nhận mật khẩu *',
            hint: 'Nhập lại mật khẩu',
            icon: PhosphorIconsBold.lockKey,
            obscureText: obscureConfirm,
            error: confirmError,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(
                        parent: anim, curve: Curves.elasticOut),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: (confirmText.isNotEmpty &&
                          password.isNotEmpty &&
                          confirmText == password)
                      ? const Icon(
                          PhosphorIconsBold.checkCircle,
                          key: ValueKey('match'),
                          size: 18,
                          color: Color(0xFF22C55E),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-match')),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onToggleConfirm,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      obscureConfirm
                          ? PhosphorIconsBold.eye
                          : PhosphorIconsBold.eyeSlash,
                      key: ValueKey(obscureConfirm),
                      size: 18,
                      color: AppColors.gray400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

// ─── Password strength bar ────────────────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int get _strength {
    if (password.length < 4) return 0;
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final s      = _strength;
    final labels = ['Yếu', 'Trung bình', 'Khá', 'Mạnh'];
    final colors = [
      AppColors.error,
      AppColors.amber,
      const Color(0xFFEAB308),
      AppColors.success,
    ];
    final label = s > 0 ? labels[s - 1] : 'Yếu';
    final color = s > 0 ? colors[s - 1] : AppColors.error;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < s ? color : AppColors.gray200,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 3),
      Text(label,
          style: AppTextStyles.caption.copyWith(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ─── Step 2: HR profile ───────────────────────────────────────────────────────

class _HRStep2Form extends StatelessWidget {
  final TextEditingController fullNameCtrl, companyCtrl, jobTitleCtrl;
  final bool agreedTerms, isDark;
  final String? fullNameError, companyError;
  final VoidCallback onToggleTerms;
  final void Function(CompanyModel)? onCompanyPicked;

  const _HRStep2Form({
    super.key,
    required this.fullNameCtrl,
    required this.companyCtrl,
    required this.jobTitleCtrl,
    required this.agreedTerms,
    required this.isDark,
    this.fullNameError,
    this.companyError,
    required this.onToggleTerms,
    this.onCompanyPicked,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthInputField(
            controller: fullNameCtrl,
            label: 'Họ tên *',
            hint: 'Nguyễn Văn A',
            icon: PhosphorIconsBold.user,
            error: fullNameError,
          ),
          const SizedBox(height: 14),
          _CompanySearchField(
            controller: companyCtrl,
            isDark: isDark,
            error: companyError,
            onPicked: onCompanyPicked,
          ),
          const SizedBox(height: 14),
          AuthInputField(
            controller: jobTitleCtrl,
            label: 'Chức danh',
            hint: 'HR Manager',
            icon: PhosphorIconsBold.briefcase,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onToggleTerms,
            behavior: HitTestBehavior.opaque,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: agreedTerms
                      ? AppColors.brandPurple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: agreedTerms
                        ? AppColors.brandPurple
                        : AppColors.gray400,
                    width: 1.5,
                  ),
                ),
                child: agreedTerms
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(children: [
                  Text('Tôi đồng ý với ',
                      style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.65)
                              : AppColors.gray500)),
                  Text('Điều khoản dịch vụ',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.brandPurple,
                          fontWeight: FontWeight.w600)),
                  Text(' và ',
                      style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.65)
                              : AppColors.gray500)),
                  Text('Chính sách bảo mật',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.brandPurple,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
        ],
      );
}

// ─── Company search field ─────────────────────────────────────────────────────

class _CompanySearchField extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark;
  final String? error;
  final void Function(CompanyModel)? onPicked;

  const _CompanySearchField({
    required this.controller,
    required this.isDark,
    this.error,
    this.onPicked,
  });

  @override
  State<_CompanySearchField> createState() => _CompanySearchFieldState();
}

class _CompanySearchFieldState extends State<_CompanySearchField> {
  List<CompanyModel> _results = [];
  bool _open = false;
  bool _searching = false;
  bool _suppress = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    if (_suppress) return;
    _debounce?.cancel();
    final q = widget.controller.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _open = false;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 420), () => _fetch(q));
  }

  Future<void> _fetch(String q) async {
    final res = await CompanyService.search(q);
    if (!mounted) return;
    setState(() {
      _results = res;
      _open = res.isNotEmpty;
      _searching = false;
    });
  }

  void _pick(CompanyModel c) {
    _suppress = true;
    widget.controller.value = TextEditingValue(
      text: c.name,
      selection: TextSelection.fromPosition(TextPosition(offset: c.name.length)),
    );
    _suppress = false;
    setState(() {
      _open = false;
      _results = [];
    });
    widget.onPicked?.call(c);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthInputField(
          controller: widget.controller,
          label: 'Tên công ty *',
          hint: 'Nhập tên để tìm kiếm...',
          icon: PhosphorIconsBold.buildings,
          error: widget.error,
          trailing: _searching
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brandPurple,
                  ),
                )
              : null,
        ),
        if (_open) ...[
          const SizedBox(height: 4),
          _CompanyDropdown(
            results: _results,
            isDark: isDark,
            onPick: _pick,
          ),
        ],
      ],
    );
  }
}

class _CompanyDropdown extends StatelessWidget {
  final List<CompanyModel> results;
  final bool isDark;
  final void Function(CompanyModel) onPick;

  const _CompanyDropdown({
    required this.results,
    required this.isDark,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2235) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.gray200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: results.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 0.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.gray100,
            ),
            itemBuilder: (context, i) {
              final c = results[i];
              return InkWell(
                onTap: () => onPick(c),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(children: [
                    Icon(PhosphorIconsBold.buildings,
                        size: 14,
                        color: AppColors.brandPurple.withValues(alpha: 0.75)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.name,
                        style: AppTextStyles.body.copyWith(
                          color: isDark ? Colors.white : AppColors.nearBlack,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(PhosphorIconsRegular.caretRight,
                        size: 12, color: AppColors.gray400),
                  ]),
                ),
              );
            },
          ),
        ),
      );
}

// ─── Step 2: Candidate profile ────────────────────────────────────────────────

const _seniorityLevels = ['Intern', 'Fresher', 'Junior', 'Middle', 'Senior', 'Lead'];

// Tech options grouped by category for the bottom sheet
const _techCategories = <String, List<String>>{
  'Frontend':       ['JavaScript', 'TypeScript', 'React', 'Next.js', 'Vue', 'Angular'],
  'Backend':        ['Node.js', 'Python', 'Java', 'PHP', 'Go', 'C#'],
  'Mobile':         ['Flutter', 'Dart', 'Kotlin', 'Swift'],
  'DevOps / Cloud': ['Docker', 'Kubernetes', 'AWS', 'Azure'],
  'Database':       ['MySQL', 'PostgreSQL', 'MongoDB', 'Redis', 'GraphQL'],
};

// Flat list used for diff computation
const _allTechOptions = [
  'JavaScript', 'TypeScript', 'React', 'Next.js', 'Vue', 'Angular',
  'Node.js', 'Python', 'Java', 'PHP', 'Go', 'C#',
  'Flutter', 'Dart', 'Kotlin', 'Swift',
  'Docker', 'Kubernetes', 'AWS', 'Azure',
  'MySQL', 'PostgreSQL', 'MongoDB', 'Redis', 'GraphQL',
];

class _CandidateStep2Form extends StatelessWidget {
  final TextEditingController fullNameCtrl, targetRoleCtrl;
  final String seniority;
  final Set<String> techStack;
  final bool isDark;
  final String? fullNameError;
  final String? targetRoleError;
  final ValueChanged<String> onSeniorityChanged;
  final ValueChanged<String> onTechToggled;

  const _CandidateStep2Form({
    super.key,
    required this.fullNameCtrl,
    required this.targetRoleCtrl,
    required this.seniority,
    required this.techStack,
    required this.isDark,
    this.fullNameError,
    this.targetRoleError,
    required this.onSeniorityChanged,
    required this.onTechToggled,
  });

  static const _bg = {false: Color(0xFFF9FAFB), true: Color(0xFF1A2235)};
  static const _bd = {false: Color(0xFFE5E7EB), true: Color(0xFF374151)};

  void _openTechSheet(BuildContext context) {
    final tempSelected = Set<String>.from(techStack);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => _TechStackSheet(
          isDark: isDark,
          tempSelected: tempSelected,
          onToggle: (t) => setSheetState(() {
            if (tempSelected.contains(t)) {
              tempSelected.remove(t);
            } else {
              tempSelected.add(t);
            }
          }),
          onApply: () {
            // Apply diff back to parent
            for (final t in _allTechOptions) {
              final was = techStack.contains(t);
              final now = tempSelected.contains(t);
              if (was != now) onTechToggled(t);
            }
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bg[isDark]!;
    final bd = _bd[isDark]!;
    final textColor = isDark ? Colors.white : AppColors.nearBlack;
    final labelStyle = AppTextStyles.label.copyWith(
      color: isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.nearBlack,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthInputField(
          controller: fullNameCtrl,
          label: 'Họ tên *',
          hint: 'Nguyễn Văn B',
          icon: PhosphorIconsBold.user,
          error: fullNameError,
        ),
        const SizedBox(height: 14),
        AuthInputField(
          controller: targetRoleCtrl,
          label: 'Vị trí mục tiêu *',
          hint: 'Flutter Developer',
          icon: PhosphorIconsBold.briefcase,
          error: targetRoleError,
        ),
        const SizedBox(height: 14),

        // ── Seniority dropdown ────────────────────────────────────────────────
        Text('Cấp độ kinh nghiệm', style: labelStyle),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            const Icon(PhosphorIconsBold.medal, size: 17, color: AppColors.gray400),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: seniority,
                  isExpanded: true,
                  iconSize: 0,
                  style: AppTextStyles.body.copyWith(
                    color: textColor,
                    fontSize: 14,
                  ),
                  dropdownColor: isDark ? const Color(0xFF1A2235) : Colors.white,
                  items: _seniorityLevels
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) { if (v != null) onSeniorityChanged(v); },
                ),
              ),
            ),
            const Icon(PhosphorIconsBold.caretDown, size: 13, color: AppColors.gray400),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Tech Stack multi-select ───────────────────────────────────────────
        Text('Tech Stack', style: labelStyle),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _openTechSheet(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: techStack.isNotEmpty
                    ? AppColors.brandPurple.withValues(alpha: 0.6)
                    : bd,
                width: techStack.isNotEmpty ? 1.5 : 1.0,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              14,
              techStack.isEmpty ? 0 : 10,
              14,
              techStack.isEmpty ? 0 : 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsBold.code,
                  size: 17,
                  color: techStack.isNotEmpty
                      ? AppColors.brandPurple
                      : AppColors.gray400,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: techStack.isEmpty
                      ? SizedBox(
                          height: 32,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Chọn kỹ năng...',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.gray400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: techStack
                              .map((t) => _SelectedTechChip(
                                    label: t,
                                    onRemove: () => onTechToggled(t),
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(width: 4),
                Icon(
                  PhosphorIconsBold.caretDown,
                  size: 13,
                  color: techStack.isNotEmpty
                      ? AppColors.brandPurple
                      : AppColors.gray400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Removable chip shown inside the tech stack trigger field ──────────────────

class _SelectedTechChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _SelectedTechChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 8, right: 4, top: 3, bottom: 3),
        decoration: BoxDecoration(
          color: AppColors.brandPurple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.brandPurple,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              )),
          const SizedBox(width: 3),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(PhosphorIconsBold.x, size: 11,
                color: AppColors.brandPurple),
          ),
        ]),
      );
}

// ── Tech Stack bottom sheet ───────────────────────────────────────────────────

class _TechStackSheet extends StatelessWidget {
  final bool isDark;
  final Set<String> tempSelected;
  final ValueChanged<String> onToggle;
  final VoidCallback onApply;

  const _TechStackSheet({
    required this.isDark,
    required this.tempSelected,
    required this.onToggle,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F1729) : Colors.white;
    final divider = isDark ? AppColors.darkCardBorder : AppColors.gray200;
    final textColor = isDark ? Colors.white : AppColors.nearBlack;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Row(children: [
              Text('Chọn Tech Stack',
                  style: AppTextStyles.label.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
              const Spacer(),
              if (tempSelected.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${tempSelected.length} đã chọn',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      )),
                ),
            ]),
          ),
          Divider(height: 1, color: divider),

          // Scrollable tech list by category
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              children: _techCategories.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(children: [
                      Container(
                        width: 3,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppColors.brandPurple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(entry.key,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          )),
                    ]),
                  ),
                  ...entry.value.map((tech) {
                    final selected = tempSelected.contains(tech);
                    return InkWell(
                      onTap: () => onToggle(tech),
                      splashColor: AppColors.brandPurple.withValues(alpha: 0.06),
                      highlightColor: AppColors.brandPurple.withValues(alpha: 0.04),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 11),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.brandPurple
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: selected
                                    ? AppColors.brandPurple
                                    : (isDark
                                        ? const Color(0xFF374151)
                                        : const Color(0xFFD1D5DB)),
                                width: 1.5,
                              ),
                            ),
                            child: selected
                                ? const Icon(PhosphorIconsBold.check,
                                    size: 12, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Text(tech,
                              style: AppTextStyles.body.copyWith(
                                color: selected
                                    ? textColor
                                    : AppColors.gray500,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 14,
                              )),
                        ]),
                      ),
                    );
                  }),
                ],
              )).toList(),
            ),
          ),

          // Apply button
          Divider(height: 1, color: divider),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16, 12, 16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: ShimmerButton(
              label: tempSelected.isEmpty
                  ? 'Áp dụng'
                  : 'Áp dụng (${tempSelected.length})',
              onTap: onApply,
            ),
          ),
        ],
      ),
    );
  }
}

