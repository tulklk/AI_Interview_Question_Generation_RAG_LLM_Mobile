import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/auth_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/app_providers.dart';
import '../../../models/user_model.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/shimmer_button.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // Role: 0=HR Manager, 1=Job Seeker
  int _roleIndex = 0;
  int _step = 1;
  bool _isLoading = false;

  // Step-1 controllers (shared)
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passCtrl       = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  bool _obscurePass     = true;
  bool _obscureConfirm  = true;

  // HR step-2 controllers
  final _companyCtrl    = TextEditingController();
  final _jobTitleCtrl   = TextEditingController();
  bool _agreedTerms     = false;

  // Job Seeker step-2 state
  String _seniority     = 'Junior';
  final _targetRoleCtrl = TextEditingController();
  final Set<String> _techStack = {};

  late AnimationController _stepAnim;

  @override
  void initState() {
    super.initState();
    _stepAnim = AnimationController(
      vsync: this, duration: AuthAnimations.stepSlide);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    _companyCtrl.dispose(); _jobTitleCtrl.dispose(); _targetRoleCtrl.dispose();
    _stepAnim.dispose();
    super.dispose();
  }

  void _onRoleChanged(int index) {
    if (_roleIndex == index) return;
    setState(() { _roleIndex = index; _step = 1; });
    ref.read(selectedRoleProvider.notifier).state =
        index == 0 ? UserRole.hrManager : UserRole.candidate;
  }

  Future<void> _next() async {
    if (_step == 1) {
      await _stepAnim.forward();
      _stepAnim.reset();
      setState(() => _step = 2);
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (_roleIndex == 0) {
      await ref.read(authProvider.notifier).loginAsHR();
    } else {
      await ref.read(authProvider.notifier).loginAsCandidate();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _back() => setState(() => _step = 1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthBackground(
      isDark: isDark,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Column(children: [
            _AuthLogo(isDark: isDark)
                .animate().fadeIn(duration: 400.ms, delay: 100.ms),
            const SizedBox(height: 24),

            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button (step 2 only)
                  if (_step == 2) ...[
                    GestureDetector(
                      onTap: _back,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(PhosphorIconsBold.arrowLeft, size: 14,
                          color: AppColors.brandPurple),
                        const SizedBox(width: 4),
                        Text('Back', style: AppTextStyles.caption.copyWith(
                          color: AppColors.brandPurple, fontWeight: FontWeight.w600)),
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
                    labels: const ['Account Information', 'Your Profile'],
                  ).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 20),

                  // Title
                  AnimatedHeading(
                    text: 'Create your account',
                    style: AppTextStyles.h1.copyWith(
                      color: isDark ? Colors.white : AppColors.nearBlack,
                      fontSize: 24, fontWeight: FontWeight.w800),
                    initialDelay: 380.ms,
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: AuthAnimations.tabSwitch,
                    child: Text(
                      _step == 1
                          ? (_roleIndex == 0
                              ? 'Join thousands of recruiters using HireGen AI'
                              : 'Start your interview practice journey')
                          : (_roleIndex == 0
                              ? 'Tell us about your company'
                              : 'Help us personalize your experience'),
                      key: ValueKey('$_roleIndex-$_step'),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.gray500, fontSize: 14)),
                  ).animate().fadeIn(delay: 550.ms),
                  const SizedBox(height: 24),

                  // Form body (animated step switch)
                  AnimatedSwitcher(
                    duration: AuthAnimations.stepSlide,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0), end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: anim, curve: AuthAnimations.easeOutCubic)),
                        child: child,
                      ),
                    ),
                    child: _step == 1
                        ? _Step1Form(
                            key: const ValueKey('step1'),
                            firstNameCtrl: _firstNameCtrl,
                            lastNameCtrl: _lastNameCtrl,
                            emailCtrl: _emailCtrl,
                            passCtrl: _passCtrl,
                            confirmCtrl: _confirmCtrl,
                            obscurePass: _obscurePass,
                            obscureConfirm: _obscureConfirm,
                            isHR: _roleIndex == 0,
                            onTogglePass: () =>
                                setState(() => _obscurePass = !_obscurePass),
                            onToggleConfirm: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                          )
                        : _roleIndex == 0
                            ? _HRStep2Form(
                                key: const ValueKey('step2hr'),
                                companyCtrl: _companyCtrl,
                                jobTitleCtrl: _jobTitleCtrl,
                                agreedTerms: _agreedTerms,
                                isDark: isDark,
                                onToggleTerms: () =>
                                    setState(() => _agreedTerms = !_agreedTerms),
                              )
                            : _JobSeekerStep2Form(
                                key: const ValueKey('step2js'),
                                targetRoleCtrl: _targetRoleCtrl,
                                seniority: _seniority,
                                techStack: _techStack,
                                isDark: isDark,
                                onSeniorityChanged: (v) =>
                                    setState(() => _seniority = v),
                                onTechToggled: (t) => setState(
                                    () => _techStack.contains(t)
                                        ? _techStack.remove(t)
                                        : _techStack.add(t)),
                              ),
                  ),
                  const SizedBox(height: 20),

                  // Button
                  ShimmerButton(
                    label: _step == 1 ? 'Continue' : 'Create Account',
                    isLoading: _isLoading,
                    onTap: _next,
                    trailingIcon: PhosphorIconsBold.arrowRight,
                  ),
                  const SizedBox(height: 18),

                  // Divider + social
                  _OrDivider(isDark: isDark, text: 'or sign up with'),
                  const SizedBox(height: 14),
                  _SocialRow(isDark: isDark, onTap: _next),
                  const SizedBox(height: 18),

                  // Sign in link
                  Center(
                    child: Wrap(alignment: WrapAlignment.center, children: [
                      Text('Already have an account? ',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray500, fontSize: 13)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text('Sign in',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.brandPurple,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ]),
                  ),
                ],
              ),
            ).animate(delay: 200.ms)
              .fadeIn(duration: 700.ms, curve: AuthAnimations.easeOutCubic)
              .slideY(begin: 0.08, end: 0, duration: 700.ms,
                curve: AuthAnimations.easeOutCubic)
              .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1),
                duration: 700.ms, curve: AuthAnimations.easeOutCubic),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

