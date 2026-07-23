import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/widgets/bottom_nav_widgets.dart';
import '../../../data/providers/app_providers.dart';

// ── Nav item data ─────────────────────────────────────────────────────────────

class _NavEntry {
  final IconData icon;
  final String Function(AppLocalizations) label;
  final String route;
  final String? badge;

  const _NavEntry({
    required this.icon,
    required this.label,
    required this.route,
    this.badge,
  });
}

// ── Shell ─────────────────────────────────────────────────────────────────────

class JobseekerShell extends ConsumerStatefulWidget {
  final Widget child;
  const JobseekerShell({super.key, required this.child});

  @override
  ConsumerState<JobseekerShell> createState() => _JobseekerShellState();
}

class _JobseekerShellState extends ConsumerState<JobseekerShell> {
  static final _navEntries = <_NavEntry>[
    _NavEntry(
      icon: Icons.dashboard_rounded,
      label: (l) => l.dashboard,
      route: '/jobseeker/dashboard',
    ),
    _NavEntry(
      icon: Icons.menu_book_rounded,
      label: (l) => l.practiceNow,
      route: '/jobseeker',
    ),
    _NavEntry(
      icon: Icons.history_rounded,
      label: (l) => l.practiceHistory,
      route: '/jobseeker/history',
      badge: '8',
    ),
    _NavEntry(
      icon: Icons.account_circle_rounded,
      label: (l) => l.myProfile,
      route: '/jobseeker/profile',
    ),
    _NavEntry(
      icon: Icons.settings_rounded,
      label: (l) => l.settings,
      route: '/jobseeker/settings',
    ),
  ];

