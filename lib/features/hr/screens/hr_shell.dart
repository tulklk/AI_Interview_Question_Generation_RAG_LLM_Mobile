import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/app_animated_bottom_nav.dart';
import '../../../core/widgets/welcome_toast.dart';
import '../../../data/providers/app_providers.dart';
import '../../hr_generate/presentation/widgets/generation_progress_badge.dart';

class HRShell extends ConsumerStatefulWidget {
  final Widget child;
  const HRShell({super.key, required this.child});

  @override
  ConsumerState<HRShell> createState() => _HRShellState();
}

class _HRShellState extends ConsumerState<HRShell> {
  static const _tabs = [
    '/hr',
    '/hr/jobs',
    '/hr/candidates',
    '/hr/interviews',
    '/hr/profile',
  ];

  static const _navItems = [
    NavItem(
      icon: PhosphorIconsRegular.house,
      activeIcon: PhosphorIconsBold.house,
      label: 'Dashboard',
    ),
    NavItem(
      icon: PhosphorIconsRegular.briefcase,
      activeIcon: PhosphorIconsBold.briefcase,
      label: 'Jobs',
    ),
    NavItem(
      icon: PhosphorIconsRegular.users,
      activeIcon: PhosphorIconsBold.users,
      label: 'Candidates',
    ),
    NavItem(
      icon: PhosphorIconsRegular.calendar,
      activeIcon: PhosphorIconsBold.calendar,
      label: 'Interviews',
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
    // Shell mounts AFTER showWelcome is already true, so ref.listen misses it.
    // Check the initial value here instead.
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
      body: Stack(
        children: [
          widget.child,
          const GenerationProgressBadge(),
        ],
      ),
      bottomNavigationBar: AppAnimatedBottomNav(
        currentIndex: currentIndex,
        items: _navItems,
        onTap: (i) => context.go(_tabs[i]),
      ),
    );
  }
}
