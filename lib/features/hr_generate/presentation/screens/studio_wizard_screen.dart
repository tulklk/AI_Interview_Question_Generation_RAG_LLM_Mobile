import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../gen_colors.dart';
import '../providers/badge_provider.dart';
import '../providers/studio_generation_provider.dart';
import '../views/studio_polling_view.dart';
import '../views/studio_question_review_view.dart';
import '../views/studio_failed_view.dart';
import '../views/studio_draft_saved_view.dart';
import '../../../../core/widgets/grid_background.dart';
import '../../../../features/subscription/subscription_provider.dart';
import '../../domain/models/studio_models.dart';

// ── Main wizard screen ────────────────────────────────────────────────────────

class StudioWizardScreen extends ConsumerStatefulWidget {
  final String? resumeJobId;
  const StudioWizardScreen({super.key, this.resumeJobId});

  @override
  ConsumerState<StudioWizardScreen> createState() => _StudioWizardScreenState();
}

class _StudioWizardScreenState extends ConsumerState<StudioWizardScreen> {
  String? _loadedJobId;

  // Sticky output prefs — never overwritten by API once set
  int _numQuestions = 10;
  String _difficulty = 'medium';
  final Set<String> _questionTypes = {'technical', 'behavioral'};

  final _jdCtrl   = TextEditingController();
  final _noteCtrl  = TextEditingController();
  final _chatCtrl  = TextEditingController();

  int  get _charCount => _jdCtrl.text.length;
  bool get _isValid   => _charCount >= 50;

  @override
  void initState() {
    super.initState();
    _jdCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(badgeProvider.notifier).setGenerationScreenActive(true);
      _syncSession();
    });
  }

  // Called by ref.listen when quotaBlocked flips to true
  void _onQuotaBlocked(String? errorMsg) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _CooldownDialog(message: errorMsg),
    ).then((_) {
      if (mounted) {
        ref.read(studioGenerationProvider.notifier).clearQuotaBlock();
      }
    });
  }

  @override
  void dispose() {
    _jdCtrl.dispose();
    _noteCtrl.dispose();
    _chatCtrl.dispose();
    final badge = ref.read(badgeProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      badge.setGenerationScreenActive(false);
    });
    super.dispose();
  }

  @override
  void didUpdateWidget(StudioWizardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resumeJobId != oldWidget.resumeJobId) {
      _loadedJobId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncSession());
    }
  }

  String? _jobIdFromRoute() {
    final fromWidget = widget.resumeJobId;
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    try {
      return GoRouterState.of(context).uri.queryParameters['jobId'];
    } catch (_) {
      return null;
    }
  }

  Future<void> _syncSession() async {
    final jobId   = _jobIdFromRoute();
    final notifier = ref.read(studioGenerationProvider.notifier);
    final current  = ref.read(studioGenerationProvider);

    if (jobId != null && jobId.isNotEmpty) {
      if (current.jobId == jobId &&
          current.currentView != 'form' &&
          !current.isRestoring) {
        _loadedJobId = jobId;
        return;
      }
      if (_loadedJobId == jobId && current.isRestoring) return;
      _loadedJobId = jobId;
      await notifier.resumeProject(jobId);
      return;
    }

    if (_loadedJobId != null) return;
    _loadedJobId = '__storage__';
    await notifier.restoreFromStorage();
  }

  Future<void> _minimizeAndExit() async {
    final view = ref.read(studioGenerationProvider).currentView;
    if (view != 'form') {
      await ref.read(studioGenerationProvider.notifier).minimize();
      ref.read(badgeProvider.notifier).syncNow();
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/hr/dashboard');
    }
  }

  Future<void> _submit() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập ít nhất 50 ký tự mô tả công việc.')),
      );
      return;
    }
    if (!ref.read(canGenerateNowProvider)) {
      await showQuotaDialog(context, trigger: 'studio_submit');
      return;
    }
    await ref.read(studioGenerationProvider.notifier).submitJob(
      jd:                _jdCtrl.text.trim(),
      numberOfQuestions: _numQuestions,
      difficulty:        _difficulty[0].toUpperCase() + _difficulty.substring(1),
      questionTypes:     _questionTypes.toList(),
    );
    ref.read(subscriptionProvider.notifier).onGenerationSuccess();
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context:            context,
      backgroundColor:    Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SettingsSheet(
        numQuestions:  _numQuestions,
        difficulty:    _difficulty,
        questionTypes: Set.of(_questionTypes),
        onSave: (num, diff, types) =>
            setState(() {
              _numQuestions = num;
              _difficulty   = diff;
              _questionTypes
                ..clear()
                ..addAll(types);
            }),
      ),
    );
  }

  static int _stepFor(String view, String pollingPhase) {
    switch (view) {
      case 'form':            return 1;
      case 'polling':         return pollingPhase == 'plan' ? 2 : 4;
      case 'plan_review':     return 3;
      case 'question_review':
      case 'draft_view':      return 4;
      case 'failed':          return pollingPhase == 'plan' ? 2 : 4;
      default:                return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show cooldown/quota dialog whenever quotaBlocked flips to true
    ref.listen<bool>(
      studioGenerationProvider.select((s) => s.quotaBlocked),
      (prev, next) {
        if (next == true && prev != true) {
          final msg = ref.read(studioGenerationProvider).error;
          _onQuotaBlocked(msg);
        }
      },
    );

    final isRestoring = ref.watch(
        studioGenerationProvider.select((s) => s.isRestoring));
    final currentView = ref.watch(
        studioGenerationProvider.select((s) => s.currentView));
    final pollingPhase = ref.watch(
        studioGenerationProvider.select((s) => s.pollingPhase));
    final c = GenColors.of(context);

    if (isRestoring) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: GenColors.primary),
              const SizedBox(height: 16),
              Text('Đang khôi phục phiên...',
                  style: TextStyle(color: c.textSub, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final step     = _stepFor(currentView, pollingPhase);
    final showStep = currentView != 'draft_view';
    final isForm   = currentView == 'form';

    return PopScope(
      canPop: isForm,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isForm) _minimizeAndExit();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor:  c.bg,
          elevation:        0,
          surfaceTintColor: Colors.transparent,
          centerTitle:      true,
          title: Text(
            'Tạo câu hỏi AI',
            style: TextStyle(
                color:      c.text,
                fontSize:   17,
                fontWeight: FontWeight.w700),
          ),
          leading: isForm
              ? IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: c.muted),
                  onPressed: () {
                    if (context.canPop()) context.pop();
                    else context.go('/hr/dashboard');
                  },
                )
              : IconButton(
                  icon:      Icon(Icons.close_rounded, color: c.muted),
                  onPressed: _minimizeAndExit,
                ),
          actions: isForm
              ? [
                  IconButton(
                    icon:    Icon(Icons.tune_rounded, color: c.muted),
                    tooltip: 'Tùy chọn đầu ra',
                    onPressed: _openSettings,
                  ),
                ]
              : null,
          bottom: showStep
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(68),
                  child: _StepIndicator4(currentStep: step),
                )
              : null,
        ),
        body: GridBackdrop(
          child: _StudioBody(
          currentView:   currentView,
          jdCtrl:        _jdCtrl,
          noteCtrl:      _noteCtrl,
          chatCtrl:      _chatCtrl,
          numQuestions:  _numQuestions,
          difficulty:    _difficulty,
          questionTypes: _questionTypes,
          onSubmit:      _submit,
          onOpenSettings: _openSettings,
        ),
        ),
      ),
    );
  }
}

