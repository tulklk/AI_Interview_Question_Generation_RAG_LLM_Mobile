import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/jobseeker_mock.dart';
import '../../models/jobseeker_models.dart';
import '../../providers/jobseeker_providers.dart';

class JobseekerProfileScreen extends ConsumerStatefulWidget {
  const JobseekerProfileScreen({super.key});

  @override
  ConsumerState<JobseekerProfileScreen> createState() =>
      _JobseekerProfileScreenState();
}

class _JobseekerProfileScreenState
    extends ConsumerState<JobseekerProfileScreen> {
  bool _editing = false;

  // Form controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _targetRoleCtrl;
  late final TextEditingController _linkedinCtrl;
  late final TextEditingController _githubCtrl;
  late final TextEditingController _skillInputCtrl;
  String? _seniorityLevel;
  List<String> _skills = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _targetRoleCtrl = TextEditingController();
    _linkedinCtrl = TextEditingController();
    _githubCtrl = TextEditingController();
    _skillInputCtrl = TextEditingController();
    // Trigger profile + CV load on first open
    Future.microtask(() {
      ref.read(candidateProfileProvider.notifier).load();
      ref.read(cvProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _targetRoleCtrl.dispose();
    _linkedinCtrl.dispose();
    _githubCtrl.dispose();
    _skillInputCtrl.dispose();
    super.dispose();
  }

  void _startEdit(CandidateProfileData data) {
    _nameCtrl.text = data.fullName;
    _bioCtrl.text = data.bio ?? '';
    _targetRoleCtrl.text = data.targetRole ?? '';
    _linkedinCtrl.text = data.linkedInUrl ?? '';
    _githubCtrl.text = data.githubUrl ?? '';
    _seniorityLevel = data.seniorityLevel;
    _skills = List.from(data.techStack);
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    final current = ref.read(candidateProfileProvider).profile ??
        const CandidateProfileData(fullName: '', email: '');
    final updated = current.copyWith(
      fullName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : current.fullName,
      bio: _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : current.bio,
      targetRole: _targetRoleCtrl.text.trim().isNotEmpty ? _targetRoleCtrl.text.trim() : current.targetRole,
      linkedInUrl: _linkedinCtrl.text.trim().isNotEmpty ? _linkedinCtrl.text.trim() : current.linkedInUrl,
      githubUrl: _githubCtrl.text.trim().isNotEmpty ? _githubCtrl.text.trim() : current.githubUrl,
      seniorityLevel: _seniorityLevel ?? current.seniorityLevel,
      techStack: _skills.isNotEmpty ? _skills : current.techStack,
    );
    await ref.read(candidateProfileProvider.notifier).save(updated);
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final profileState = ref.watch(candidateProfileProvider);
    final isWide = MediaQuery.of(context).size.width > 840;
    final bg = isDark ? const Color(0xFF070A13) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileState.error != null && profileState.profile == null
              ? _ErrorView(
                  error: profileState.error!,
                  isDark: isDark,
                  onRetry: () =>
                      ref.read(candidateProfileProvider.notifier).load(),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.myProfile,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (!_editing)
                            TextButton.icon(
                              onPressed: () => _startEdit(
                                  profileState.profile ?? const CandidateProfileData(fullName: '', email: '')),
                              icon: const Icon(Icons.edit_rounded, size: 15),
                              label: Text(l10n.editProfile),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.brandPurple),
                            )
                          else
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _editing = false),
                                  style: TextButton.styleFrom(
                                      foregroundColor:
                                          const Color(0xFF6B7280)),
                                  child: Text(l10n.cancelEdit),
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton(
                                  onPressed: _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    elevation: 0,
                                  ),
                                  child: Text(l10n.saveChanges_),
                                ),
                              ],
                            ),
                        ],
                      ).animate().fadeIn(),
                      const SizedBox(height: 16),

                      // Body
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 240,
                              child: _LeftPanel(
                                data: profileState.profile ??
                                    const CandidateProfileData(fullName: '', email: ''),
                                isDark: isDark,
                                l10n: l10n,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  _ProfileForm(
                                    editing: _editing,
                                    data: profileState.profile ??
                                        const CandidateProfileData(fullName: '', email: ''),
                                    isDark: isDark,
                                    l10n: l10n,
                                    nameCtrl: _nameCtrl,
                                    bioCtrl: _bioCtrl,
                                    targetRoleCtrl: _targetRoleCtrl,
                                    linkedinCtrl: _linkedinCtrl,
                                    githubCtrl: _githubCtrl,
                                    skillInputCtrl: _skillInputCtrl,
                                    seniorityLevel: _seniorityLevel,
                                    skills: _skills,
                                    onSeniorityChanged: (v) =>
                                        setState(() => _seniorityLevel = v),
                                    onSkillAdd: (s) {
                                      if (s.trim().isNotEmpty &&
                                          !_skills.contains(s.trim())) {
                                        setState(() => _skills.add(s.trim()));
                                        _skillInputCtrl.clear();
                                      }
                                    },
                                    onSkillRemove: (s) =>
                                        setState(() => _skills.remove(s)),
                                  ),
                                  const SizedBox(height: 14),
                                  _CvSection(isDark: isDark, l10n: l10n),
                                ],
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 80.ms)
                      else
                        Column(
                          children: [
                            _LeftPanel(
                              data: profileState.profile ??
                                  const CandidateProfileData(fullName: '', email: ''),
                              isDark: isDark,
                              l10n: l10n,
                            ).animate().fadeIn(delay: 60.ms),
                            const SizedBox(height: 20),
                            _ProfileForm(
                              editing: _editing,
                              data: profileState.profile ??
                                  const CandidateProfileData(fullName: '', email: ''),
                              isDark: isDark,
                              l10n: l10n,
                              nameCtrl: _nameCtrl,
                              bioCtrl: _bioCtrl,
                              targetRoleCtrl: _targetRoleCtrl,
                              linkedinCtrl: _linkedinCtrl,
                              githubCtrl: _githubCtrl,
                              skillInputCtrl: _skillInputCtrl,
                              seniorityLevel: _seniorityLevel,
                              skills: _skills,
                              onSeniorityChanged: (v) =>
                                  setState(() => _seniorityLevel = v),
                              onSkillAdd: (s) {
                                if (s.trim().isNotEmpty &&
                                    !_skills.contains(s.trim())) {
                                  setState(() => _skills.add(s.trim()));
                                  _skillInputCtrl.clear();
                                }
                              },
                              onSkillRemove: (s) =>
                                  setState(() => _skills.remove(s)),
                            ).animate().fadeIn(delay: 100.ms),
                            const SizedBox(height: 14),
                            _CvSection(isDark: isDark, l10n: l10n)
                                .animate().fadeIn(delay: 120.ms),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }
}

