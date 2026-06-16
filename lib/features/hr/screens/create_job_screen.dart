import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_secondary_button.dart';
import '../../../core/widgets/app_skill_chip.dart';
import '../../../core/widgets/app_text_field.dart';

class CreateJobScreen extends ConsumerStatefulWidget {
  const CreateJobScreen({super.key});

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _titleCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _level = 'Middle';
  bool _isGenerating = false;
  final Set<String> _selectedSkills = {'Flutter', 'Dart', 'Riverpod'};

  static const _levels = ['Junior', 'Middle', 'Senior', 'Lead'];
  static const _suggestedSkills = [
    'Flutter', 'Dart', 'Riverpod', 'BLoC', 'Firebase',
    'REST API', 'GraphQL', 'CI/CD', 'Clean Architecture',
    'Node.js', 'TypeScript', 'React', 'Python', 'Docker',
  ];

  Future<void> _generateKit() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isGenerating = false);
      context.push('/hr/ai-generator');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.offWhite,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(PhosphorIconsBold.arrowLeft, size: 18,
              color: isDark ? AppColors.white : AppColors.nearBlack),
          ),
        ),
        title: Text('Create Job', style: AppTextStyles.h4.copyWith(
          color: isDark ? AppColors.white : AppColors.nearBlack)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form section
            _SectionCard(
              title: 'Job Details',
              icon: PhosphorIconsBold.briefcase,
              isDark: isDark,
              child: Column(
                children: [
                  AppTextField(
                    label: 'Job Title *',
                    hint: 'e.g. Senior Flutter Developer',
                    controller: _titleCtrl,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Department',
                          hint: 'Engineering',
                          controller: _deptCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Location',
                          hint: 'Ho Chi Minh City',
                          controller: _locationCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Experience Level', style: AppTextStyles.label.copyWith(
                        color: isDark ? AppColors.white.withOpacity(0.85) : AppColors.nearBlack)),
                      const SizedBox(height: 10),
                      Row(
                        children: _levels.map((l) {
                          final isSelected = l == _level;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _level = l),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? AppColors.primaryGradient : null,
                                  color: isSelected ? null : (isDark ? AppColors.darkCard : AppColors.white),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : AppColors.cardBorder),
                                ),
                                child: Text(l,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption.copyWith(
                                    color: isSelected ? Colors.white :
                                      (isDark ? AppColors.white.withOpacity(0.7) : AppColors.gray500),
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  )),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Job Description *',
                    hint: 'Describe the role, responsibilities, and ideal candidate...',
                    controller: _descCtrl,
                    maxLines: 5,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),
            // Skills section
            _SectionCard(
              title: 'Required Skills',
              icon: PhosphorIconsBold.code,
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedSkills.map((s) => AppSkillChip(
                      label: s,
                      selected: _selectedSkills.contains(s),
                      onTap: () => setState(() {
                        if (_selectedSkills.contains(s)) {
                          _selectedSkills.remove(s);
                        } else {
                          _selectedSkills.add(s);
                        }
                      }),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_selectedSkills.length} skills selected',
                    style: AppTextStyles.caption.copyWith(color: AppColors.brandPurple),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 24),
            // Generate button
            AppGradientButton(
              label: 'Generate AI Interview Kit',
              isLoading: _isGenerating,
              onTap: _generateKit,
              height: 54,
              icon: const Icon(PhosphorIconsBold.sparkle, size: 18, color: Colors.white),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            AppSecondaryButton(
              label: 'Save as Draft',
              onTap: () => context.pop(),
              height: 48,
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.brandPurple),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.h4.copyWith(
                color: isDark ? AppColors.white : AppColors.nearBlack)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