// ── Studio body — layout switcher ─────────────────────────────────────────────
/// On mobile: stack panels. On wide screens: 3-column layout.

class _StudioBody extends ConsumerWidget {
  final String      currentView;
  final TextEditingController jdCtrl;
  final TextEditingController noteCtrl;
  final TextEditingController chatCtrl;
  final int         numQuestions;
  final String      difficulty;
  final Set<String> questionTypes;
  final VoidCallback onSubmit;
  final VoidCallback onOpenSettings;

  const _StudioBody({
    required this.currentView,
    required this.jdCtrl,
    required this.noteCtrl,
    required this.chatCtrl,
    required this.numQuestions,
    required this.difficulty,
    required this.questionTypes,
    required this.onSubmit,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideColumnsLocked = ref.watch(
        studioGenerationProvider.select((s) => s.sideColumnsLocked));
    final isForm = currentView == 'form';
    final width  = MediaQuery.of(context).size.width;
    // Use 3-column only for form view on wide screens
    final use3Col = !isForm && width >= 900;

    if (isForm) {
      return Column(children: [
        const QuotaWarningBanner(),
        Expanded(
          child: _JdInputStep(
            jdCtrl:         jdCtrl,
            noteCtrl:       noteCtrl,
            numQuestions:   numQuestions,
            difficulty:     difficulty,
            questionTypes:  questionTypes,
            onSubmit:       onSubmit,
            onOpenSettings: onOpenSettings,
          ),
        ),
      ]);
    }

    // Non-form views (polling, plan_review, question_review, failed, draft_view)
    if (use3Col) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel — JD + documents
          SizedBox(
            width: 280,
            child: AbsorbPointer(
              absorbing: sideColumnsLocked,
              child: Opacity(
                opacity: sideColumnsLocked ? 0.5 : 1.0,
                child: LeftDocumentsPanel(jdCtrl: jdCtrl),
              ),
            ),
          ),
          // Middle panel — chat + plan/view content
          Expanded(child: _MiddlePanelHost(currentView: currentView, chatCtrl: chatCtrl)),
          // Right panel — settings + questions
          SizedBox(
            width: 300,
            child: AbsorbPointer(
              absorbing: sideColumnsLocked,
              child: Opacity(
                opacity: sideColumnsLocked ? 0.5 : 1.0,
                child: RightSettingsPanel(),
              ),
            ),
          ),
        ],
      );
    }

    // Mobile — stack panels
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration:          const Duration(milliseconds: 200),
        switchInCurve:     Curves.easeOut,
        switchOutCurve:    Curves.easeIn,
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _buildMobileView(currentView, sideColumnsLocked, chatCtrl),
      ),
    );
  }

  Widget _buildMobileView(
      String view, bool locked, TextEditingController chatCtrl) {
    switch (view) {
      case 'polling':
        return const StudioPollingView(key: ValueKey('polling'));
      case 'plan_review':
        return StudioPlanReviewMobileView(
            key: const ValueKey('plan_review'), chatCtrl: chatCtrl);
      case 'question_review':
        return const StudioQuestionReviewView(key: ValueKey('question_review'));
      case 'failed':
        return const StudioFailedView(key: ValueKey('failed'));
      case 'draft_view':
        return const StudioDraftSavedView(key: ValueKey('draft_view'));
      default:
        return const SizedBox.shrink(key: ValueKey('empty'));
    }
  }
}

// ── Middle panel host (wide screen only) ─────────────────────────────────────

class _MiddlePanelHost extends ConsumerWidget {
  final String currentView;
  final TextEditingController chatCtrl;
  const _MiddlePanelHost({required this.currentView, required this.chatCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = GenColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left:  BorderSide(color: c.border),
          right: BorderSide(color: c.border),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _content(currentView, chatCtrl),
      ),
    );
  }

  Widget _content(String view, TextEditingController chatCtrl) {
    switch (view) {
      case 'polling':
        return const StudioPollingView(key: ValueKey('m_polling'));
      case 'plan_review':
        return StudioPlanReviewMobileView(
            key: const ValueKey('m_plan_review'), chatCtrl: chatCtrl);
      case 'question_review':
        return const StudioQuestionReviewView(key: ValueKey('m_qr'));
      case 'failed':
        return const StudioFailedView(key: ValueKey('m_failed'));
      case 'draft_view':
        return const StudioDraftSavedView(key: ValueKey('m_draft'));
      default:
        return const SizedBox.shrink(key: ValueKey('m_empty'));
    }
  }
}

