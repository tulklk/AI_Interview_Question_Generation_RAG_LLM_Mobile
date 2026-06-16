import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/app_animated_bottom_nav.dart';

class CandidateShell extends ConsumerWidget {
  final Widget child;
  const CandidateShell({super.key, required this.child});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    for (int i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i])) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: AppAnimatedBottomNav(
        currentIndex: currentIndex,
        items: _navItems,
        onTap: (i) => context.go(_tabs[i]),
      ),
    );
  }
}
