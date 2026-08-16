import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/widgets/grid_background.dart';
import '../../hr_generate/data/generation_api.dart';
import '../../hr_generate/domain/enums/difficulty_level.dart';
import '../../hr_generate/domain/enums/question_type.dart';
import '../../hr_generate/presentation/gen_colors.dart';

// ── Local Question Model ──────────────────────────────────────────────────────

class _ManualQ {
  final String localId;
  String content;
  HrQuestionType type;
  HrDifficultyLevel difficulty;
  String sampleAnswer;
  String rationale;
  String? remoteId;

  _ManualQ({
    required this.localId,
    this.content = '',
    this.type = HrQuestionType.technical,
    this.difficulty = HrDifficultyLevel.medium,
    this.sampleAnswer = '',
    this.rationale = '',
    this.remoteId,
  });

  _ManualQ copyWith({
    String? content,
    HrQuestionType? type,
    HrDifficultyLevel? difficulty,
    String? sampleAnswer,
    String? rationale,
    String? remoteId,
  }) =>
      _ManualQ(
        localId:      localId,
        content:      content      ?? this.content,
        type:         type         ?? this.type,
        difficulty:   difficulty   ?? this.difficulty,
        sampleAnswer: sampleAnswer ?? this.sampleAnswer,
        rationale:    rationale    ?? this.rationale,
        remoteId:     remoteId     ?? this.remoteId,
      );

  Map<String, dynamic> toJson() => {
        'question':    content.trim(),
        'questionType': type.toApiString(),
        'difficulty':  difficulty.toApiString(),
        if (sampleAnswer.trim().isNotEmpty) 'sampleAnswer': sampleAnswer.trim(),
        if (rationale.trim().isNotEmpty)    'rationale':    rationale.trim(),
      };

  bool get isValid => content.trim().length >= 10;
}

// ── State ─────────────────────────────────────────────────────────────────────

class ManualBuilderState {
  final int step; // 1-4
  // Meta (step 1)
  final String title;
  final String role;
  final String experienceLevel;
  final HrDifficultyLevel defaultDifficulty;
  // Questions (step 2)
  final List<_ManualQ> questions;
  // Post-save
  final String? questionSetId;
  // UI
  final bool saving;
  final bool publishing;
  final bool saved;
  final String? error;

  const ManualBuilderState({
    this.step              = 1,
    this.title             = '',
    this.role              = '',
    this.experienceLevel   = '',
    this.defaultDifficulty = HrDifficultyLevel.medium,
    this.questions         = const [],
    this.questionSetId,
    this.saving            = false,
    this.publishing        = false,
    this.saved             = false,
    this.error,
  });

  ManualBuilderState copyWith({
    int? step,
    String? title,
    String? role,
    String? experienceLevel,
    HrDifficultyLevel? defaultDifficulty,
    List<_ManualQ>? questions,
    String? questionSetId,
    bool? saving,
    bool? publishing,
    bool? saved,
    String? error,
    bool clearError = false,
  }) =>
      ManualBuilderState(
        step:             step             ?? this.step,
        title:            title            ?? this.title,
        role:             role             ?? this.role,
        experienceLevel:  experienceLevel  ?? this.experienceLevel,
        defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
        questions:        questions        ?? this.questions,
        questionSetId:    questionSetId    ?? this.questionSetId,
        saving:           saving           ?? this.saving,
        publishing:       publishing       ?? this.publishing,
        saved:            saved            ?? this.saved,
        error:            clearError ? null : (error ?? this.error),
      );