// ── Left Panel — JD + Documents ───────────────────────────────────────────────

class LeftDocumentsPanel extends ConsumerStatefulWidget {
  final TextEditingController jdCtrl;
  const LeftDocumentsPanel({super.key, required this.jdCtrl});

  @override
  ConsumerState<LeftDocumentsPanel> createState() => _LeftDocumentsPanelState();
}

class _LeftDocumentsPanelState extends ConsumerState<LeftDocumentsPanel> {
  bool _showLibrary = false;
  List<StudioLibraryDocument> _libraryDocs = [];
  final Set<String> _selectedLibIds = {};
  bool _loadingLibrary = false;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'doc'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    await ref.read(studioGenerationProvider.notifier)
        .uploadDocument(File(path));
  }

  Future<void> _loadLibrary() async {
    final projectId = ref.read(studioGenerationProvider).projectId;
    if (projectId == null) return;
    setState(() => _loadingLibrary = true);
    try {
      final repo = ref.read(studioRepositoryProvider);
      _libraryDocs = await repo.listLibraryDocuments(projectId);
    } catch (_) {}
    setState(() => _loadingLibrary = false);
  }

  Future<void> _attachSelected() async {
    if (_selectedLibIds.isEmpty) return;
    await ref.read(studioGenerationProvider.notifier)
        .attachLibraryDocuments(_selectedLibIds.toList());
    setState(() {
      _showLibrary = false;
      _selectedLibIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c     = GenColors.of(context);
    final docs  = ref.watch(studioGenerationProvider.select((s) => s.documents));
    final state = ref.watch(studioGenerationProvider);

    return Container(
      color: c.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // JD section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Mô tả công việc',
                style: TextStyle(
                    color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color:        c.bg,
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(color: c.border),
              ),
              child: TextField(
                controller: widget.jdCtrl,
                minLines: 4,
                maxLines: 8,
                style: TextStyle(color: c.text, fontSize: 12, height: 1.55),
                cursorColor: GenColors.primary,
                decoration: InputDecoration(
                  hintText:       'Nội dung JD...',
                  hintStyle:      TextStyle(color: c.hint, fontSize: 12),
                  filled:         true,
                  fillColor:      c.bg,
                  border:         InputBorder.none,
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Save JD button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      final projectId = state.projectId;
                      if (projectId == null) return;
                      await ref.read(studioRepositoryProvider)
                          .saveJobDescription(projectId,
                              content: widget.jdCtrl.text.trim());
                    },
              icon: const Icon(Icons.save_outlined, size: 14),
              label: const Text('Lưu JD', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: GenColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const Divider(height: 16),

          // Documents section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Text('Tài liệu RAG',
                  style: TextStyle(
                      color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              // Upload button
              _IconActionBtn(
                icon:    Icons.upload_file_outlined,
                tooltip: 'Tải lên tài liệu',
                c:       c,
                onTap:   _pickAndUpload,
              ),
              const SizedBox(width: 6),
              // Library button
              _IconActionBtn(
                icon:    Icons.library_books_outlined,
                tooltip: 'Gắn từ thư viện',
                c:       c,
                onTap: () async {
                  setState(() => _showLibrary = !_showLibrary);
                  if (_showLibrary && _libraryDocs.isEmpty) await _loadLibrary();
                },
              ),
            ]),
          ),
          const SizedBox(height: 8),

          if (_showLibrary) ...[
            _LibraryPicker(
              docs:        _libraryDocs,
              loading:     _loadingLibrary,
              selected:    _selectedLibIds,
              onToggle:    (id) => setState(() {
                if (_selectedLibIds.contains(id)) {
                  _selectedLibIds.remove(id);
                } else {
                  _selectedLibIds.add(id);
                }
              }),
              onAttach:    _attachSelected,
              onClose:     () => setState(() => _showLibrary = false),
              c:           c,
            ),
            const SizedBox(height: 8),
          ],

          // Document list
          Expanded(
            child: docs.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có tài liệu.\nBấm ⬆ để tải lên.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.muted, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) => _DocTile(doc: docs[i], c: c),
                  ),
          ),
        ],
      ),
    );
  }
}

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final GenColors c;
  final VoidCallback onTap;
  const _IconActionBtn({
    required this.icon,
    required this.tooltip,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color:        c.bg,
          borderRadius: BorderRadius.circular(6),
          border:       Border.all(color: c.border),
        ),
        child: Icon(icon, size: 14, color: c.textSub),
      ),
    ),
  );
}

class _DocTile extends ConsumerWidget {
  final StudioDocument doc;
  final GenColors c;
  const _DocTile({required this.doc, required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(doc.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: c.border),
      ),
      child: Row(children: [
        // Selection toggle
        GestureDetector(
          onTap: () => ref.read(studioGenerationProvider.notifier)
              .toggleDocumentSelection(doc.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 16, height: 16,
            decoration: BoxDecoration(
              color:  doc.isSelected ? GenColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: doc.isSelected ? GenColors.primary : c.border,
                  width: 1.5),
            ),
            child: doc.isSelected
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        // Icon
        Icon(
          doc.isLibraryLink
              ? Icons.library_books_outlined
              : Icons.description_outlined,
          size: 14, color: c.muted,
        ),
        const SizedBox(width: 6),
        // Name + status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.fileName,
                  style: TextStyle(color: c.text, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(doc.status.displayLabel,
                    style: TextStyle(color: color, fontSize: 9)),
              ]),
            ],
          ),
        ),
        // Delete
        GestureDetector(
          onTap: () => ref.read(studioGenerationProvider.notifier)
              .deleteDocument(doc.id),
          child: Icon(Icons.close_rounded, size: 14, color: c.muted),
        ),
      ]),
    );
  }

  Color _statusColor(StudioDocumentStatus s) {
    switch (s) {
      case StudioDocumentStatus.completed:  return const Color(0xFF10B981);
      case StudioDocumentStatus.processing: return const Color(0xFFF59E0B);
      case StudioDocumentStatus.failed:     return const Color(0xFFEF4444);
      case StudioDocumentStatus.pending:    return const Color(0xFF9CA3AF);
    }
  }
}

