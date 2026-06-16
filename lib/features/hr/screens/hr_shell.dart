import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/widgets/app_animated_bottom_nav.dart';

class HRShell extends ConsumerWidget {
  final Widget child;
  const HRShell({super.key, required this.child});

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
