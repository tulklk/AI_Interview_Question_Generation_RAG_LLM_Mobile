import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/shimmer_button.dart';

const _seniorityLevels = ['Intern', 'Fresher', 'Junior', 'Middle', 'Senior', 'Lead'];
const _techOptions = [
  'JavaScript', 'TypeScript', 'React', 'Next.js', 'Vue', 'Angular',
  'Node.js', 'Python', 'Java', 'Kotlin', 'Swift', 'Go', 'C#', 'PHP',
  'Flutter', 'Dart', 'Docker', 'Kubernetes', 'AWS', 'Azure',
  'MySQL', 'PostgreSQL', 'MongoDB', 'Redis', 'GraphQL',
];

/// Shows a modal bottom sheet where a new Google user fills in their profile.
/// Returns [GoogleProfileData] on submit, or null if dismissed.
Future<GoogleProfileData?> showGoogleProfileSheet(
  BuildContext context, {
  required String email,
  required String name,
}) {
  return showModalBottomSheet<GoogleProfileData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _GoogleProfileSheet(email: email, name: name),
  );
}

class _GoogleProfileSheet extends StatefulWidget {
  final String email;
  final String name;
  const _GoogleProfileSheet({required this.email, required this.name});

  @override
  State<_GoogleProfileSheet> createState() => _GoogleProfileSheetState();
}

class _GoogleProfileSheetState extends State<_GoogleProfileSheet> {
  int _roleIndex = 0; // 0 = HR Manager, 1 = Ứng viên

  // HR fields
  final _companyCtrl  = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  String? _companyError;

  // Candidate fields
  final _targetRoleCtrl = TextEditingController();
  String _seniority = 'Junior';
  final Set<String> _techStack = {};

  @override
  void dispose() {
    _companyCtrl.dispose();
    _jobTitleCtrl.dispose();
    _targetRoleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_roleIndex == 0 && _companyCtrl.text.trim().isEmpty) {
      setState(() => _companyError = 'Vui lòng nhập tên công ty');
      return;
    }
    setState(() => _companyError = null);