class _LibraryPicker extends StatelessWidget {
  final List<StudioLibraryDocument> docs;
  final bool loading;
  final Set<String> selected;
  final void Function(String) onToggle;
  final VoidCallback onAttach;
  final VoidCallback onClose;
  final GenColors c;

  const _LibraryPicker({
    required this.docs,
    required this.loading,
    required this.selected,
    required this.onToggle,
    required this.onAttach,
    required this.onClose,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Thư viện tài liệu',
                style: TextStyle(
                    color: c.text, fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close_rounded, size: 14, color: c.muted),
            ),
          ]),
          const SizedBox(height: 6),
          if (loading)
            const Center(
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: GenColors.primary, strokeWidth: 2),
              ),
            )
          else if (docs.isEmpty)
            Text('Không có tài liệu trong thư viện.',
                style: TextStyle(color: c.muted, fontSize: 11))
          else
            ...docs.map((d) {
              final sel = selected.contains(d.knowledgeDocumentId);
              return GestureDetector(
                onTap: () => onToggle(d.knowledgeDocumentId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color:        sel ? GenColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                        border:       Border.all(
                            color: sel ? GenColors.primary : c.border,
                            width: 1.5),
                      ),
                      child: sel
                          ? const Icon(Icons.check, size: 9, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(d.fileName,
                          style: TextStyle(color: c.text, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (d.alreadyAttached)
                      Text('Đã gắn',
                          style: TextStyle(color: c.muted, fontSize: 9)),
                  ]),
                ),
              );
            }),
          if (docs.isNotEmpty && selected.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAttach,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GenColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text('Gắn ${selected.length} tài liệu',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Right Panel — Settings + Save button ──────────────────────────────────────

class RightSettingsPanel extends ConsumerWidget {
  const RightSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c           = GenColors.of(context);
    final state       = ref.watch(studioGenerationProvider);
    final settings    = state.settings;
    final isSaving    = state.isSavingDraft;
    final isDone      = state.isDraftSaved;
    final isLocked    = state.sideColumnsLocked;

    return Container(
      color: c.card,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cài đặt',
              style: TextStyle(
                  color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          if (settings != null) ...[
            _SettingRow(
              label: 'Số câu hỏi',
              value: '${settings.numberOfQuestions}',
              c:     c,
            ),
            _SettingRow(
              label: 'Độ khó',
              value: settings.difficulty.name,
              c:     c,
            ),
            _SettingRow(
              label: 'Phỏng vấn',
              value: '${settings.interviewLengthMinutes} phút',
              c:     c,
            ),
          ] else
            Text('Chưa có cài đặt.',
                style: TextStyle(color: c.muted, fontSize: 12)),

          // Apply settings button (only when plan not approved)
          if (!state.isPlanApproved && settings != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (isLocked || state.isApplyingSettings)
                    ? null
                    : () => ref.read(studioGenerationProvider.notifier).applySettings(),
                icon: state.isApplyingSettings
                    ? const SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync_rounded, size: 14),
                label: Text(
                  state.isApplyingSettings ? 'Đang áp dụng...' : 'Áp cài đặt',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: GenColors.primary,
                  side: const BorderSide(color: GenColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],

          if (state.isPlanApproved) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.lock_rounded,
                    size: 12, color: Color(0xFF10B981)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Kế hoạch đã duyệt — không thể thay đổi cài đặt.',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 11),
                  ),
                ),
              ]),
            ),
          ],

          const Divider(height: 24),

          // Save draft button (spec §7.9)
          _SaveDraftButton(isSaving: isSaving, isDone: isDone, c: c),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final GenColors c;
  const _SettingRow({required this.label, required this.value, required this.c});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Text('$label: ',
          style: TextStyle(color: c.muted, fontSize: 11)),
      Expanded(
        child: Text(value,
            style: TextStyle(
                color: c.text, fontSize: 11, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
      ),
    ]),
  );
}

