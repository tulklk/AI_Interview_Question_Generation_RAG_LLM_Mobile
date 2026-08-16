import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/ui_providers.dart';
import '../../core/i18n/app_localizations.dart';
import '../../data/providers/app_providers.dart';
import '../../core/widgets/grid_background.dart';
import '../../core/widgets/hiregen_brand_mark.dart';
import '../../features/hr_generate/presentation/widgets/generation_progress_badge.dart';
import '../../features/subscription/subscription_provider.dart';

class HRAppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final String currentLocation;

  const HRAppShell({
    super.key,
    required this.currentLocation,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 840;
    final showBadge = !currentLocation.startsWith('/hr/generate');

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.showWelcome) {
        ref.read(authProvider.notifier).consumeWelcome();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _showWelcomeDialog(context, next.user?.name ?? 'HR Manager');
          }
        });
      }
    });

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A14) : const Color(0xFFF4F5FB),
      extendBody: true,
      appBar: _AppBar(location: currentLocation),
      drawer: _HRDrawer(currentLocation: currentLocation),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: GridBackground()),
          RepaintBoundary(child: navigationShell),
          if (showBadge)
            Positioned(
              bottom: isWide ? 24 : 100,
              right:  16,
              child:  const GenerationProgressBadge(),
            ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : _NavSlide(
              visible: ref.watch(navBarVisibleProvider),
              child: _HRGlassNavBar(
                currentLocation: currentLocation,
                isDark:          isDark,
                navigationShell: navigationShell,
              ),
            ),
    );
  }
}

// ── Nav-bar slide/fade wrapper ────────────────────────────────────────────────

class _NavSlide extends StatelessWidget {
  final bool   visible;
  final Widget child;
  const _NavSlide({required this.visible, required this.child});