// ─── Logo (same as login) ─────────────────────────────────────────────────────

class _AuthLogo extends StatelessWidget {
  final bool isDark;
  const _AuthLogo({required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(
            color: AppColors.brandPurple.withValues(alpha: 0.40),
            blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: const Icon(PhosphorIconsBold.sparkle, size: 26, color: Colors.white),
      ),
      const SizedBox(height: 10),
      Text('HireGen AI',
        style: AppTextStyles.h3.copyWith(
          color: isDark ? Colors.white : AppColors.nearBlack,
          fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text('AI-Powered Interview Question Generator',
        style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12)),
    ],
  );
}

// ─── Role segmented tabs ──────────────────────────────────────────────────────

class _RoleSegmentedTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;
  const _RoleSegmentedTabs({required this.selectedIndex,
    required this.onChanged, required this.isDark});

  static const _labels = ['HR Manager', 'Job Seeker'];
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final pillW = (constraints.maxWidth - _gap * 3) / 2;
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2235) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(children: [
          // ── sliding pill ──────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: const Cubic(0.34, 1.56, 0.64, 1), // spring overshoot
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
          // ── labels ───────────────────────────────────────────
          Row(
            children: List.generate(_labels.length, (i) => Expanded(
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
            )),
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
  const _WizardStepIndicator({required this.currentStep,
    required this.isDark, required this.labels});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _StepBubble(number: 1, label: labels[0],
        state: currentStep > 1 ? _StepState.done
            : currentStep == 1 ? _StepState.active : _StepState.idle,
        isDark: isDark),
      Expanded(child: AnimatedContainer(
        duration: AuthAnimations.stepSlide,
        height: 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          gradient: currentStep >= 2
              ? AppColors.primaryGradient
              : LinearGradient(colors: [
                  isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                ]),
        ),
      )),
      _StepBubble(number: 2, label: labels[1],
        state: currentStep > 2 ? _StepState.done
            : currentStep == 2 ? _StepState.active : _StepState.idle,
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
  const _StepBubble({required this.number, required this.label,
    required this.state, required this.isDark});

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
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
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
    final color    = isDone ? AppColors.success
        : isActive ? AppColors.brandPurple
        : (widget.isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB));

    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 48, height: 48,
        child: Stack(alignment: Alignment.center, children: [
          // Pulse ring 1
          if (isActive)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final t = _pulse.value;
                final size = 28.0 + t * 18;
                return Container(
                  width: size, height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.brandPurple.withValues(
                          alpha: (1 - t) * 0.45),
                      width: 1.5,
                    ),
                  ),
                );
              },
            ),
          // Pulse ring 2 (offset phase)
          if (isActive)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final t = (((_pulse.value + 0.5) % 1.0));
                final size = 28.0 + t * 18;
                return Container(
                  width: size, height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.brandPurple.withValues(
                          alpha: (1 - t) * 0.25),
                      width: 1.0,
                    ),
                  ),
                );
              },
            ),
          // Bubble
          AnimatedContainer(
            duration: AuthAnimations.stepSlide,
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isActive || isDone) ? color : Colors.transparent,
              border: Border.all(color: color, width: 1.5),
              boxShadow: isActive
                  ? [BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.40),
                      blurRadius: 12, spreadRadius: 0)]
                  : isDone
                  ? [BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.35),
                      blurRadius: 8)]
                  : null,
            ),
            child: Center(child: isDone
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text('${widget.number}', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: (isActive || isDone) ? Colors.white
                        : (widget.isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppColors.gray400)))),
          ),
        ]),
      ),
      Text(widget.label, style: AppTextStyles.caption.copyWith(
        fontSize: 10,
        color: isActive ? AppColors.brandPurple
            : isDone ? AppColors.success
            : (widget.isDark
                ? Colors.white.withValues(alpha: 0.4)
                : AppColors.gray400),
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }
}