class _SaveDraftButton extends ConsumerWidget {
  final bool isSaving;
  final bool isDone;
  final GenColors c;
  const _SaveDraftButton({
      required this.isSaving, required this.isDone, required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final IconData icon;
    final String label;
    final Color color;

    if (isSaving) {
      icon  = Icons.hourglass_top_rounded;
      label = 'Đang lưu…';
      color = c.muted;
    } else if (isDone) {
      icon  = Icons.check_circle_rounded;
      label = 'Đã lưu';
      color = const Color(0xFF10B981);
    } else {
      icon  = Icons.save_outlined;
      label = 'Lưu';
      color = GenColors.primary;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (isSaving || isDone)
            ? null
            : () => ref.read(studioGenerationProvider.notifier).saveDraft(),
        icon: isSaving
            ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Icon(icon, size: 14),
        label: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor:         color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          foregroundColor:         Colors.white,
          padding:                 const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ── Plan Review Mobile View (with chat at bottom) ──────────────────────────────

class StudioPlanReviewMobileView extends ConsumerStatefulWidget {
  final TextEditingController chatCtrl;
  const StudioPlanReviewMobileView({super.key, required this.chatCtrl});

  @override
  ConsumerState<StudioPlanReviewMobileView> createState() =>
      _StudioPlanReviewMobileViewState();
}

class _StudioPlanReviewMobileViewState
    extends ConsumerState<StudioPlanReviewMobileView> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c         = GenColors.of(context);
    final state     = ref.watch(studioGenerationProvider);
    final plan      = state.plan;
    final messages  = state.chatMessages;
    final isLocked  = state.isPlanApproved;
    final isStream  = state.isStreaming;

    // Scroll to bottom when messages change
    if (messages.isNotEmpty) _scrollToBottom();

    return Column(
      children: [
        // Main content: plan review + chat
        Expanded(
          child: ListView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            children: [
              // Plan card
              if (plan != null) _PlanCard(plan: plan, c: c)
              else if (state.isLoading)
                const Center(child: CircularProgressIndicator(
                    color: GenColors.primary))
              else
                Center(
                  child: Text('Chưa có plan.',
                      style: TextStyle(color: c.muted, fontSize: 13)),
                ),

              const SizedBox(height: 16),

              // Chat messages
              if (messages.isNotEmpty) ...[
                Text('Tinh chỉnh plan',
                    style: TextStyle(
                        color: c.text, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...messages.map((m) => _ChatBubble(msg: m, c: c)),
              ],

              if (isLocked)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        const Color(0xFF10B981).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border:       Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.lock_rounded, size: 13, color: Color(0xFF10B981)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kế hoạch đã duyệt — chat tinh chỉnh bị khoá.',
                        style: TextStyle(
                            color: Color(0xFF10B981), fontSize: 12),
                      ),
                    ),
                  ]),
                ),
            ],
          ),
        ),

        // Approve bar / chat input
        if (!isLocked) ...[
          // Chat input
          _ChatInputBar(
            ctrl:      widget.chatCtrl,
            isStream:  isStream,
            onSend:    () {
              final msg = widget.chatCtrl.text.trim();
              if (msg.isEmpty) return;
              widget.chatCtrl.clear();
              ref.read(studioGenerationProvider.notifier).sendRefinement(msg);
            },
            c:         c,
          ),
        ],

        // Approve plan button
        if (plan != null && !isLocked)
          _ApprovePlanBar(c: c),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final StudioPlanDetail plan;
  final GenColors c;
  const _PlanCard({required this.plan, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.assignment_rounded,
                size: 16, color: GenColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(plan.title,
                  style: TextStyle(
                      color: c.text, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            _PlanStatusChip(status: plan.status),
          ]),
          if (plan.title.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${plan.totalQuestions} câu  ·  ${plan.interviewLengthMinutes} phút',
                style: TextStyle(color: c.textSub, fontSize: 12, height: 1.5)),
          ],
          if (plan.sections.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...plan.sections.map((s) => _SectionTile(section: s, c: c)),
          ],
        ],
      ),
    );
  }
}

