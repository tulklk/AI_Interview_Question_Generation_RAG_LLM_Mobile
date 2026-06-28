import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../gen_colors.dart';
import '../providers/generation_provider.dart';
import '../views/step1_jd_input_view.dart';
import '../views/polling_view.dart';
import '../views/plan_review_view.dart';
import '../views/question_review_view.dart';
import '../views/failed_view.dart';
import '../views/draft_saved_view.dart';
import '../widgets/step_indicator.dart';

class GenerateScreen extends ConsumerWidget {
  const GenerateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generationProvider);
    final c     = GenColors.of(context);

    if (state.isRestoring) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: GenColors.primary),
              const SizedBox(height: 16),
              Text(context.l10n.restoringSession,
                  style: TextStyle(color: c.textSub, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final currentStep = viewToStep(state.currentView, state.pollingPhase);
    final showStep    = state.currentView != 'draft_view';

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor:  c.bg,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        centerTitle:      true,
        title: Text(
          context.l10n.createAIQuestions,
          style: TextStyle(
              color:      c.text,
              fontSize:   17,
              fontWeight: FontWeight.w700),
        ),
        leading: state.currentView != 'form'
            ? IconButton(
                icon: Icon(Icons.close_rounded, color: c.muted),
                onPressed: () =>
                    ref.read(generationProvider.notifier).reset(),
              )
            : IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: c.muted),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/hr/dashboard');
                  }
                },
              ),
        bottom: showStep
            ? PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child:         StepIndicator(currentStep: currentStep),
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration:        const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity:  anim,
          child:    SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end:   Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: _buildView(state),
      ),
    );
  }

  Widget _buildView(GenerationState state) {
    switch (state.currentView) {
      case 'polling':
        return const PollingView(key: ValueKey('polling'));
      case 'plan_review':
        return const PlanReviewView(key: ValueKey('plan_review'));
      case 'question_review':
        return const QuestionReviewView(key: ValueKey('question_review'));
      case 'failed':
        return const FailedView(key: ValueKey('failed'));
      case 'draft_view':
        return const DraftSavedView(key: ValueKey('draft_view'));
      case 'form':
      default:
        return const Step1JdInputView(key: ValueKey('form'));
    }
  }
}
