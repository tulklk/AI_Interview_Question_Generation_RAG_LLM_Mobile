import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/widgets/app_animated_bottom_nav.dart';
import '../../../core/widgets/grid_background.dart';
import '../../../core/widgets/welcome_toast.dart';
import '../../../data/providers/app_providers.dart';

class CandidateShell extends ConsumerStatefulWidget {
  final Widget child;
  const CandidateShell({super.key, required this.child});

  @override
  ConsumerState<CandidateShell> createState() => _CandidateShellState();
}

class _CandidateShellState extends ConsumerState<CandidateShell> {
  static const _tabs = [
    '/candidate',
    '/candidate/jobs',
    '/candidate/practice',
    '/candidate/applications',
    '/candidate/profile',
  ];

  static const _navItems = [
    NavItem(
      icon: PhosphorIconsRegular.house,
      activeIcon: PhosphorIconsBold.house,
      label: 'Home',
    ),
    NavItem(
      icon: PhosphorIconsRegular.briefcase,
      activeIcon: PhosphorIconsBold.briefcase,
      label: 'Jobs',
    ),
    NavItem(
      icon: PhosphorIconsRegular.robot,
      activeIcon: PhosphorIconsBold.robot,
      label: 'Practice',
    ),
    NavItem(
      icon: PhosphorIconsRegular.clipboardText,
      activeIcon: PhosphorIconsBold.clipboardText,
      label: 'Applied',
    ),
    NavItem(
      icon: PhosphorIconsRegular.user,
      activeIcon: PhosphorIconsBold.user,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.showWelcome && auth.user != null) {
        ref.read(authProvider.notifier).consumeWelcome();
        showWelcomeToast(context, auth.user!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i])) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(
          Theme.of(context).brightness == Brightness.dark),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: GridBackground()),
          Positioned.fill(child: widget.child),
        ],
      ),
      bottomNavigationBar: _NavSlide(
        visible: ref.watch(navBarVisibleProvider),
        child: AppAnimatedBottomNav(
          currentIndex: currentIndex,
          items: _navItems,
          onTap: (i) => context.go(_tabs[i]),
        ),
      ),
    );
  }
}

// ── Reusable nav-bar slide/fade wrapper ───────────────────────────────────────

/// Slides the nav bar downward and fades it out when [visible] is false.
/// The layout space is preserved so the page body does not reflow, but
/// [IgnorePointer] prevents stray taps on the invisible bar.
class _NavSlide extends StatelessWidget {
  final bool   visible;
  final Widget child;
  const _NavSlide({required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset:   visible ? Offset.zero : const Offset(0, 1.5),
        duration: const Duration(milliseconds: 300),
        curve:    visible ? Curves.easeOutCubic : Curves.easeInCubic,
        child: AnimatedOpacity(
          opacity:  visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: child,
        ),
      ),
    );
  }
}