class _PlanStatusChip extends StatelessWidget {
  final String status;
  const _PlanStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status.toLowerCase()) {
      case 'approved':
        label = 'Đã duyệt'; color = const Color(0xFF10B981);
      case 'awaitingapproval':
      case 'awaiting_approval':
        label = 'Chờ duyệt'; color = const Color(0xFFF59E0B);
      case 'archived':
        label = 'Lưu trữ'; color = const Color(0xFF6B7280);
      default:
        label = 'Nháp'; color = const Color(0xFF9CA3AF);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final StudioPlanSection section;
  final GenColors c;
  const _SectionTile({required this.section, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:        c.bg,
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(section.name,
                    style: TextStyle(
                        color: c.text, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              Text('${section.numberOfQuestions} câu',
                  style: TextStyle(color: c.muted, fontSize: 10)),
            ]),
            if (section.description != null && section.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(section.description!,
                  style: TextStyle(color: c.textSub, fontSize: 11, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final StudioChatMessage msg;
  final GenColors c;
  const _ChatBubble({required this.msg, required this.c});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? GenColors.primary
              : c.card,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(12),
            topRight:    const Radius.circular(12),
            bottomLeft:  Radius.circular(isUser ? 12 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 12),
          ),
          border: isUser ? null : Border.all(color: c.border),
        ),
        child: msg.isStreaming
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(
                      color: c.text, strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('Đang xử lý...',
                    style: TextStyle(
                        color: c.muted, fontSize: 12, fontStyle: FontStyle.italic)),
              ])
            : Text(msg.content,
                style: TextStyle(
                    color: isUser ? Colors.white : c.text,
                    fontSize: 12, height: 1.5)),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isStream;
  final VoidCallback onSend;
  final GenColors c;

  const _ChatInputBar({
    required this.ctrl,
    required this.isStream,
    required this.onSend,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:  c.card,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color:        c.bg,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: c.border),
            ),
            child: TextField(
              controller: ctrl,
              enabled:    !isStream,
              minLines: 1,
              maxLines: 3,
              style: TextStyle(color: c.text, fontSize: 13),
              cursorColor: GenColors.primary,
              decoration: InputDecoration(
                hintText:       'Tinh chỉnh kế hoạch...',
                hintStyle:      TextStyle(color: c.hint, fontSize: 13),
                border:         InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => isStream ? null : onSend(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isStream ? null : onSend,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38, height: 38,
            decoration: BoxDecoration(
              color:  isStream ? c.border : GenColors.primary,
              shape:  BoxShape.circle,
            ),
            child: isStream
                ? const Center(
                    child: SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 17, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}

class _ApprovePlanBar extends ConsumerWidget {
  final GenColors c;
  const _ApprovePlanBar({required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(studioGenerationProvider.select((s) => s.isLoading));

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color:  c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () => ref.read(studioGenerationProvider.notifier)
                  .approvePlan(),
          icon: isLoading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_circle_outline_rounded, size: 17),
          label: const Text('Duyệt & Tạo câu hỏi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

// ── 4-Step indicator ──────────────────────────────────────────────────────────

class _StepIndicator4 extends StatelessWidget {
  final int currentStep; // 1–4

  const _StepIndicator4({required this.currentStep});

  static const _labels = ['Nhập JD', 'Tạo Plan', 'Duyệt Plan', 'Câu hỏi'];

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);

    return Container(
      color:   c.bg,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftStep = (i ~/ 2) + 1;
            final done     = currentStep > leftStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: done
                      ? const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF6C47FF)])
                      : null,
                  color:        done ? null : c.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final step   = (i ~/ 2) + 1;
          final done   = currentStep > step;
          final active = currentStep == step;
          return _Dot(
            step: step, label: _labels[step - 1],
            done: done, active: active, c: c,
          );
        }),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int     step;
  final String  label;
  final bool    done;
  final bool    active;
  final GenColors c;

  const _Dot({
    required this.step, required this.label,
    required this.done, required this.active, required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? const Color(0xFF10B981)
        : active
            ? GenColors.primary
            : c.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width:  active ? 28 : 22,
          height: active ? 28 : 22,
          decoration: BoxDecoration(
            color:     color,
            shape:     BoxShape.circle,
            boxShadow: active
                ? [BoxShadow(
                    color:      GenColors.primary.withValues(alpha: 0.45),
                    blurRadius: 10, spreadRadius: 1)]
                : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : Text('$step',
                    style: TextStyle(
                      color:      active ? Colors.white : c.muted,
                      fontSize:   active ? 11 : 9,
                      fontWeight: FontWeight.w700,
                    )),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              color:      active ? c.text : done ? const Color(0xFF10B981) : c.muted,
              fontSize:   9,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            )),
      ],
    );
  }
}

// ── Step 1 — JD input ─────────────────────────────────────────────────────────

class _JdInputStep extends ConsumerWidget {
  final TextEditingController jdCtrl;
  final TextEditingController noteCtrl;
  final int         numQuestions;
  final String      difficulty;
  final Set<String> questionTypes;
  final VoidCallback onSubmit;
  final VoidCallback onOpenSettings;

  const _JdInputStep({
    required this.jdCtrl,
    required this.noteCtrl,
    required this.numQuestions,
    required this.difficulty,
    required this.questionTypes,
    required this.onSubmit,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(studioGenerationProvider.select((s) => s.isLoading));
    final error     = ref.watch(studioGenerationProvider.select((s) => s.error));
    final c         = GenColors.of(context);

    final charCount = jdCtrl.text.length;
    final wordCount = jdCtrl.text.trim().isEmpty
        ? 0
        : jdCtrl.text.trim().split(RegExp(r'\s+')).length;
    final isValid = charCount >= 50;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _Label(icon: Icons.description_outlined,
                        label: 'Mô tả công việc', c: c)),
                    _UseSampleButton(ctrl: jdCtrl, c: c),
                  ],
                ),
                const SizedBox(height: 8),
                _JdArea(
                  controller: jdCtrl,
                  wordCount:  wordCount,
                  charCount:  charCount,
                  c:          c,
                ),
                const SizedBox(height: 20),

                _Label(icon: Icons.edit_note_rounded,
                    label: 'Ghi chú cho AI', optional: true, c: c),
                const SizedBox(height: 8),
                _NoteArea(controller: noteCtrl, c: c),
                const SizedBox(height: 16),

                _PrefsSummary(
                  numQuestions:  numQuestions,
                  difficulty:    difficulty,
                  questionTypes: questionTypes,
                  onTap:         onOpenSettings,
                  c:             c,
                ),

                if (!isValid && charCount > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Nhập ít nhất 50 ký tự để tiếp tục (còn thiếu ${50 - charCount} ký tự).',
                    style: TextStyle(color: c.muted, fontSize: 12),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 10),
                  _ErrorCard(message: error),
                ],
              ],
            ),
          ),
        ),
        _SubmitBar(isLoading: isLoading, enabled: isValid, onTap: onSubmit, c: c),
      ],
    );
  }
}

// ── Sub-widgets for step 1 ────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final bool      optional;
  final GenColors c;

  const _Label({
    required this.icon,
    required this.label,
    this.optional = false,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        color:        GenColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: GenColors.primary, size: 13),
    ),
    const SizedBox(width: 8),
    Text(label,
        style: TextStyle(
            color: c.text, fontSize: 14, fontWeight: FontWeight.w600)),
    if (optional) ...[
      const SizedBox(width: 6),
      Text('(tùy chọn)',
          style: TextStyle(color: c.muted, fontSize: 12)),
    ],
  ]);
}

class _UseSampleButton extends StatelessWidget {
  final TextEditingController ctrl;
  final GenColors c;

  const _UseSampleButton({required this.ctrl, required this.c});