  @override
  Widget build(BuildContext context) => IgnorePointer(
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

// ── AppBar ────────────────────────────────────────────────────────────────────

class _AppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String location;
  const _AppBar({required this.location});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  String _title(AppLocalizations l10n) {
    if (location == '/hr' || location.startsWith('/hr/dashboard'))
      return l10n.dashboard;
    if (location.startsWith('/hr/generate')) return l10n.generateQuestions;
    if (location.startsWith('/hr/history')) return l10n.history;
    if (location.startsWith('/hr/knowledge')) return l10n.knowledgeBase;
    if (location.startsWith('/hr/settings')) return l10n.settings;
    if (location.startsWith('/hr/profile')) return l10n.profile;
    if (location.startsWith('/hr/recommendations')) return l10n.recommendedCandidates;
    return l10n.appName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n   = context.l10n;
    final user   = ref.watch(authProvider).user;

    return AppBar(
      toolbarHeight: 56,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: isDark
                ? const Color(0xFF0B1020).withValues(alpha: 0.78)
                : Colors.white.withValues(alpha: 0.74),
            foregroundDecoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : const Color(0xFF6C47FF).withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: Builder(
        builder: (ctx) => IconButton(
          tooltip: 'Menu',
          icon: Icon(Icons.menu_rounded,
              color: isDark ? Colors.white : const Color(0xFF111827)),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        _title(l10n),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF111827),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        // Notifications
        Semantics(
          label: l10n.notificationsSection,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280)),
                iconSize: 22,
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6C47FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('2',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Avatar → profile
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Tooltip(
            message: l10n.profile,
            child: GestureDetector(
              onTap: () => context.go('/hr/profile'),
              child: _UserAvatar(
                name: user?.name ?? 'HR',
                avatarUrl: user?.avatarUrl,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

class _HRDrawer extends ConsumerStatefulWidget {
  final String currentLocation;
  const _HRDrawer({required this.currentLocation});

  @override
  ConsumerState<_HRDrawer> createState() => _HRDrawerState();
}

class _HRDrawerState extends ConsumerState<_HRDrawer> {

  List<_NavItem> _navItems(AppLocalizations l10n) => [
        _NavItem(
            label: l10n.dashboard,
            route: '/hr/dashboard',
            icon: Icons.dashboard_rounded,
            badge: null),
        _NavItem(
            label: l10n.generateQuestions,
            route: '/hr/generate',
            icon: Icons.auto_awesome_rounded,
            badge: 'AI'),
        _NavItem(
            label: l10n.history,
            route: '/hr/history',
            icon: Icons.history_rounded,
            badge: '7'),
        _NavItem(
            label: l10n.recommendedCandidates,
            route: '/hr/recommendations',
            icon: Icons.people_alt_rounded,
            badge: null),
        _NavItem(
            label: l10n.knowledgeBase,
            route: '/hr/knowledge',
            icon: Icons.menu_book_rounded,
            badge: null),
      ];

  bool _isActive(String route) {
    final loc = widget.currentLocation;
    if (route == '/hr/dashboard') {
      return loc == '/hr' || loc.startsWith('/hr/dashboard');
    }
    return loc.startsWith(route);
  }

  // Full-screen routes that live outside the shell navigator
  static const _fullScreenRoutes = {'/hr/generate', '/hr/manual-builder'};

  void _navigate(BuildContext ctx, String route) {
    Navigator.of(ctx).pop();
    if (_fullScreenRoutes.contains(route)) {
      context.go(route);
    } else {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final user = ref.watch(authProvider).user;
    final bg = isDark ? const Color(0xFF0B1020) : Colors.white;

    return Drawer(
      backgroundColor: bg,
      width: 280,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0533), Color(0xFF0D1B4B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const HireGenBrandMark(
              tagline: 'AI-Powered Interview Question Generator',
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section header ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      l10n.mainMenu,
                      style: TextStyle(
                          color: isDark
                              ? const Color(0xFF4A5578)
                              : const Color(0xFF9CA3AF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8),
                    ),
                  ),

                  // ── Nav items ──────────────────────────────────────────
                  ..._navItems(l10n).map((item) => _DrawerNavItem(
                        item: item,
                        active: _isActive(item.route),
                        isDark: isDark,
                        onTap: () => _navigate(context, item.route),
                      )),

                  const SizedBox(height: 16),

                  // ── Promo card ─────────────────────────────────────────
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
                          Text(l10n.quickCreate,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            l10n.quickCreateDesc,
                            style: const TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 11,
                                height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              context.go('/hr/generate');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4)),
                              ),
                              child: Text(l10n.startNow,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: isDark
                          ? const Color(0xFF1E2640)
                          : const Color(0xFFE5E7EB))),
            ),
            padding: EdgeInsets.fromLTRB(
                16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _UserAvatar(
                      name: user?.name ?? 'HR',
                      avatarUrl: user?.avatarUrl,
                      size: 40,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'HR Manager',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                                color: Color(0xFF6B7280), fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const PlanBadgeWidget(),
                  ],
                ),
                const SizedBox(height: 12),
                // Theme + Language toggles
                Row(
                  children: [
                    Expanded(
                      child: _DrawerToggleBtn(
                        icon: ref.watch(themeProvider) == ThemeMode.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        label: ref.watch(themeProvider) == ThemeMode.dark
                            ? l10n.lightTheme
                            : l10n.darkTheme,
                        isDark: isDark,
                        onTap: () =>
                            ref.read(themeProvider.notifier).toggle(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DrawerToggleBtn(
                        icon: Icons.language_rounded,
                        label: ref.watch(languageProvider) == 'vi'
                            ? l10n.english
                            : l10n.vietnamese,
                        isDark: isDark,
                        onTap: () =>
                            ref.read(languageProvider.notifier).toggle(),
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
                              : const Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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

class _NavItem {
  final String label;
  final String route;
  final IconData icon;
  final String? badge;
  const _NavItem({
    required this.label,
    required this.route,
    required this.icon,
    this.badge,
  });
}

class _DrawerNavItem extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.item,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF6C47FF).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(
                    color: const Color(0xFF6C47FF).withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: active
                    ? const Color(0xFF6C47FF)
                    : isDark
                        ? const Color(0xFF4A5578)
                        : const Color(0xFF9CA3AF),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: active
                        ? isDark
                            ? Colors.white
                            : const Color(0xFF111827)
                        : isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF4B5563),
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (item.badge != null) _Badge(label: item.badge!),
            ],
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  bool get _isNew => label == 'New';

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: _isNew
              ? const Color(0xFF6C47FF).withValues(alpha: 0.15)
              : const Color(0xFF374151).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: _isNew
              ? Border.all(
                  color: const Color(0xFF6C47FF).withValues(alpha: 0.4))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _isNew ? const Color(0xFF6C47FF) : const Color(0xFF9CA3AF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

// ── Drawer toggle button ──────────────────────────────────────────────────────

class _DrawerToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _DrawerToggleBtn({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E2640)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2D3562)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280)),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}

// ── Notched nav-bar layout constants ─────────────────────────────────────────

const double _kHRPillH   = 60.0;
const double _kHRMarginH = 18.0;
const double _kHRMargBot = 12.0;
const double _kHRTopPad  = 4.0;
const double _kHRFabSz   = 56.0;
const double _kHRFabAb   = 22.0;          // how far the FAB rises above the pill top
const double _kHRNotchR  = _kHRFabSz / 2 + 10; // arc radius = 38

// ── HR Glass Nav Bar (notched pill + centre FAB) ──────────────────────────────

class _HRGlassNavBar extends StatelessWidget {
  final String                  currentLocation;
  final bool                    isDark;
  final StatefulNavigationShell navigationShell;

  const _HRGlassNavBar({
    required this.currentLocation,
    required this.isDark,
    required this.navigationShell,
  });

  bool _active(String route) {
    if (route == '/hr/dashboard') {
      return currentLocation == '/hr' ||
          currentLocation.startsWith('/hr/dashboard');
    }
    return currentLocation.startsWith(route);
  }

  // 0=Dashboard 1=History 2=Knowledge 3=Profile
  int get _activeIndex {
    if (currentLocation == '/hr' ||
        currentLocation.startsWith('/hr/dashboard')) return 0;
    if (currentLocation.startsWith('/hr/history'))   return 1;
    if (currentLocation.startsWith('/hr/knowledge')) return 2;
    if (currentLocation.startsWith('/hr/profile'))   return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n    = context.l10n;
    final safePad = MediaQuery.of(context).padding.bottom;

    final pillBg = isDark
        ? const Color(0xFF1A1D2E).withValues(alpha: 0.74)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.70);
    final pillBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);

    final totalH = _kHRFabAb + _kHRTopPad + _kHRPillH + _kHRMargBot + safePad;
    final pillTop = _kHRFabAb + _kHRTopPad;

    return SizedBox(
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Notched glass pill ─────────────────────────────────────────────
          Positioned(
            left:   _kHRMarginH,
            right:  _kHRMarginH,
            top:    pillTop,
            bottom: _kHRMargBot + safePad,
            child: Stack(
              children: [
                // Blur background clipped to notched shape
                Positioned.fill(
                  child: ClipPath(
                    clipper: const _HRNotchedClipper(),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                      child: Container(color: pillBg),
                    ),
                  ),
                ),
                // Border outline traced along the same notch
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HRNotchedBorderPainter(borderColor: pillBorder),
                  ),
                ),
                // Sliding active-indicator pill (purple rect that glides)
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: _activeIndex.toDouble(),
                      end:   _activeIndex.toDouble(),
                    ),
                    duration: const Duration(milliseconds: 420),
                    curve:    Curves.easeInOutCubic,
                    builder: (ctx, t, _) {
                      return LayoutBuilder(builder: (ctx, c) {
                        final W    = c.maxWidth;
                        const gap  = _kHRNotchR * 2.0;
                        final pilW = (W - gap) / 2.0;

                        final double cx;
                        if (t <= 1.0) {
                          cx = pilW * 0.25 + t * pilW * 0.5;
                        } else if (t >= 2.0) {
                          cx = pilW + gap + pilW * 0.25 + (t - 2.0) * pilW * 0.5;
                        } else {
                          final from = pilW * 0.75;
                          final to   = pilW + gap + pilW * 0.25;
                          cx = from + (to - from) * (t - 1.0);
                        }

                        const indW   = 50.0;
                        const indH   = 38.0;
                        final indTop = (_kHRPillH - indH) / 2;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left:   cx - indW / 2,
                              top:    indTop,
                              width:  indW,
                              height: indH,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C47FF),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:      const Color(0xFF6C47FF)
                                          .withValues(alpha: 0.45),
                                      blurRadius: 12,
                                      offset:     const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      });
                    },
                  ),
                ),
                // Nav icons – 2 left, 2 right, dead-zone under notch
                Positioned.fill(
                  child: Row(children: [
                    Expanded(
                      child: Row(children: [
                        _HRGlassNavItem(
                          icon:   Icons.home_rounded,
                          label:  l10n.dashboard,
                          active: _active('/hr/dashboard'),
                          isDark: isDark,
                          onTap:  () => navigationShell.goBranch(0),
                        ),
                        _HRGlassNavItem(
                          icon:   Icons.history_rounded,
                          label:  l10n.history,
                          active: _active('/hr/history'),
                          isDark: isDark,
                          onTap:  () => navigationShell.goBranch(1),
                        ),
                      ]),
                    ),
                    const SizedBox(width: _kHRNotchR * 2), // dead-zone
                    Expanded(
                      child: Row(children: [
                        _HRGlassNavItem(
                          icon:   Icons.menu_book_rounded,
                          label:  l10n.knowledgeBase,
                          active: _active('/hr/knowledge'),
                          isDark: isDark,
                          onTap:  () => navigationShell.goBranch(2),
                        ),
                        _HRGlassNavItem(
                          icon:   Icons.account_circle_rounded,
                          label:  l10n.profile,
                          active: _active('/hr/profile'),
                          isDark: isDark,
                          onTap:  () => navigationShell.goBranch(3),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // ── Morphing Generate-Question-Set FAB ────────────────────────────
          Positioned(
            top:   0,
            left:  0,
            right: 0,
            child: Center(child: _HRMorphFab()),
          ),
        ],
      ),
    );
  }
}

// ── HR glass nav item (icon-only; active pill is a separate sliding layer) ────

class _HRGlassNavItem extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         active;
  final bool         isDark;
  final VoidCallback onTap;

  const _HRGlassNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = active
        ? Colors.white
        : (isDark ? const Color(0xFF8A94A6) : const Color(0xFF9AA3B2));

    return Expanded(
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap:    onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve:    Curves.easeOutBack,
              scale:    active ? 1.0 : 0.88,
              child: Icon(icon,
                  size:  active ? 22 : 20,
                  color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

// ── HR generate-question-set FAB ──────────────────────────────────────────────
//
// Single icon (auto_awesome) with a modern idle animation:
//   • button glow pulses softly (shadow alpha + blur)
//   • icon breathes (scale 1.0 ↔ 1.10) with a gentle pendulum rock (±2.5°)
// All driven by one ping-pong AnimationController → easeInOut curve.

class _HRMorphFab extends StatefulWidget {
  const _HRMorphFab();

  @override
  State<_HRMorphFab> createState() => _HRMorphFabState();
}

class _HRMorphFabState extends State<_HRMorphFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double>   _breathAnim; // easeInOut 0→1

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _breathAnim = CurvedAnimation(
      parent: _breathCtrl,
      curve:  Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/hr/generate'),
      child: AnimatedBuilder(
        animation: _breathAnim,
        builder: (_, __) {
          final t = _breathAnim.value; // 0→1→0 (easeInOut)

          // ── Button body (glow breathes) ──────────────────────────────────
          return Container(
            width:  _kHRFabSz,
            height: _kHRFabSz,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
                colors: [Color(0xFF9B72FF), Color(0xFF6C47FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color:        const Color(0xFF6C47FF)
                      .withValues(alpha: 0.36 + 0.24 * t),
                  blurRadius:   12 + 12 * t,
                  spreadRadius: -1,
                  offset:       const Offset(0, 5),
                ),
              ],
            ),
            // ── Icon (scale breathe + pendulum rock) ──────────────────────
            child: Center(
              child: Transform.rotate(
                // oscillates from -0.044 rad (≈−2.5°) to +0.044 rad (+2.5°)
                angle: (t - 0.5) * 0.088,
                child: Transform.scale(
                  scale: 1.0 + 0.10 * t,
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size:  26,
                    shadows: [
                      Shadow(color: Color(0x88FFFFFF), blurRadius: 14),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── HR notched-pill clipper ───────────────────────────────────────────────────

class _HRNotchedClipper extends CustomClipper<Path> {
  const _HRNotchedClipper();
  static const _cr = 32.0;
  static const _nr = _kHRNotchR;

  @override
  Path getClip(Size size) {
    final outer = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(_cr),
      ));
    final notch = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, 0),
        radius: _nr,
      ));
    return Path.combine(PathOperation.difference, outer, notch);
  }

  @override
  bool shouldReclip(_HRNotchedClipper _) => false;
}

// ── HR notched-pill border painter ───────────────────────────────────────────

class _HRNotchedBorderPainter extends CustomPainter {
  const _HRNotchedBorderPainter({required this.borderColor});
  final Color borderColor;
  static const _cr = 32.0;
  static const _nr = _kHRNotchR;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(_cr),
      ));
    final notch = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, 0),
        radius: _nr,
      ));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, notch),
      Paint()
        ..style       = PaintingStyle.stroke
        ..color       = borderColor
        ..strokeWidth = 1.0
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_HRNotchedBorderPainter old) =>
      old.borderColor != borderColor;
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;

  const _UserAvatar({required this.name, this.avatarUrl, required this.size});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'H';
  }

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: const Color(0xFF6C47FF),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C47FF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Welcome dialog ────────────────────────────────────────────────────────────

void _showWelcomeDialog(BuildContext context, String fullName) {
  final firstName = fullName.trim().split(' ').first;
  final isDark    = Theme.of(context).brightness == Brightness.dark;
  final l10n      = context.l10n;

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
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
                l10n.welcomeGreeting(firstName),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.welcomeBody,
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
                  child: Text(
                    l10n.getStarted,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