// ─── Step 1 form ─────────────────────────────────────────────────────────────

class _Step1Form extends StatelessWidget {
  final TextEditingController firstNameCtrl, lastNameCtrl,
      emailCtrl, passCtrl, confirmCtrl;
  final bool obscurePass, obscureConfirm, isHR;
  final VoidCallback onTogglePass, onToggleConfirm;

  const _Step1Form({
    super.key,
    required this.firstNameCtrl, required this.lastNameCtrl,
    required this.emailCtrl, required this.passCtrl, required this.confirmCtrl,
    required this.obscurePass, required this.obscureConfirm,
    required this.isHR, required this.onTogglePass, required this.onToggleConfirm,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(children: [
        Expanded(child: AuthInputField(
          controller: firstNameCtrl, label: 'First Name',
          hint: 'Nguyen', icon: PhosphorIconsBold.user)),
        const SizedBox(width: 10),
        Expanded(child: AuthInputField(
          controller: lastNameCtrl, label: 'Last Name',
          hint: 'Van A', icon: PhosphorIconsBold.user)),
      ]),
      const SizedBox(height: 14),
      AuthInputField(
        controller: emailCtrl,
        label: isHR ? 'Work Email' : 'Email Address',
        hint: isHR ? 'you@company.com' : 'you@example.com',
        icon: PhosphorIconsBold.envelopeSimple,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 14),
      AuthInputField(
        controller: passCtrl, label: 'Password',
        hint: 'Min. 8 characters', icon: PhosphorIconsBold.lock,
        obscureText: obscurePass,
        trailing: GestureDetector(
          onTap: onTogglePass,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(obscurePass ? PhosphorIconsBold.eye : PhosphorIconsBold.eyeSlash,
              key: ValueKey(obscurePass), size: 18, color: AppColors.gray400)),
        ),
      ),
      const SizedBox(height: 8),
      _PasswordStrengthBar(password: passCtrl.text),
      const SizedBox(height: 14),
      AuthInputField(
        controller: confirmCtrl, label: 'Confirm Password',
        hint: 'Repeat your password', icon: PhosphorIconsBold.lockKey,
        obscureText: obscureConfirm,
        trailing: GestureDetector(
          onTap: onToggleConfirm,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(obscureConfirm ? PhosphorIconsBold.eye : PhosphorIconsBold.eyeSlash,
              key: ValueKey(obscureConfirm), size: 18, color: AppColors.gray400)),
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
    final s = _strength;
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    final colors = [
      AppColors.error, AppColors.amber, const Color(0xFFEAB308), AppColors.success,
    ];
    final label = s > 0 ? labels[s - 1] : 'Weak';
    final color = s > 0 ? colors[s - 1] : AppColors.error;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(4, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: i < s ? color : AppColors.gray200),
        ),
      ))),
      const SizedBox(height: 3),
      Text(label, style: AppTextStyles.caption.copyWith(
        color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ─── HR step 2 ───────────────────────────────────────────────────────────────

class _HRStep2Form extends StatelessWidget {
  final TextEditingController companyCtrl, jobTitleCtrl;
  final bool agreedTerms;
  final bool isDark;
  final VoidCallback onToggleTerms;

  const _HRStep2Form({
    super.key,
    required this.companyCtrl, required this.jobTitleCtrl,
    required this.agreedTerms, required this.isDark,
    required this.onToggleTerms,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      AuthInputField(controller: companyCtrl, label: 'Company Name',
        hint: 'e.g. FPT Software', icon: PhosphorIconsBold.buildings),
      const SizedBox(height: 14),
      AuthInputField(controller: jobTitleCtrl, label: 'Your Job Title',
        hint: 'e.g. HR Manager', icon: PhosphorIconsBold.briefcase),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: onToggleTerms,
        behavior: HitTestBehavior.opaque,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 18, height: 18, margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: agreedTerms ? AppColors.brandPurple : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: agreedTerms ? AppColors.brandPurple : AppColors.gray400,
                width: 1.5),
            ),
            child: agreedTerms
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(child: Wrap(children: [
            Text('I agree to the ', style: AppTextStyles.caption.copyWith(
              color: isDark ? Colors.white.withValues(alpha: 0.65) : AppColors.gray500)),
            Text('Terms of Service', style: AppTextStyles.caption.copyWith(
              color: AppColors.brandPurple, fontWeight: FontWeight.w600)),
            Text(' and ', style: AppTextStyles.caption.copyWith(
              color: isDark ? Colors.white.withValues(alpha: 0.65) : AppColors.gray500)),
            Text('Privacy Policy', style: AppTextStyles.caption.copyWith(
              color: AppColors.brandPurple, fontWeight: FontWeight.w600)),
          ])),
        ]),
      ),
    ],
  );
}