  static const _sample =
      'Chúng tôi đang tìm kiếm một Fullstack Developer có 1–3 năm kinh nghiệm. '
      'Trách nhiệm: Xây dựng RESTful API bằng ASP.NET Core hoặc Node.js, '
      'phát triển giao diện React.js/Next.js, thiết kế database PostgreSQL/MySQL, '
      'tích hợp xác thực JWT, phối hợp với QA và Product Team. '
      'Yêu cầu: Kinh nghiệm C#/Node.js, thành thạo React.js & TypeScript, '
      'hiểu REST API, JWT, database design, Git, Docker.';

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      ctrl.text = _sample;
      ctrl.selection = TextSelection.collapsed(offset: _sample.length);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        GenColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GenColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.article_outlined, size: 12, color: GenColors.primary),
          SizedBox(width: 4),
          Text('Dùng mẫu',
              style: TextStyle(
                  color:      GenColors.primary,
                  fontSize:   11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

class _JdArea extends StatefulWidget {
  final TextEditingController controller;
  final int     wordCount;
  final int     charCount;
  final GenColors c;

  const _JdArea({
    required this.controller,
    required this.wordCount,
    required this.charCount,
    required this.c,
  });

  @override
  State<_JdArea> createState() => _JdAreaState();
}

class _JdAreaState extends State<_JdArea> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused ? widget.c.borderFoc : widget.c.border;

    return AnimatedContainer(
      duration:    const Duration(milliseconds: 200),
      decoration:  BoxDecoration(
        color:        widget.c.card,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: borderColor, width: _focused ? 1.5 : 1),
        boxShadow:    _focused
            ? [BoxShadow(
                color:      GenColors.primary.withValues(alpha: 0.12),
                blurRadius: 8)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Focus(
            onFocusChange: (v) => setState(() => _focused = v),
            child: TextField(
              controller: widget.controller,
              minLines:   9,
              maxLines:   18,
              style: TextStyle(
                  color: widget.c.text, fontSize: 13, height: 1.65),
              cursorColor: GenColors.primary,
              decoration: InputDecoration(
                hintText: 'Dán mô tả công việc vào đây...\n\n'
                    'Ví dụ: Chúng tôi đang tìm kiếm một Frontend Developer '
                    'Senior với hơn 5 năm kinh nghiệm React...',
                hintStyle:      TextStyle(color: widget.c.hint, fontSize: 13, height: 1.65),
                filled:         true,
                fillColor:      widget.c.card,
                border:         InputBorder.none,
                enabledBorder:  InputBorder.none,
                focusedBorder:  InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: widget.c.border)),
            ),
            child: Row(children: [
              Text(
                '${widget.wordCount} từ  ·  ${widget.charCount} ký tự',
                style: TextStyle(color: widget.c.muted, fontSize: 11),
              ),
              const Spacer(),
              if (widget.charCount >= 50)
                const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF10B981), size: 13),
                  SizedBox(width: 4),
                  Text('Đủ độ dài',
                      style: TextStyle(
                          color:      Color(0xFF10B981),
                          fontSize:   11,
                          fontWeight: FontWeight.w500)),
                ])
              else if (widget.charCount > 0)
                Text(
                  'Cần thêm ${50 - widget.charCount} ký tự',
                  style: const TextStyle(
                      color: Color(0xFFF59E0B), fontSize: 11),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _NoteArea extends StatefulWidget {
  final TextEditingController controller;
  final GenColors c;

  const _NoteArea({required this.controller, required this.c});

  @override
  State<_NoteArea> createState() => _NoteAreaState();
}

class _NoteAreaState extends State<_NoteArea> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused ? widget.c.borderFoc : widget.c.border;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:        widget.c.card,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: borderColor, width: _focused ? 1.5 : 1),
          boxShadow:    _focused
              ? [BoxShadow(
                  color:      GenColors.primary.withValues(alpha: 0.12),
                  blurRadius: 8)]
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          minLines:   3,
          maxLines:   6,
          style: TextStyle(
              color: widget.c.text, fontSize: 13, height: 1.65),
          cursorColor: GenColors.primary,
          decoration: InputDecoration(
            hintText: 'VD: Tập trung vào System Design, phỏng vấn bằng tiếng Anh, ưu tiên câu hỏi thực tế...',
            hintStyle:      TextStyle(color: widget.c.hint, fontSize: 12),
            filled:         true,
            fillColor:      widget.c.card,
            border:         InputBorder.none,
            enabledBorder:  InputBorder.none,
            focusedBorder:  InputBorder.none,
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ),
    );
  }
}

class _PrefsSummary extends StatelessWidget {
  final int         numQuestions;
  final String      difficulty;
  final Set<String> questionTypes;
  final VoidCallback onTap;
  final GenColors   c;

  const _PrefsSummary({
    required this.numQuestions,
    required this.difficulty,
    required this.questionTypes,
    required this.onTap,
    required this.c,
  });

  String get _diffLabel {
    switch (difficulty) {
      case 'easy':   return 'Dễ';
      case 'hard':   return 'Khó';
      default:       return 'Trung bình';
    }
  }

  String get _typesLabel {
    final map = {
      'technical':     'Kỹ thuật',
      'behavioral':    'Hành vi',
      'system_design': 'System Design',
    };
    return questionTypes.map((t) => map[t] ?? t).join(', ');
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color:        GenColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(
            color: GenColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.tune_rounded, size: 15, color: GenColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$numQuestions câu  ·  $_diffLabel  ·  $_typesLabel',
            style: TextStyle(color: c.textSub, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(Icons.chevron_right_rounded, size: 16, color: c.muted),
      ]),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding:    const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:        const Color(0xFFEF4444).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded,
            color: Color(0xFFEF4444), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: const TextStyle(
                  color: Color(0xFFEF4444), fontSize: 12, height: 1.4)),
        ),
      ],
    ),
  );
}

class _SubmitBar extends StatelessWidget {
  final bool         isLoading;
  final bool         enabled;
  final VoidCallback onTap;
  final GenColors    c;

  const _SubmitBar({
    required this.isLoading,
    required this.enabled,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color:  c.bg,
      border: Border(top: BorderSide(color: c.border)),
    ),
    padding: EdgeInsets.fromLTRB(
        16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
    child: SizedBox(
      width:  double.infinity,
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6C47FF)],
                  begin:  Alignment.centerLeft,
                  end:    Alignment.centerRight,
                )
              : null,
          color:        enabled ? null : c.border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed:  (isLoading || !enabled) ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor:         Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor:             Colors.transparent,
            foregroundColor:         Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width:  22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 18, color: enabled ? Colors.white : c.muted),
                    const SizedBox(width: 8),
                    Text('Tạo Plan',
                        style: TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w700,
                          color: enabled ? Colors.white : c.muted,
                        )),
                  ],
                ),
        ),
      ),
    ),
  );
}