  bool get metaValid => title.trim().length >= 3;
  bool get hasQuestions => questions.isNotEmpty && questions.every((q) => q.isValid);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ManualBuilderNotifier extends StateNotifier<ManualBuilderState> {
  ManualBuilderNotifier() : super(const ManualBuilderState());

  int _nextId = 0;
  String _newId() => 'local_${_nextId++}';

  // ── Navigation ─────────────────────────────────────────────────────────────

  void goStep(int s) {
    if (s < 1 || s > 4) return;
    state = state.copyWith(step: s);
  }

  // ── Step 1 ─────────────────────────────────────────────────────────────────

  void setTitle(String v)           => state = state.copyWith(title: v);
  void setRole(String v)            => state = state.copyWith(role: v);
  void setExperienceLevel(String v) => state = state.copyWith(experienceLevel: v);
  void setDefaultDifficulty(HrDifficultyLevel v) =>
      state = state.copyWith(defaultDifficulty: v);

  // ── Step 2 ─────────────────────────────────────────────────────────────────

  void addQuestion() {
    final q = _ManualQ(
      localId:    _newId(),
      difficulty: state.defaultDifficulty,
    );
    state = state.copyWith(questions: [...state.questions, q]);
  }

  void updateQuestion(String localId, {
    String? content,
    HrQuestionType? type,
    HrDifficultyLevel? difficulty,
    String? sampleAnswer,
    String? rationale,
  }) {
    state = state.copyWith(
      questions: state.questions.map((q) {
        if (q.localId != localId) return q;
        return q.copyWith(
          content:      content,
          type:         type,
          difficulty:   difficulty,
          sampleAnswer: sampleAnswer,
          rationale:    rationale,
        );
      }).toList(),
    );
  }

  void removeQuestion(String localId) {
    state = state.copyWith(
      questions: state.questions.where((q) => q.localId != localId).toList(),
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> save({bool publish = false}) async {
    if (!state.metaValid || state.questions.isEmpty) return;
    state = state.copyWith(saving: true, clearError: true);

    try {
      final dio = buildGenerationDio();

      // 1. Create the question set
      final createRes = await dio.post('/api/hr/question-sets', data: {
        'title':           state.title.trim(),
        if (state.role.trim().isNotEmpty) 'role': state.role.trim(),
        if (state.experienceLevel.trim().isNotEmpty)
          'experienceLevel': state.experienceLevel.trim(),
        'difficulty': state.defaultDifficulty.toApiString(),
        'source': 'manual',
      });
      final setId = _pickId(createRes.data);
      if (setId == null || setId.isEmpty) {
        throw Exception('Backend did not return question set ID');
      }

      // 2. Batch-add all questions
      final questionsPayload = state.questions
          .where((q) => q.isValid)
          .map((q) => q.toJson())
          .toList();

      try {
        await dio.post(
          '/api/hr/question-sets/$setId/questions/batch',
          data: {'questions': questionsPayload},
        );
      } catch (_) {
        // Fallback: add individually
        for (final q in state.questions.where((q) => q.isValid)) {
          await dio.post(
            '/api/hr/question-sets/$setId/questions',
            data: q.toJson(),
          );
        }
      }

      // 3. Optionally publish
      if (publish) {
        await dio.post('/api/hr/question-sets/$setId/publish');
      }

      state = state.copyWith(
        saving:        false,
        saved:         true,
        questionSetId: setId,
        step:          4,
        publishing:    false,
      );
    } on DioException catch (e) {
      state = state.copyWith(saving: false, error: _friendlyErr(e));
    } catch (e) {
      state = state.copyWith(saving: false, error: e.toString());
    }
  }

  Future<void> publish() async {
    final setId = state.questionSetId;
    if (setId == null) return;
    state = state.copyWith(publishing: true);
    try {
      final dio = buildGenerationDio();
      await dio.post('/api/hr/question-sets/$setId/publish');
      state = state.copyWith(publishing: false);
    } on DioException catch (e) {
      state = state.copyWith(publishing: false, error: _friendlyErr(e));
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String? _pickId(dynamic raw) {
    if (raw is Map) {
      final d = raw['data'] ?? raw;
      if (d is Map) {
        return (d['questionSetId'] ?? d['id'] ?? d['setId'])?.toString();
      }
    }
    return null;
  }

  static String _friendlyErr(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    final code = e.response?.statusCode;
    if (code != null) return 'Lỗi server ($code). Vui lòng thử lại.';
    return 'Lỗi kết nối. Vui lòng kiểm tra mạng.';
  }
}

final manualBuilderProvider =
    StateNotifierProvider.autoDispose<ManualBuilderNotifier, ManualBuilderState>(
        (_) => ManualBuilderNotifier());

// ── Screen ────────────────────────────────────────────────────────────────────

class ManualBuilderScreen extends ConsumerStatefulWidget {
  const ManualBuilderScreen({super.key});

  @override
  ConsumerState<ManualBuilderScreen> createState() =>
      _ManualBuilderScreenState();
}

class _ManualBuilderScreenState extends ConsumerState<ManualBuilderScreen> {
  // Step 1 controllers
  final _titleCtrl  = TextEditingController();
  final _roleCtrl   = TextEditingController();
  final _levelCtrl  = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _roleCtrl.dispose();
    _levelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ManualBuilderState>(manualBuilderProvider, (prev, next) {
      final err = next.error;
      if (err != null && err != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(manualBuilderProvider.notifier).clearError();
      }
    });

    final state   = ref.watch(manualBuilderProvider);
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final gc      = GenColors.of(context);

    return Scaffold(
      backgroundColor: gc.bg,
      appBar: _buildAppBar(context, state, isDark),
      body: GridBackdrop(
        child: Column(
        children: [
          if (state.step <= 2)
            _ModeToggleBar(isDark: isDark),
          _StepBar4(current: state.step, isDark: isDark),
          Divider(
            height: 1, thickness: 1,
            color: isDark ? const Color(0xFF1E2640) : const Color(0xFFE5E7EB),
          ),
          Expanded(child: _buildStep(state, isDark, gc)),
        ],
      ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext ctx, ManualBuilderState state,
      bool isDark) {
    final l10n = AppLocalizations.of(ctx)!;
    return AppBar(
      backgroundColor:  isDark ? const Color(0xFF0B1020) : Colors.white,
      elevation:        0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.close_rounded,
            color: isDark ? Colors.white70 : const Color(0xFF374151)),
        onPressed: () => _confirmExit(ctx, state),
      ),
      title: Text(
        l10n.manualCreate,
        style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize:   17,
            fontWeight: FontWeight.w700),
      ),
      actions: [
        if (state.step == 3 && !state.saved)
          _TopSaveBtn(saving: state.saving, onTap: () {
            ref.read(manualBuilderProvider.notifier).save();
          }),
      ],
    );
  }

  Widget _buildStep(ManualBuilderState state, bool isDark, GenColors gc) {
    switch (state.step) {
      case 1:
        return _MetaStep(
          isDark:      isDark,
          gc:          gc,
          titleCtrl:   _titleCtrl,
          roleCtrl:    _roleCtrl,
          levelCtrl:   _levelCtrl,
          state:       state,
          onContinue:  () {
            final n = ref.read(manualBuilderProvider.notifier);
            n.setTitle(_titleCtrl.text);
            n.setRole(_roleCtrl.text);
            n.setExperienceLevel(_levelCtrl.text);
            if (state.metaValid) n.goStep(2);
          },
        );
      case 2:
        return _AddQuestionsStep(
          isDark:     isDark,
          gc:         gc,
          state:      state,
          notifier:   ref.read(manualBuilderProvider.notifier),
          onContinue: () => ref.read(manualBuilderProvider.notifier).goStep(3),
        );
      case 3:
        return _ReviewStep(
          isDark:     isDark,
          gc:         gc,
          state:      state,
          notifier:   ref.read(manualBuilderProvider.notifier),
          onSave:     () => ref.read(manualBuilderProvider.notifier).save(),
          onBack:     () => ref.read(manualBuilderProvider.notifier).goStep(2),
        );
      case 4:
        return _DoneStep(
          isDark:    isDark,
          gc:        gc,
          state:     state,
          notifier:  ref.read(manualBuilderProvider.notifier),
          onHistory: () => context.go('/hr/history'),
          onNew:     () {
            // Reset state by re-read after the provider auto-disposes on nav
            context.go('/hr/manual-builder');
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _confirmExit(BuildContext ctx, ManualBuilderState state) async {
    if (state.step == 4 || (state.questions.isEmpty && state.title.isEmpty)) {
      ctx.pop();
      return;
    }
    final l10n = AppLocalizations.of(ctx)!;
    final isVi = l10n.isVi;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(isVi ? 'Thoát?' : 'Exit?'),
        content: Text(isVi
            ? 'Tiến trình chưa lưu sẽ bị mất.'
            : 'Unsaved progress will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(isVi ? 'Ở lại' : 'Stay')),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: Text(isVi ? 'Thoát' : 'Exit'),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) ctx.pop();
  }

  List<_ManualQ> get questions =>
      ref.read(manualBuilderProvider).questions;
}

// ── Step Bar ──────────────────────────────────────────────────────────────────

class _StepBar4 extends StatelessWidget {
  final int current;
  final bool isDark;

  const _StepBar4({
    required this.current,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = l10n.isVi
        ? ['Thông tin', 'Câu hỏi', 'Xem lại', 'Hoàn tất']
        : ['Info', 'Questions', 'Review', 'Done'];

    return Container(
      color: isDark ? const Color(0xFF0B1020) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepBefore = (i ~/ 2) + 1;
            final done = stepBefore < current;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: done
                      ? GenColors.primary
                      : (isDark ? const Color(0xFF2D3562) : const Color(0xFFE2E4EA)),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final step   = i ~/ 2 + 1;
          final done   = step < current;
          final active = step == current;
          final color  = (done || active)
              ? GenColors.primary
              : (isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF));

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width:  28,
                height: 28,
                decoration: BoxDecoration(
                  color: done
                      ? GenColors.primary
                      : active
                          ? GenColors.primary.withValues(alpha: 0.15)
                          : (isDark ? const Color(0xFF1E2640) : const Color(0xFFF3F4F6)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (done || active)
                        ? GenColors.primary
                        : (isDark ? const Color(0xFF2D3562) : const Color(0xFFE2E4EA)),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : Text(
                          '$step',
                          style: TextStyle(
                            color: active
                                ? GenColors.primary
                                : (isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF)),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[step - 1],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Top Save Button ───────────────────────────────────────────────────────────

class _TopSaveBtn extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;
  const _TopSaveBtn({required this.saving, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: TextButton(
          onPressed: saving ? null : onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6C47FF),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          ),
          child: saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF6C47FF)))
              : const Text('Lưu',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      );
}

// ── Step 1: Meta ──────────────────────────────────────────────────────────────

class _MetaStep extends ConsumerWidget {
  final bool isDark;
  final GenColors gc;
  final TextEditingController titleCtrl;
  final TextEditingController roleCtrl;
  final TextEditingController levelCtrl;
  final ManualBuilderState state;
  final VoidCallback onContinue;

  const _MetaStep({
    required this.isDark,
    required this.gc,
    required this.titleCtrl,
    required this.roleCtrl,
    required this.levelCtrl,
    required this.state,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(manualBuilderProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHint(
                  isDark: isDark,
                  text: 'Nhập thông tin cơ bản cho bộ câu hỏi của bạn.',
                ),
                const SizedBox(height: 20),

                // Title
                _Label('Tên bộ câu hỏi *', isDark: isDark),
                const SizedBox(height: 6),
                _InputField(
                  controller: titleCtrl,
                  isDark:     isDark,
                  hint:       'VD: Flutter Senior Developer Interview',
                  maxLength:  200,
                  onChanged:  notifier.setTitle,
                ),
                const SizedBox(height: 16),

                // Role
                _Label('Vị trí tuyển dụng', isDark: isDark),
                const SizedBox(height: 6),
                _InputField(
                  controller: roleCtrl,
                  isDark:     isDark,
                  hint:       'VD: Senior Flutter Developer',
                  onChanged:  notifier.setRole,
                ),
                const SizedBox(height: 16),

                // Experience level
                _Label('Cấp độ kinh nghiệm', isDark: isDark),
                const SizedBox(height: 6),
                _InputField(
                  controller: levelCtrl,
                  isDark:     isDark,
                  hint:       'VD: 3-5 năm kinh nghiệm',
                  onChanged:  notifier.setExperienceLevel,
                ),
                const SizedBox(height: 20),

                // Default difficulty
                _Label('Độ khó mặc định', isDark: isDark),
                const SizedBox(height: 8),
                Row(
                  children: HrDifficultyLevel.values.map((d) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _DiffChip(
                      label:    d.displayName,
                      selected: state.defaultDifficulty == d,
                      isDark:   isDark,
                      color:    d.badgeColor,
                      onTap:    () => notifier.setDefaultDifficulty(d),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        _SubmitBar(
          label:   AppLocalizations.of(context)!.isVi
              ? 'Tiếp theo: Thêm câu hỏi →'
              : 'Next: Add Questions →',
          enabled: state.metaValid,
          isDark:  isDark,
          gc:      gc,
          onTap:   onContinue,
        ),
      ],
    );
  }
}

// ── Step 2: Add Questions ─────────────────────────────────────────────────────

class _AddQuestionsStep extends ConsumerWidget {
  final bool isDark;
  final GenColors gc;
  final ManualBuilderState state;
  final ManualBuilderNotifier notifier;
  final VoidCallback onContinue;

  const _AddQuestionsStep({
    required this.isDark,
    required this.gc,
    required this.state,
    required this.notifier,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: state.questions.isEmpty
              ? _EmptyQuestionsHint(isDark: isDark, gc: gc, onAdd: notifier.addQuestion)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: state.questions.length,
                  itemBuilder: (ctx, i) => _QuestionEditor(
                    key:      ValueKey(state.questions[i].localId),
                    question: state.questions[i],
                    index:    i,
                    isDark:   isDark,
                    gc:       gc,
                    notifier: notifier,
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1020) : Colors.white,
              border: Border(top: BorderSide(
                color: isDark ? const Color(0xFF1E2640) : const Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                // Add question
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: notifier.addQuestion,
                    icon:  const Icon(Icons.add_circle_outline_rounded, size: 16),
                    label: Text(AppLocalizations.of(context)!.isVi ? 'Thêm câu hỏi' : 'Add Question'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GenColors.primary,
                      side:  const BorderSide(color: GenColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Continue
                Expanded(
                  child: FilledButton(
                    onPressed: state.hasQuestions ? onContinue : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: GenColors.primary,
                      disabledBackgroundColor: isDark
                          ? const Color(0xFF2D3562)
                          : const Color(0xFFE5E7EB),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.isVi
                          ? 'Xem lại (${state.questions.length})'
                          : 'Review (${state.questions.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyQuestionsHint extends StatelessWidget {
  final bool isDark;
  final GenColors gc;
  final VoidCallback onAdd;
  const _EmptyQuestionsHint({
    required this.isDark,
    required this.gc,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color:  GenColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.quiz_outlined, size: 40, color: GenColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có câu hỏi nào',
              style: TextStyle(
                  color:      isDark ? Colors.white : const Color(0xFF111827),
                  fontSize:   16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Nhấn nút bên dưới để thêm câu hỏi đầu tiên.',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon:  const Icon(Icons.add_rounded, size: 16),
              label: const Text('Thêm câu hỏi đầu tiên'),
              style: FilledButton.styleFrom(
                backgroundColor: GenColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      );
}

// ── Question Editor Card ──────────────────────────────────────────────────────

class _QuestionEditor extends StatefulWidget {
  final _ManualQ question;
  final int index;
  final bool isDark;
  final GenColors gc;
  final ManualBuilderNotifier notifier;

  const _QuestionEditor({
    super.key,
    required this.question,
    required this.index,
    required this.isDark,
    required this.gc,
    required this.notifier,
  });

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  late final _contentCtrl = TextEditingController(text: widget.question.content);
  late final _answerCtrl  = TextEditingController(text: widget.question.sampleAnswer);
  late final _rationaleCtrl = TextEditingController(text: widget.question.rationale);
  bool _expanded = true;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _answerCtrl.dispose();
    _rationaleCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.notifier.updateQuestion(
      widget.question.localId,
      content:      _contentCtrl.text,
      sampleAnswer: _answerCtrl.text,
      rationale:    _rationaleCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final q      = widget.question;
    final isDark = widget.isDark;
    final gc     = widget.gc;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB)),
        boxShadow: isDark
            ? null
            : [BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width:  24, height: 24,
                    decoration: BoxDecoration(
                      color:  GenColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: TextStyle(
                            color:      GenColors.primary,
                            fontSize:   11,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q.content.isEmpty ? 'Câu hỏi chưa nhập…' : q.content,
                      maxLines:  1,
                      overflow:  TextOverflow.ellipsis,
                      style: TextStyle(
                          color:      isDark
                              ? (q.content.isEmpty
                                  ? const Color(0xFF6B7280)
                                  : Colors.white)
                              : (q.content.isEmpty
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF111827)),
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          fontStyle: q.content.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: const Color(0xFFEF4444).withValues(alpha: 0.7)),
                    onPressed: () =>
                        widget.notifier.removeQuestion(q.localId),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            Divider(height: 1, color: isDark
                ? const Color(0xFF1E2640)
                : const Color(0xFFF3F4F6)),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type + Difficulty row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('Loại câu hỏi', isDark: isDark),
                            const SizedBox(height: 6),
                            _TypeDropdown(
                              value:    q.type,
                              isDark:   isDark,
                              gc:       gc,
                              onChanged: (t) => widget.notifier
                                  .updateQuestion(q.localId, type: t),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('Độ khó', isDark: isDark),
                            const SizedBox(height: 6),
                            _DiffDropdown(
                              value:    q.difficulty,
                              isDark:   isDark,
                              onChanged: (d) => widget.notifier
                                  .updateQuestion(q.localId, difficulty: d),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Question content
                  _FieldLabel('Nội dung câu hỏi *', isDark: isDark),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _contentCtrl,
                    minLines: 2,
                    maxLines: 5,
                    onChanged: (_) => _save(),
                    style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        fontSize: 13),
                    decoration: _inputDeco(
                      isDark: isDark,
                      hint: 'Nhập nội dung câu hỏi (tối thiểu 10 ký tự)…',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sample answer
                  _FieldLabel('Câu trả lời mẫu', isDark: isDark),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _answerCtrl,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (_) => _save(),
                    style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        fontSize: 13),
                    decoration: _inputDeco(
                      isDark: isDark,
                      hint: 'Câu trả lời kỳ vọng (không bắt buộc)…',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rationale
                  _FieldLabel('Lý do / Ghi chú', isDark: isDark),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _rationaleCtrl,
                    minLines: 1,
                    maxLines: 3,
                    onChanged: (_) => _save(),
                    style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        fontSize: 13),
                    decoration: _inputDeco(
                      isDark: isDark,
                      hint: 'Lý do chọn câu hỏi này (không bắt buộc)…',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDeco({required bool isDark, required String hint}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        filled: true,
        fillColor: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6C47FF), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}

// ── Step 3: Review ────────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  final bool isDark;
  final GenColors gc;
  final ManualBuilderState state;
  final ManualBuilderNotifier notifier;
  final VoidCallback onSave;
  final VoidCallback onBack;

  const _ReviewStep({
    required this.isDark,
    required this.gc,
    required this.state,
    required this.notifier,
    required this.onSave,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.title,
                      style: TextStyle(
                          color:      isDark ? Colors.white : const Color(0xFF111827),
                          fontSize:   15,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (state.role.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        state.role,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              _MetaBadge(
                label: '${state.questions.length} câu',
                isDark: isDark,
              ),
            ],
          ),
        ),

        // Questions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: state.questions.length,
            itemBuilder: (ctx, i) => _ReviewQCard(
              question: state.questions[i],
              index:    i,
              isDark:   isDark,
              gc:       gc,
            ),
          ),
        ),

        // Footer
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1020) : Colors.white,
              border: Border(top: BorderSide(
                color: isDark ? const Color(0xFF1E2640) : const Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon:  const Icon(Icons.arrow_back_rounded, size: 14),
                  label: Text(AppLocalizations.of(context)!.isVi ? 'Sửa' : 'Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF6B7280) : const Color(0xFF374151),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF4A5578) : const Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: state.saving ? null : onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: GenColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: state.saving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text(
                            'Lưu bộ câu hỏi',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewQCard extends StatelessWidget {
  final _ManualQ question;
  final int index;
  final bool isDark;
  final GenColors gc;

  const _ReviewQCard({
    required this.question,
    required this.index,
    required this.isDark,
    required this.gc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:  20, height: 20,
                decoration: BoxDecoration(
                  color:  GenColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: TextStyle(
                          color: GenColors.primary, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 8),
              _TypeTag(type: question.type, isDark: isDark),
              const SizedBox(width: 6),
              _DiffTag(diff: question.difficulty),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.content,
            style: TextStyle(
                color:      isDark ? Colors.white : const Color(0xFF111827),
                fontSize:   13,
                fontWeight: FontWeight.w600,
                height:     1.4),
          ),
          if (question.sampleAnswer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Trả lời: ${question.sampleAnswer}',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Step 4: Done ──────────────────────────────────────────────────────────────

class _DoneStep extends StatelessWidget {
  final bool isDark;
  final GenColors gc;
  final ManualBuilderState state;
  final ManualBuilderNotifier notifier;
  final VoidCallback onHistory;
  final VoidCallback onNew;

  const _DoneStep({
    required this.isDark,
    required this.gc,
    required this.state,
    required this.notifier,
    required this.onHistory,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width:  84, height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [GenColors.primary, const Color(0xFF3B82F6)],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:      GenColors.primary.withValues(alpha: 0.30),
                    blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 22),
            Text(
              'Bộ câu hỏi đã lưu!',
              style: TextStyle(
                  color:      isDark ? Colors.white : const Color(0xFF111827),
                  fontSize:   22,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.questions.length} câu hỏi đã được lưu thành công.\n'
              'Bạn có thể xuất bản để ứng viên luyện tập.',
              style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Publish button
            if (state.questionSetId != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.publishing
                      ? null
                      : () => notifier.publish(),
                  icon:  const Icon(Icons.public_rounded, size: 16),
                  label: state.publishing
                      ? const Text('Đang xuất bản…')
                      : const Text('Xuất bản ra Marketplace'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onHistory,
                icon:  const Icon(Icons.history_rounded, size: 16),
                label: const Text('Xem trong lịch sử'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GenColors.primary,
                  side:  BorderSide(color: GenColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onNew,
              child: Text(
                'Tạo bộ câu hỏi mới',
                style: TextStyle(
                    color: GenColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isDark;
  final GenColors gc;
  final VoidCallback onTap;

  const _SubmitBar({
    required this.label,
    required this.enabled,
    required this.isDark,
    required this.gc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1020) : Colors.white,
          border: Border(top: BorderSide(
            color: isDark ? const Color(0xFF1E2640) : const Color(0xFFE5E7EB))),
        ),
        child: SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: enabled
                  ? const LinearGradient(
                      colors: [GenColors.primary, Color(0xFF3B82F6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF2D3562), const Color(0xFF2D3562)]
                          : [const Color(0xFFE5E7EB), const Color(0xFFE5E7EB)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onTap : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: enabled
                          ? Colors.white
                          : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                      fontSize:   15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _SectionHint extends StatelessWidget {
  final bool isDark;
  final String text;
  const _SectionHint({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        const Color(0xFF6C47FF).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: const Color(0xFF6C47FF).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 16, color: Color(0xFF6C47FF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                    color: Color(0xFF6C47FF), fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color:      isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
          fontSize:   13,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color:    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String hint;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.isDark,
    required this.hint,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller:  controller,
        onChanged:   onChanged,
        maxLength:   maxLength,
        style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 14),
        decoration: InputDecoration(
          hintText:  hint,
          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
          filled:    true,
          fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
          counterText: '',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6C47FF), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );
}

class _DiffChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final Color color;
  final VoidCallback onTap;
  const _DiffChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:        selected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(
              color: selected
                  ? color
                  : (isDark ? const Color(0xFF2D3562) : const Color(0xFFE2E4EA)),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
                color:      selected ? color : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                fontSize:   12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400),
          ),
        ),
      );
}

class _TypeDropdown extends StatelessWidget {
  final HrQuestionType value;
  final bool isDark;
  final GenColors gc;
  final ValueChanged<HrQuestionType> onChanged;

  const _TypeDropdown({
    required this.value,
    required this.isDark,
    required this.gc,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<HrQuestionType>(
            value: value,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1A1F35) : Colors.white,
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 12),
            items: HrQuestionType.values.map((t) => DropdownMenuItem(
              value: t,
              child: Text(t.displayName, style: const TextStyle(fontSize: 12)),
            )).toList(),
            onChanged: (t) { if (t != null) onChanged(t); },
          ),
        ),
      );
}

class _DiffDropdown extends StatelessWidget {
  final HrDifficultyLevel value;
  final bool isDark;
  final ValueChanged<HrDifficultyLevel> onChanged;

  const _DiffDropdown({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE5E7EB)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<HrDifficultyLevel>(
            value: value,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1A1F35) : Colors.white,
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 12),
            items: HrDifficultyLevel.values.map((d) => DropdownMenuItem(
              value: d,
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: d.badgeColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(d.displayName, style: const TextStyle(fontSize: 12)),
                ],
              ),
            )).toList(),
            onChanged: (d) { if (d != null) onChanged(d); },
          ),
        ),
      );
}

class _TypeTag extends StatelessWidget {
  final HrQuestionType type;
  final bool isDark;
  const _TypeTag({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color:        const Color(0xFF6C47FF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          type.displayName,
          style: const TextStyle(
              color: Color(0xFF6C47FF), fontSize: 10, fontWeight: FontWeight.w600),
        ),
      );
}

class _DiffTag extends StatelessWidget {
  final HrDifficultyLevel diff;
  const _DiffTag({required this.diff});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color:        diff.badgeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          diff.displayName,
          style: TextStyle(
              color:      diff.badgeColor,
              fontSize:   10,
              fontWeight: FontWeight.w600),
        ),
      );
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final bool isDark;
  const _MetaBadge({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        const Color(0xFF6C47FF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: const Color(0xFF6C47FF).withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: const TextStyle(
                color:      Color(0xFF6C47FF),
                fontSize:   11,
                fontWeight: FontWeight.w700)),
      );
}

// ── Mode Toggle Bar ───────────────────────────────────────────────────────────

class _ModeToggleBar extends StatelessWidget {
  final bool isDark;
  const _ModeToggleBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: isDark ? const Color(0xFF0B1020) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : const Color(0xFFF0F1F5),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3562) : const Color(0xFFE2E4EA),
          ),
        ),
        child: Row(children: [
          // AI tab (inactive — tap to switch)
          _ModeTab(
            icon:   Icons.auto_awesome_rounded,
            label:  l10n.generateQuestions,
            active: false,
            isDark: isDark,
            onTap:  () => context.go('/hr/generate'),
          ),
          // Manual tab (active — current screen)
          _ModeTab(
            icon:   Icons.edit_note_rounded,
            label:  l10n.manualCreate,
            active: true,
            isDark: isDark,
            onTap:  null,
          ),
        ]),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     active;
  final bool     isDark;
  final VoidCallback? onTap;
  const _ModeTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor   = GenColors.primary;
    final inactiveColor = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: active
              ? BoxDecoration(
                  color: isDark ? const Color(0xFF1E2640) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? GenColors.primary.withValues(alpha: 0.35)
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color:      Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14,
                  color: active ? activeColor : inactiveColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color:      active ? activeColor : inactiveColor,
                  fontSize:   12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