// ── Left Panel (avatar + achievements) ───────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  final CandidateProfileData data;
  final bool isDark;
  final AppLocalizations l10n;

  const _LeftPanel({
    required this.data,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1F35) : Colors.white;
    final borderC =
        isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);
    final earnedCount =
        achievements.where((a) => a.earned).length;

    return Column(
      children: [
        // Avatar card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderC),
          ),
          child: Column(
            children: [
              // Avatar ring
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6C47FF)],
                  ),
                ),
                child: Center(
                  child: Text(
                    (data.fullName ?? 'U').isNotEmpty
                        ? (data.fullName ?? 'U')[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.fullName ?? l10n.notSet,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                data.targetRole ?? l10n.notSet,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Free plan badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: AppColors.brandPurple.withValues(alpha: 0.35)),
                ),
                child: Text(
                  l10n.freePlan,
                  style: const TextStyle(
                    color: AppColors.brandPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Achievements card
        Container(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.achievements,
                    style: TextStyle(
                      color:
                          isDark ? Colors.white : const Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.earnedCount(
                        earnedCount, achievements.length),
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: achievements.map((a) {
                  return _AchievementBadge(
                      achievement: a, isDark: isDark);
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool isDark;
  const _AchievementBadge(
      {required this.achievement, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final locked = !achievement.earned;
    return Tooltip(
      message: '${achievement.title}\n${achievement.description}',
      child: Container(
        decoration: BoxDecoration(
          color: locked
              ? (isDark
                  ? const Color(0xFF0D1117)
                  : const Color(0xFFF9FAFB))
              : AppColors.brandPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: locked
                ? (isDark
                    ? const Color(0xFF1E2640)
                    : const Color(0xFFE5E7EB))
                : AppColors.brandPurple.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 20,
                  color: locked ? null : null,
                ),
              ),
              if (locked)
                const Icon(Icons.lock_rounded,
                    size: 8, color: Color(0xFF4A5578)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Form ──────────────────────────────────────────────────────────────

class _ProfileForm extends StatelessWidget {
  final bool editing;
  final CandidateProfileData data;
  final bool isDark;
  final AppLocalizations l10n;
  final TextEditingController nameCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController targetRoleCtrl;
  final TextEditingController linkedinCtrl;
  final TextEditingController githubCtrl;
  final TextEditingController skillInputCtrl;
  final String? seniorityLevel;
  final List<String> skills;
  final ValueChanged<String?> onSeniorityChanged;
  final ValueChanged<String> onSkillAdd;
  final ValueChanged<String> onSkillRemove;

  const _ProfileForm({
    required this.editing,
    required this.data,
    required this.isDark,
    required this.l10n,
    required this.nameCtrl,
    required this.bioCtrl,
    required this.targetRoleCtrl,
    required this.linkedinCtrl,
    required this.githubCtrl,
    required this.skillInputCtrl,
    required this.seniorityLevel,
    required this.skills,
    required this.onSeniorityChanged,
    required this.onSkillAdd,
    required this.onSkillRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1F35) : Colors.white;
    final borderC =
        isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contact info
        _FormSection(
          title: l10n.contactInfo,
          cardBg: cardBg,
          borderC: borderC,
          isDark: isDark,
          children: [
            _FieldRow(
              label: 'Full Name',
              value: data.fullName ?? l10n.notSet,
              ctrl: nameCtrl,
              editing: editing,
              isDark: isDark,
              borderC: borderC,
            ),
            _EmailNote(email: data.email, isDark: isDark, l10n: l10n),
          ],
        ),

        const SizedBox(height: 14),

        // Career goals
        _FormSection(
          title: l10n.careerGoals,
          cardBg: cardBg,
          borderC: borderC,
          isDark: isDark,
          children: [
            _FieldRow(
              label: l10n.targetRole,
              value: data.targetRole ?? l10n.notSet,
              ctrl: targetRoleCtrl,
              hint: l10n.targetRoleHint,
              editing: editing,
              isDark: isDark,
              borderC: borderC,
            ),
            _SeniorityRow(
              label: l10n.seniorityLevel,
              value: data.seniorityLevel ?? l10n.notSet,
              selected: editing ? seniorityLevel : data.seniorityLevel,
              editing: editing,
              isDark: isDark,
              borderC: borderC,
              l10n: l10n,
              onChanged: onSeniorityChanged,
            ),
            _TextAreaRow(
              label: l10n.bio,
              value: data.bio ?? l10n.notSet,
              ctrl: bioCtrl,
              hint: l10n.bioHint,
              editing: editing,
              isDark: isDark,
              borderC: borderC,
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Skills
        _FormSection(
          title: l10n.skillsExpertise,
          cardBg: cardBg,
          borderC: borderC,
          isDark: isDark,
          children: [
            _SkillsEditor(
              displaySkills: editing ? skills : data.techStack,
              editing: editing,
              isDark: isDark,
              borderC: borderC,
              ctrl: skillInputCtrl,
              l10n: l10n,
              onAdd: onSkillAdd,
              onRemove: onSkillRemove,
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Social
        _FormSection(
          title: l10n.socialLinks,
          cardBg: cardBg,
          borderC: borderC,
          isDark: isDark,
          children: [
            _FieldRow(
              label: 'LinkedIn',
              value: data.linkedInUrl ?? l10n.notSet,
              ctrl: linkedinCtrl,
              hint: l10n.linkedInUrl,
              editing: editing,
              isDark: isDark,
              borderC: borderC,
            ),
            _FieldRow(
              label: 'GitHub',
              value: data.githubUrl ?? l10n.notSet,
              ctrl: githubCtrl,
              hint: l10n.githubUrl,
              editing: editing,
              isDark: isDark,
              borderC: borderC,
            ),
          ],
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final Color cardBg;
  final Color borderC;
  final bool isDark;
  final List<Widget> children;

  const _FormSection({
    required this.title,
    required this.cardBg,
    required this.borderC,
    required this.isDark,
    required this.children,
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
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final TextEditingController ctrl;
  final String? hint;
  final bool editing;
  final bool isDark;
  final Color borderC;

  const _FieldRow({
    required this.label,
    required this.value,
    required this.ctrl,
    required this.editing,
    required this.isDark,
    required this.borderC,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (!editing)
            Text(
              value,
              style: TextStyle(
                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                fontSize: 14,
              ),
            )
          else
            TextField(
              controller: ctrl,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderC),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderC),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.brandPurple),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
              ),
            ),
        ],
      ),
    );
  }
}

class _TextAreaRow extends StatelessWidget {
  final String label;
  final String value;
  final TextEditingController ctrl;
  final String? hint;
  final bool editing;
  final bool isDark;
  final Color borderC;

  const _TextAreaRow({
    required this.label,
    required this.value,
    required this.ctrl,
    required this.editing,
    required this.isDark,
    required this.borderC,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (!editing)
            Text(
              value,
              style: TextStyle(
                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                fontSize: 14,
                height: 1.6,
              ),
            )
          else
            TextField(
              controller: ctrl,
              maxLines: 4,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderC),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderC),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.brandPurple),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
              ),
            ),
        ],
      ),
    );
  }
}

class _SeniorityRow extends StatelessWidget {
  final String label;
  final String value;
  final String? selected;
  final bool editing;
  final bool isDark;
  final Color borderC;
  final AppLocalizations l10n;
  final ValueChanged<String?> onChanged;

  const _SeniorityRow({
    required this.label,
    required this.value,
    required this.selected,
    required this.editing,
    required this.isDark,
    required this.borderC,
    required this.l10n,
    required this.onChanged,
  });

  static const _levels = ['Junior', 'Mid-level', 'Senior', 'Lead', 'Principal'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (!editing)
            Text(
              value,
              style: TextStyle(
                color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                fontSize: 14,
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: selected,
              hint: Text(
                l10n.selectLevel,
                style: TextStyle(
                  color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 14,
              ),
              dropdownColor:
                  isDark ? const Color(0xFF1A1F35) : Colors.white,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderC),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderC),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.brandPurple),
                ),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
              ),
              items: _levels
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _SkillsEditor extends StatelessWidget {
  final List<String> displaySkills;
  final bool editing;
  final bool isDark;
  final Color borderC;
  final TextEditingController ctrl;
  final AppLocalizations l10n;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _SkillsEditor({
    required this.displaySkills,
    required this.editing,
    required this.isDark,
    required this.borderC,
    required this.ctrl,
    required this.l10n,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: displaySkills.map((s) {
            return Chip(
              label: Text(
                s,
                style: TextStyle(
                  color: isDark ? const Color(0xFFA78BFA) : AppColors.brandPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: AppColors.brandPurple.withValues(alpha: isDark ? 0.15 : 0.08),
              side: BorderSide(
                  color: AppColors.brandPurple.withValues(alpha: isDark ? 0.35 : 0.25)),
              deleteIcon: editing
                  ? const Icon(Icons.close_rounded, size: 14)
                  : null,
              deleteIconColor: const Color(0xFF9CA3AF),
              onDeleted: editing ? () => onRemove(s) : null,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            );
          }).toList(),
        ),
        if (editing) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  onSubmitted: onAdd,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.skillHint,
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderC),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderC),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.brandPurple),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0D1117)
                        : const Color(0xFFF9FAFB),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => onAdd(ctrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  elevation: 0,
                ),
                child: Text(l10n.addSkill, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EmailNote extends StatelessWidget {
  final String? email;
  final bool isDark;
  final AppLocalizations l10n;

  const _EmailNote({required this.email, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email',
            style: TextStyle(
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email ?? l10n.notSet,
            style: TextStyle(
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.emailNote,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final bool isDark;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── CV Section ────────────────────────────────────────────────────────────────

const _kAllowedExts = ['pdf', 'docx', 'jpg', 'jpeg', 'png'];
const _kMaxSizeBytes = 10 * 1024 * 1024; // 10 MB

class _CvSection extends ConsumerStatefulWidget {
  final bool isDark;
  final AppLocalizations l10n;

  const _CvSection({required this.isDark, required this.l10n});

  @override
  ConsumerState<_CvSection> createState() => _CvSectionState();
}

class _CvSectionState extends ConsumerState<_CvSection> {
  Future<void> _pickAndUpload({bool replace = false}) async {
    // Client-side validate: format
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _kAllowedExts,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final ext = (file.extension ?? '').toLowerCase();

    if (!_kAllowedExts.contains(ext)) {
      _toast(widget.l10n.cvFormatError, isError: true);
      return;
    }
    if ((file.size) > _kMaxSizeBytes) {
      _toast(widget.l10n.cvSizeError, isError: true);
      return;
    }

    final path = file.path;
    if (path == null) {
      _toast('Không thể đọc file.', isError: true);
      return;
    }

    final error = await ref
        .read(cvProvider.notifier)
        .upload(path, file.name);

    if (!mounted) return;
    if (error == null) {
      _toast(widget.l10n.cvUploadSuccess);
    } else {
      _toast(error, isError: true);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = widget.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            widget.isDark ? const Color(0xFF1A1F35) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Text(
          l10n.deleteCvTitle,
          style: TextStyle(
            color: widget.isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.deleteCvBody,
          style: TextStyle(
            color: widget.isDark
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.deleteCv,
              style: const TextStyle(
                  color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final ok = await ref.read(cvProvider.notifier).delete();
    if (!mounted) return;
    if (ok) {
      _toast(widget.l10n.cvDeleteSuccess);
    } else {
      final err = ref.read(cvProvider).error;
      _toast(err ?? 'Xóa CV thất bại.', isError: true);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final cvState = ref.watch(cvProvider);
    final l10n = widget.l10n;
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF1A1F35) : Colors.white;
    final borderC =
        isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);

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
          Row(
            children: [
              const Icon(Icons.description_rounded,
                  size: 16, color: AppColors.brandPurple),
              const SizedBox(width: 6),
              Text(
                l10n.cvResume,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Loading (initial fetch) ───────────────────────────────────────
          if (cvState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                    color: AppColors.brandPurple, strokeWidth: 2),
              ),
            )

          // ── Uploading / parsing AI ────────────────────────────────────────
          else if (cvState.isUploading)
            _UploadingIndicator(isDark: isDark, l10n: l10n)

          // ── Has CV ────────────────────────────────────────────────────────
          else if (cvState.hasCV)
            _CvCard(
              cv: cvState.cv!,
              isDark: isDark,
              l10n: l10n,
              isDeleting: cvState.isDeleting,
              onReplace: () => _pickAndUpload(replace: true),
              onDelete: _confirmDelete,
            )

          // ── Empty state ───────────────────────────────────────────────────
          else
            _CvEmptyState(
              isDark: isDark,
              l10n: l10n,
              onUpload: _pickAndUpload,
            ),
        ],
      ),
    );
  }
}

// ── Uploading indicator ───────────────────────────────────────────────────────

class _UploadingIndicator extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  const _UploadingIndicator({required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.brandPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                color: AppColors.brandPurple, strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.cvUploading,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFFD1D5DB)
                    : const Color(0xFF374151),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _CvEmptyState extends StatelessWidget {
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onUpload;
  const _CvEmptyState(
      {required this.isDark, required this.l10n, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2640) : const Color(0xFFE5E7EB),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.upload_file_rounded,
            size: 40,
            color: isDark
                ? const Color(0xFF4A5578)
                : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.noCvYet,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.noCvHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF9CA3AF),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.acceptedFormats,
            style: const TextStyle(
                color: Color(0xFF4A5578),
                fontSize: 11),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_rounded, size: 16),
            label: Text(l10n.uploadCv),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loaded CV card ────────────────────────────────────────────────────────────

class _CvCard extends StatelessWidget {
  final CvData cv;
  final bool isDark;
  final AppLocalizations l10n;
  final bool isDeleting;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  const _CvCard({
    required this.cv,
    required this.isDark,
    required this.l10n,
    required this.isDeleting,
    required this.onReplace,
    required this.onDelete,
  });

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final textColor =
        isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final borderC =
        isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);

    final allSkills = [
      ...cv.skills,
      ...cv.techStack.where((s) => !cv.skills.contains(s))
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File name row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderC),
          ),
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFFA78BFA)
                      : AppColors.brandPurple),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.cvFileName ?? 'CV',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cv.parsedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.cvParsedAt}: ${_formatDate(cv.parsedAt)}',
                        style: TextStyle(color: labelColor, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: Color(0xFF10B981)),
            ],
          ),
        ),

        // Skills extracted
        if (allSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.cvSkillsLabel,
              style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: allSkills
                .map((s) => _SkillChip(label: s, isDark: isDark))
                .toList(),
          ),
        ],

        // AI Summary
        if (cv.summary != null && cv.summary!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.cvSummaryLabel,
              style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.brandPurple.withValues(alpha: 0.2)),
            ),
            child: Text(
              cv.summary!,
              style: TextStyle(
                  color: textColor, fontSize: 12, height: 1.6),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReplace,
                icon: const Icon(Icons.swap_horiz_rounded, size: 15),
                label: Text(l10n.replaceCv),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandPurple,
                  side: const BorderSide(color: AppColors.brandPurple),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                            color: Color(0xFFEF4444), strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded, size: 15),
                label: Text(l10n.deleteCv),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SkillChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandPurple
            .withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: AppColors.brandPurple
                .withValues(alpha: isDark ? 0.35 : 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark
              ? const Color(0xFFA78BFA)
              : AppColors.brandPurple,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