// ── Settings bottom sheet ─────────────────────────────────────────────────────

typedef _SettingsSaveCallback = void Function(
    int numQuestions, String difficulty, Set<String> types);

class _SettingsSheet extends StatefulWidget {
  final int         numQuestions;
  final String      difficulty;
  final Set<String> questionTypes;
  final _SettingsSaveCallback onSave;

  const _SettingsSheet({
    required this.numQuestions,
    required this.difficulty,
    required this.questionTypes,
    required this.onSave,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late int    _num;
  late String _diff;
  late final Set<String> _types;
  late final TextEditingController _numCtrl;

  static const _difficulties = [
    ('easy',   'Dễ'),
    ('medium', 'Trung bình'),
    ('hard',   'Khó'),
  ];

  static const _typeOptions = [
    ('technical',     'Kỹ thuật'),
    ('behavioral',    'Hành vi'),
    ('system_design', 'System Design'),
  ];

  @override
  void initState() {
    super.initState();
    _num   = widget.numQuestions;
    _diff  = widget.difficulty;
    _types = Set.of(widget.questionTypes);
    _numCtrl = TextEditingController(text: _num.toString());
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(_num, _diff, _types);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = GenColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color:        c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color:        c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.tune_rounded,
                color: GenColors.primary, size: 18),
            const SizedBox(width: 8),
            Text('Tùy chọn đầu ra',
                style: TextStyle(
                    color:      c.text,
                    fontSize:   16,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),

          Text('Số câu hỏi (1–50)',
              style: TextStyle(
                  color:      c.text,
                  fontSize:   13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: [
            _CounterBtn(
              icon: Icons.remove,
              onTap: () {
                if (_num > 1) setState(() { _num--; _numCtrl.text = '$_num'; });
              },
              c: c,
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 70,
              child: TextField(
                controller:   _numCtrl,
                keyboardType: TextInputType.number,
                textAlign:    TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _RangeFormatter(1, 50),
                ],
                style: TextStyle(
                    color:      c.text,
                    fontSize:   18,
                    fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  filled:    true,
                  fillColor: c.bg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:   BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:   BorderSide(color: c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: GenColors.primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n >= 1 && n <= 50) setState(() => _num = n);
                },
              ),
            ),
            const SizedBox(width: 12),
            _CounterBtn(
              icon: Icons.add,
              onTap: () {
                if (_num < 50) setState(() { _num++; _numCtrl.text = '$_num'; });
              },
              c: c,
            ),
          ]),
          const SizedBox(height: 20),

          Text('Độ khó',
              style: TextStyle(
                  color:      c.text,
                  fontSize:   13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _difficulties.map((rec) {
              final value = rec.$1;
              final label = rec.$2;
              final sel = _diff == value;
              return GestureDetector(
                onTap: () => setState(() => _diff = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:        sel ? GenColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border:       Border.all(
                        color: sel ? GenColors.primary : c.border,
                        width: 1.5),
                  ),
                  child: Text(label,
                      style: TextStyle(
                        color:      sel ? Colors.white : c.textSub,
                        fontSize:   13,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Text('Loại câu hỏi',
              style: TextStyle(
                  color:      c.text,
                  fontSize:   13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _typeOptions.map((rec) {
              final value = rec.$1;
              final label = rec.$2;
              final sel = _types.contains(value);
              return GestureDetector(
                onTap: () => setState(() {
                  if (sel) {
                    if (_types.length > 1) _types.remove(value);
                  } else {
                    _types.add(value);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color:        sel ? GenColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border:       Border.all(
                        color: sel ? GenColors.primary : c.border,
                        width: 1.5),
                  ),
                  child: Text(label,
                      style: TextStyle(
                        color:      sel ? Colors.white : c.textSub,
                        fontSize:   13,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width:  double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: GenColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Lưu',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  final GenColors    c;

  const _CounterBtn({
    required this.icon,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color:        c.bg,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: c.border),
      ),
      child: Icon(icon, size: 18, color: c.textSub),
    ),
  );
}

// ── Range input formatter ─────────────────────────────────────────────────────

// ── Cooldown / quota dialog ───────────────────────────────────────────────────

class _CooldownDialog extends StatelessWidget {
  final String? message;
  const _CooldownDialog({this.message});

  @override
  Widget build(BuildContext context) {
    final c       = GenColors.of(context);
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final msg     = message ??
        'Bạn đã đạt giới hạn tạo câu hỏi. Vui lòng thử lại sau hoặc nâng cấp gói dịch vụ.';

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time_rounded,
                  color: Color(0xFF111827), size: 36),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Giới hạn tạo câu hỏi',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color:      c.text,
                  fontSize:   18,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            // Message from backend
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSub, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Upgrade button
            SizedBox(
              width:  double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/hr/settings?tab=billing');
                },
                icon:  const Icon(Icons.workspace_premium_rounded, size: 18),
                label: const Text('Đi tới gói dịch vụ',
                    style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GenColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Dismiss button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng',
                  style: TextStyle(
                      color: c.muted, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Range formatter ───────────────────────────────────────────────────────────

class _RangeFormatter extends TextInputFormatter {
  final int min;
  final int max;
  _RangeFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    if (newVal.text.isEmpty) return newVal;
    final n = int.tryParse(newVal.text);
    if (n == null) return old;
    if (n > max) {
      final s = max.toString();
      return newVal.copyWith(
          text:      s,
          selection: TextSelection.collapsed(offset: s.length));
    }
    return newVal;
  }
}
