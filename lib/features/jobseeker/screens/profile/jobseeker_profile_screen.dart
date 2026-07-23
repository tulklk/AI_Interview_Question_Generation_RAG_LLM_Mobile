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

// ── Left Panel (hero card + achievements) ────────────────────────────────────

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
    final borderC = isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);
    final earnedCount = achievements.where((a) => a.earned).length;
    final initial = data.fullName.isNotEmpty
        ? data.fullName[0].toUpperCase()
        : 'U';

    return Column(
      children: [
        // ── Hero gradient card ─────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF2D1B69), const Color(0xFF1A1040)]
                    : [const Color(0xFF7C3AED), const Color(0xFF4F46E5)],
              ),
            ),
            child: Stack(
              children: [
                // Decorative background blobs
                Positioned(
                  top: -30, right: -30,
                  child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40, left: -20,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  top: 60, right: 20,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    children: [
                      // Glowing avatar
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.3),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.25),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Container(
                          width: 80, height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF9B72FF), Color(0xFF6C47FF)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 1.0, end: 1.03, duration: 2400.ms, curve: Curves.easeInOut),

                      const SizedBox(height: 16),
                      Text(
                        data.fullName.isNotEmpty ? data.fullName : l10n.notSet,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        data.targetRole?.isNotEmpty == true
                            ? data.targetRole!
                            : l10n.notSet,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      // Free plan badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium_rounded,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              l10n.freePlan,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _HeroStat(
                              value: '${data.techStack.length}',
                              label: 'Kỹ năng',
                            ),
                            Container(
                              width: 1, height: 28,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            _HeroStat(
                              value: '$earnedCount',
                              label: 'Thành tích',
                            ),
                            Container(
                              width: 1, height: 28,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            _HeroStat(
                              value: data.seniorityLevel?.isNotEmpty == true
                                  ? data.seniorityLevel!.split('-').first
                                  : '—',
                              label: 'Cấp độ',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.08, curve: Curves.easeOut),

        const SizedBox(height: 14),

        // ── Achievements card ──────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderC),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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
                    width: 4, height: 18,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF9B72FF), Color(0xFF6C47FF)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.achievements,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$earnedCount/${achievements.length} đạt',
                      style: const TextStyle(
                        color: AppColors.brandPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: achievements.asMap().entries.map((e) {
                  return _AchievementBadge(
                    achievement: e.value,
                    isDark: isDark,
                  )
                      .animate(delay: (e.key * 60).ms)
                      .fadeIn(duration: 400.ms)
                      .scaleXY(begin: 0.7, curve: Curves.easeOutBack);
                }).toList(),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 120.ms, duration: 500.ms).slideY(begin: 0.05),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool isDark;
  const _AchievementBadge({required this.achievement, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final earned = achievement.earned;
    return Tooltip(
      message: '${achievement.title}\n${achievement.description}',
      child: Container(
        decoration: BoxDecoration(
          gradient: earned
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandPurple.withValues(alpha: isDark ? 0.3 : 0.15),
                    AppColors.brandPurple.withValues(alpha: isDark ? 0.15 : 0.05),
                  ],
                )
              : null,
          color: earned
              ? null
              : (isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: earned
                ? AppColors.brandPurple.withValues(alpha: isDark ? 0.5 : 0.35)
                : (isDark ? const Color(0xFF1E2640) : const Color(0xFFE5E7EB)),
            width: earned ? 1.5 : 1,
          ),
          boxShadow: earned
              ? [
                  BoxShadow(
                    color: AppColors.brandPurple.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: earned ? 1.0 : 0.35,
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            if (!earned)
              Positioned(
                bottom: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2640)
                        : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      size: 9, color: Color(0xFF6B7280)),
                ),
              ),
            if (earned)
              Positioned(
                bottom: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 8, color: Colors.white),
                ),
              ),
          ],
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

class _SkillsEditor extends StatefulWidget {
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
  State<_SkillsEditor> createState() => _SkillsEditorState();
}

class _SkillsEditorState extends State<_SkillsEditor> {
  static const _maxVisible = 8;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final editing = widget.editing;
    final skills = widget.displaySkills;

    final visible = (editing || _expanded || skills.length <= _maxVisible)
        ? skills
        : skills.take(_maxVisible).toList();
    final hiddenCount = skills.length - _maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ...visible.map((s) => Chip(
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
              deleteIcon: editing ? const Icon(Icons.close_rounded, size: 14) : null,
              deleteIconColor: const Color(0xFF9CA3AF),
              onDeleted: editing ? () => widget.onRemove(s) : null,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            )),
            if (!editing && !_expanded && hiddenCount > 0)
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Chip(
                  label: Text(
                    '+$hiddenCount',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: isDark ? const Color(0xFF1E2640) : const Color(0xFFF3F4F6),
                  side: BorderSide(
                      color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
            if (!editing && _expanded && skills.length > _maxVisible)
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: Chip(
                  label: Text(
                    'Thu gọn',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: isDark ? const Color(0xFF1E2640) : const Color(0xFFF3F4F6),
                  side: BorderSide(
                      color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
          ],
        ),
        if (editing) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.ctrl,
                  onSubmitted: widget.onAdd,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.l10n.skillHint,
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.borderC),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.borderC),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.brandPurple),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => widget.onAdd(widget.ctrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                ),
                child: Text(widget.l10n.addSkill, style: const TextStyle(fontSize: 13)),
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

class _CvCard extends StatefulWidget {
  final CvData cv;
  final bool isDark;
  final AppLocalizations l10n;

  const _CvCard({
    required this.cv,
    required this.isDark,
    required this.l10n,
  });

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
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cv = widget.cv;
    final isDark = widget.isDark;
    final l10n = widget.l10n;
    final labelColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final textColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final borderC = isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB);

    final allSkills = [
      ...cv.skills,
      ...cv.techStack.where((s) => !cv.skills.contains(s)),
    ];
    final visibleSkills = _showAllSkills || allSkills.length <= _maxVisibleSkills
        ? allSkills
        : allSkills.take(_maxVisibleSkills).toList();
    final hiddenCount = allSkills.length - _maxVisibleSkills;

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
                  color: isDark ? const Color(0xFFA78BFA) : AppColors.brandPurple),
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
            children: [
              ...visibleSkills.map((s) => _SkillChip(label: s, isDark: isDark)),
              if (!_showAllSkills && hiddenCount > 0)
                GestureDetector(
                  onTap: () => setState(() => _showAllSkills = true),
                  child: _SkillChip(label: '+$hiddenCount', isDark: isDark, muted: true),
                ),
              if (_showAllSkills && allSkills.length > _maxVisibleSkills)
                GestureDetector(
                  onTap: () => setState(() => _showAllSkills = false),
                  child: _SkillChip(label: 'Thu gọn', isDark: isDark, muted: true),
                ),
            ],
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
              border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.2)),
            ),
            child: Text(
              cv.summary!,
              style: TextStyle(color: textColor, fontSize: 12, height: 1.6),
            ),
          ),
        ],
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool muted;
  const _SkillChip({required this.label, required this.isDark, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final bgColor = muted
        ? (isDark ? const Color(0xFF1E2640) : const Color(0xFFF3F4F6))
        : AppColors.brandPurple.withValues(alpha: isDark ? 0.15 : 0.08);
    final borderColor = muted
        ? (isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB))
        : AppColors.brandPurple.withValues(alpha: isDark ? 0.35 : 0.25);
    final textColor = muted
        ? (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))
        : (isDark ? const Color(0xFFA78BFA) : AppColors.brandPurple);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