// ─── Job Seeker step 2 ────────────────────────────────────────────────────────

const _seniorityLevels = ['Intern', 'Junior', 'Mid', 'Senior', 'Lead'];
const _techOptions = [
  'JavaScript','TypeScript','React','Next.js','Vue','Angular',
  'Node.js','Python','Java','Go','C#','PHP','Ruby','Swift',
  'Kotlin','Docker','Kubernetes','AWS','Azure','MySQL',
  'PostgreSQL','MongoDB','Redis','GraphQL',
];

class _JobSeekerStep2Form extends StatelessWidget {
  final TextEditingController targetRoleCtrl;
  final String seniority;
  final Set<String> techStack;
  final bool isDark;
  final ValueChanged<String> onSeniorityChanged;
  final ValueChanged<String> onTechToggled;

  const _JobSeekerStep2Form({
    super.key,
    required this.targetRoleCtrl, required this.seniority,
    required this.techStack, required this.isDark,
    required this.onSeniorityChanged, required this.onTechToggled,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      AuthInputField(controller: targetRoleCtrl, label: 'Target Role',
        hint: 'e.g. Flutter Developer', icon: PhosphorIconsBold.briefcase),
      const SizedBox(height: 14),

      // Seniority
      Text('Seniority', style: AppTextStyles.label.copyWith(
        color: isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.nearBlack,
        fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6,
        children: _seniorityLevels.map((s) {
          final selected = s == seniority;
          return GestureDetector(
            onTap: () => onSeniorityChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.brandPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? AppColors.brandPurple
                      : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
              ),
              child: Text(s, style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : AppColors.gray500,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 12)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 14),

      // Tech stack
      Text('Tech Stack', style: AppTextStyles.label.copyWith(
        color: isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.nearBlack,
        fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6,
        children: _techOptions.map((t) {
          final selected = techStack.contains(t);
          return GestureDetector(
            onTap: () => onTechToggled(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.brandPurple.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: selected ? AppColors.brandPurple
                      : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                  width: selected ? 1.5 : 1.0),
              ),
              child: Text(t, style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.brandPurple
                    : (isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.gray500),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11)),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  final bool isDark;
  final String text;
  const _OrDivider({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(
      color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(text, style: AppTextStyles.caption.copyWith(
        color: AppColors.gray400, fontSize: 12))),
    Expanded(child: Divider(
      color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
  ]);
}

class _SocialRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _SocialRow({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _SocialBtn(label: 'Google',
      icon: _GoogleIcon(), isDark: isDark, onTap: onTap)),
    const SizedBox(width: 10),
    Expanded(child: _SocialBtn(label: 'Github',
      icon: Icon(PhosphorIconsBold.githubLogo, size: 18,
        color: isDark ? Colors.white : AppColors.nearBlack),
      isDark: isDark, onTap: onTap)),
  ]);
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isDark;
  final VoidCallback onTap;
  const _SocialBtn({required this.label, required this.icon,
    required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2235) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        icon, const SizedBox(width: 8),
        Text(label, style: AppTextStyles.label.copyWith(
          color: isDark ? Colors.white : AppColors.nearBlack,
          fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 18, height: 18,
    decoration: const BoxDecoration(
      shape: BoxShape.circle, color: Color(0xFFF1F3F4)),
    child: const Center(child: Text('G', style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w800,
      color: Color(0xFFEA4335), height: 1.0))),
  );
}