    Navigator.of(context).pop(GoogleProfileData(
      intendedRole: _roleIndex == 0 ? 'hrManager' : 'candidate',
      companyName:  _roleIndex == 0 ? _companyCtrl.text.trim() : null,
      jobTitle:     _roleIndex == 0 && _jobTitleCtrl.text.isNotEmpty
                        ? _jobTitleCtrl.text.trim() : null,
      targetRole:   _roleIndex == 1 && _targetRoleCtrl.text.isNotEmpty
                        ? _targetRoleCtrl.text.trim() : null,
      seniorityLevel: _roleIndex == 1 ? _seniority : null,
      techStack:    _roleIndex == 1 ? _techStack.toList() : const [],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final bottomInset  = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.20)
                  : AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text('Hoàn thiện hồ sơ',
                      style: AppTextStyles.h1.copyWith(
                          color: isDark ? Colors.white : AppColors.nearBlack,
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Cho chúng tôi biết thêm để cá nhân hóa trải nghiệm',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.gray500, fontSize: 13)),
                  const SizedBox(height: 16),

                  // Google account card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.brandPurple.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.brandPurple.withValues(alpha: 0.20)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 38, height: 38,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.name.isNotEmpty
                                ? widget.name[0].toUpperCase()
                                : 'G',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.name,
                                style: AppTextStyles.label.copyWith(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.nearBlack,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            Text(widget.email,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.gray500, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(PhosphorIconsBold.check,
                          size: 16, color: AppColors.success),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Role selector
                  Text('Bạn là',
                      style: AppTextStyles.label.copyWith(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.nearBlack,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  _RoleToggle(
                    selectedIndex: _roleIndex,
                    isDark: isDark,
                    onChanged: (i) =>
                        setState(() { _roleIndex = i; _companyError = null; }),
                  ),
                  const SizedBox(height: 20),

                  // Conditional fields
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOut)),
                        child: child,
                      ),
                    ),
                    child: _roleIndex == 0
                        ? _HRFields(
                            key: const ValueKey('hr'),
                            companyCtrl:  _companyCtrl,
                            jobTitleCtrl: _jobTitleCtrl,
                            companyError: _companyError,
                          )
                        : _CandidateFields(
                            key: const ValueKey('cand'),
                            targetRoleCtrl:     _targetRoleCtrl,
                            seniority:          _seniority,
                            techStack:          _techStack,
                            isDark:             isDark,
                            onSeniorityChanged: (v) =>
                                setState(() => _seniority = v),
                            onTechToggled: (t) => setState(() => _techStack
                                .contains(t)
                                    ? _techStack.remove(t)
                                    : _techStack.add(t)),
                          ),
                  ),
                  const SizedBox(height: 28),

                  ShimmerButton(
                    label: 'Hoàn tất & Đăng nhập',
                    onTap: _submit,
                    trailingIcon: PhosphorIconsBold.arrowRight,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Role toggle ──────────────────────────────────────────────────────────────

class _RoleToggle extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _RoleToggle({
    required this.selectedIndex,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const gap = 4.0;
          final pillW = (constraints.maxWidth - gap * 3) / 2;
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
                left: gap + selectedIndex * (pillW + gap),
                top: gap,
                width: pillW,
                height: 44 - gap * 2,
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
              Row(children: [
                for (int i = 0; i < 2; i++)
                  Expanded(
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
                            child: Text(i == 0 ? 'HR Manager' : 'Ứng viên'),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ]),
          );
        },
      );
}

// ─── HR fields ────────────────────────────────────────────────────────────────

class _HRFields extends StatelessWidget {
  final TextEditingController companyCtrl, jobTitleCtrl;
  final String? companyError;

  const _HRFields({
    super.key,
    required this.companyCtrl,
    required this.jobTitleCtrl,
    this.companyError,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthInputField(
            controller: companyCtrl,
            label: 'Tên công ty *',
            hint: 'Nhập tên công ty của bạn',
            icon: PhosphorIconsBold.buildings,
            error: companyError,
          ),
          const SizedBox(height: 14),
          AuthInputField(
            controller: jobTitleCtrl,
            label: 'Chức danh',
            hint: 'HR Manager',
            icon: PhosphorIconsBold.briefcase,
          ),
        ],
      );
}

// ─── Candidate fields ─────────────────────────────────────────────────────────

class _CandidateFields extends StatelessWidget {
  final TextEditingController targetRoleCtrl;
  final String seniority;
  final Set<String> techStack;
  final bool isDark;
  final ValueChanged<String> onSeniorityChanged;
  final ValueChanged<String> onTechToggled;

  const _CandidateFields({
    super.key,
    required this.targetRoleCtrl,
    required this.seniority,
    required this.techStack,
    required this.isDark,
    required this.onSeniorityChanged,
    required this.onTechToggled,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthInputField(
            controller: targetRoleCtrl,
            label: 'Vị trí mục tiêu',
            hint: 'Flutter Developer',
            icon: PhosphorIconsBold.briefcase,
          ),
          const SizedBox(height: 14),
          Text('Cấp độ kinh nghiệm',
              style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.nearBlack,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _seniorityLevels.map((s) {
              final selected = s == seniority;
              return GestureDetector(
                onTap: () => onSeniorityChanged(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brandPurple
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? AppColors.brandPurple
                          : (isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Text(s,
                      style: AppTextStyles.caption.copyWith(
                          color: selected ? Colors.white : AppColors.gray500,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 12)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('Tech Stack (tùy chọn)',
              style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.nearBlack,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _techOptions.map((t) {
              final selected = techStack.contains(t);
              return GestureDetector(
                onTap: () => onTechToggled(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brandPurple.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: selected
                          ? AppColors.brandPurple
                          : (isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB)),
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(t,
                      style: AppTextStyles.caption.copyWith(
                          color: selected
                              ? AppColors.brandPurple
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.70)
                                  : AppColors.gray500),
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 11)),
                ),
              );
            }).toList(),
          ),
        ],
      );
}