  bool _isActive(String entryRoute, String currentLocation) {
    // Exact matches
    if (entryRoute == '/jobseeker') return currentLocation == '/jobseeker';
    if (entryRoute == '/jobseeker/settings') return currentLocation == '/jobseeker/settings';
    // StartsWith for all others
    return currentLocation.startsWith(entryRoute);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 840;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.showWelcome) {
        ref.read(authProvider.notifier).consumeWelcome();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _showWelcomeDialog(context, next.user?.name ?? 'Ứng viên');
          }
        });
      }
    });

    if (isTablet) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF070A13) : const Color(0xFFF4F5FB),
        body: Row(
          children: [
            _NavigationRail(
              navEntries: _navEntries,
              currentLocation: location,
              isActive: _isActive,
              l10n: l10n,
              isDark: isDark,
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070A13) : const Color(0xFFF4F5FB),
      appBar: _JobseekerAppBar(),
      drawer: _JobseekerDrawer(
        navEntries: _navEntries,
        currentLocation: location,
        isActive: _isActive,
      ),
      body: widget.child,
      bottomNavigationBar: _JobseekerBottomBar(
        currentLocation: location,
        isDark: isDark,
      ),
      floatingActionButton: _JobseekerCenterFab(
        currentLocation: location,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _JobseekerAppBar extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thMode = ref.watch(themeProvider);
    final lang = ref.watch(languageProvider);
    final user = ref.watch(authProvider).user;

    final iconColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return AppBar(
      toolbarHeight: 56,
      backgroundColor: isDark ? const Color(0xFF0B1020) : Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'HireGen ',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const TextSpan(
              text: 'AI',
              style: TextStyle(
                color: Color(0xFF6C47FF),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Theme toggle
        IconButton(
          icon: Icon(
            thMode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: iconColor,
            size: 22,
          ),
          onPressed: () => ref.read(themeProvider.notifier).toggle(),
          tooltip: thMode == ThemeMode.dark
              ? context.l10n.lightMode
              : context.l10n.darkMode,
        ),
        // Language switcher
        InkWell(
          onTap: () => ref.read(languageProvider.notifier).toggle(),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang == 'vi' ? 'VI' : 'EN',
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Notification bell with badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: iconColor, size: 22),
              onPressed: () {},
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C47FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // User avatar
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: GestureDetector(
            onTap: () => context.go('/jobseeker/profile'),
            child: _UserAvatarCircle(
              name: user?.name ?? 'User',
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

class _JobseekerDrawer extends ConsumerWidget {
  final List<_NavEntry> navEntries;
  final String currentLocation;
  final bool Function(String, String) isActive;

  const _JobseekerDrawer({
    required this.navEntries,
    required this.currentLocation,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final user = ref.watch(authProvider).user;
    final bg = isDark ? const Color(0xFF0B1020) : Colors.white;

    return Drawer(
      backgroundColor: bg,
      width: 288,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0533), Color(0xFF0D1B4B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C47FF), Color(0xFF8B65FF)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'HireGen ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: 'AI',
                            style: TextStyle(
                              color: Color(0xFF6C47FF),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'AI-Powered Interview Practice',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      l10n.candidateSection.toUpperCase(),
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF4A5578)
                            : const Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  // Nav items
                  ...navEntries.map((entry) {
                    final active = isActive(entry.route, currentLocation);
                    return _DrawerNavItem(
                      icon: entry.icon,
                      label: entry.label(l10n),
                      badge: entry.badge,
                      active: active,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(entry.route);
                      },
                    );
                  }),

                  const SizedBox(height: 16),

                  // Practice CTA card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C47FF), Color(0xFF8B65FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.readyToPractice,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.readyToPracticeDesc,
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              context.go('/jobseeker');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                l10n.browseSets,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── User footer ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E2640)
                      : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              14 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _UserAvatarCircle(name: user?.name ?? 'User', size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Candidate',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Free plan pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'Free',
                        style: TextStyle(
                          color: Color(0xFF06B6D4),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: Text(l10n.logout),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF2A3350)
                            : const Color(0xFFE5E7EB),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Navigation Rail (tablet) ──────────────────────────────────────────────────

class _NavigationRail extends ConsumerWidget {
  final List<_NavEntry> navEntries;
  final String currentLocation;
  final bool Function(String, String) isActive;
  final AppLocalizations l10n;
  final bool isDark;

  const _NavigationRail({
    required this.navEntries,
    required this.currentLocation,
    required this.isActive,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = isDark ? const Color(0xFF0B1020) : Colors.white;
    final thMode = ref.watch(themeProvider);
    final lang = ref.watch(languageProvider);
    final user = ref.watch(authProvider).user;

    return Container(
      width: 250,
      color: bg,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              16,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0533), Color(0xFF0D1B4B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C47FF), Color(0xFF8B65FF)],
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'HireGen ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: 'AI',
                            style: TextStyle(
                              color: Color(0xFF6C47FF),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'AI-Powered Interview Practice',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                ),
              ],
            ),
          ),

          // Section header + nav items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      l10n.candidateSection.toUpperCase(),
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF4A5578)
                            : const Color(0xFF9CA3AF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ...navEntries.map((entry) {
                    final active = isActive(entry.route, currentLocation);
                    return _DrawerNavItem(
                      icon: entry.icon,
                      label: entry.label(l10n),
                      badge: entry.badge,
                      active: active,
                      isDark: isDark,
                      onTap: () => context.go(entry.route),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Controls row
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E2640)
                      : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _UserAvatarCircle(name: user?.name ?? 'User', size: 32),
                IconButton(
                  icon: Icon(
                    thMode == ThemeMode.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    size: 20,
                  ),
                  onPressed: () => ref.read(themeProvider.notifier).toggle(),
                ),
                GestureDetector(
                  onTap: () => ref.read(languageProvider.notifier).toggle(),
                  child: Text(
                    lang == 'vi' ? 'VI' : 'EN',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  child: Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ── Drawer nav item ───────────────────────────────────────────────────────────

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF6C47FF)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active
                  ? Colors.white
                  : isDark
                      ? const Color(0xFF4A5578)
                      : const Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF4B5563),
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFF374151).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF9CA3AF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Shared user avatar ────────────────────────────────────────────────────────

class _UserAvatarCircle extends StatelessWidget {
  final String name;
  final double size;

  const _UserAvatarCircle({required this.name, required this.size});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF6C47FF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Jobseeker Bottom Navigation Bar ──────────────────────────────────────────

// ── Jobseeker Bottom Bar (BottomAppBar with notch) ───────────────────────────

class _JobseekerBottomBar extends StatelessWidget {
  final String currentLocation;
  final bool   isDark;

  const _JobseekerBottomBar({
    required this.currentLocation,
    required this.isDark,
  });

  bool _active(String route) {
    if (route == '/jobseeker') return currentLocation == '/jobseeker';
    return currentLocation.startsWith(route);
  }

  bool get _browseActive =>
      _active('/jobseeker') &&
      !currentLocation.startsWith('/jobseeker/dashboard') &&
      !currentLocation.startsWith('/jobseeker/history') &&
      !currentLocation.startsWith('/jobseeker/profile');

  @override
  Widget build(BuildContext context) {
    final l10n  = context.l10n;
    final barBg = isDark ? const Color(0xFF0B1020) : Colors.white;

    return BottomAppBar(
      color:       barBg,
      elevation:   8,
      notchMargin: 8,
      shape:       const CircularNotchedRectangle(),
      height:      64,
      padding:     EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: BNItem(
              icon:   Icons.home_rounded,
              label:  l10n.navDashboard,
              active: _active('/jobseeker/dashboard'),
              isDark: isDark,
              onTap:  () => context.go('/jobseeker/dashboard'),
            ),
          ),
          Expanded(
            child: BNItem(
              icon:   Icons.menu_book_rounded,
              label:  l10n.navPractice,
              active: _browseActive,
              isDark: isDark,
              onTap:  () => context.go('/jobseeker'),
            ),
          ),
          // Gap + label for centre FAB
          SizedBox(
            width:  72,
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    l10n.navPractice,
                    style: const TextStyle(
                      fontSize:   9,
                      color:      Color(0xFF6C47FF),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BNItem(
              icon:   Icons.history_rounded,
              label:  l10n.navHistory,
              active: _active('/jobseeker/history'),
              isDark: isDark,
              onTap:  () => context.go('/jobseeker/history'),
            ),
          ),
          Expanded(
            child: BNItem(
              icon:   Icons.account_circle_rounded,
              label:  l10n.navProfile,
              active: _active('/jobseeker/profile'),
              isDark: isDark,
              onTap:  () => context.go('/jobseeker/profile'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Jobseeker Centre FAB ─────────────────────────────────────────────────────

class _JobseekerCenterFab extends StatelessWidget {
  final String currentLocation;
  const _JobseekerCenterFab({required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed:       () => context.go('/jobseeker'),
      backgroundColor: const Color(0xFF6C47FF),
      foregroundColor: Colors.white,
      elevation:       6,
      shape:           const CircleBorder(),
      child: const Icon(Icons.play_arrow_rounded, size: 28),
    );
  }
}

// ── Welcome dialog ────────────────────────────────────────────────────────────

void _showWelcomeDialog(BuildContext context, String fullName) {
  final firstName = fullName.trim().split(' ').first;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C47FF), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C47FF).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.waving_hand_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Chào mừng, $firstName! 🎉',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã đăng nhập thành công vào HireGen AI.\nChúc bạn luyện tập hiệu quả!',
              style: TextStyle(
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C47FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text(
                  'Bắt đầu',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
