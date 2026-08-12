import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/ui_providers.dart';
import '../../../core/widgets/grid_background.dart';
import '../../../core/widgets/hiregen_brand_mark.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/providers/app_providers.dart';
import '../providers/jobseeker_providers.dart';
import '../providers/candidate_subscription_provider.dart';
import '../../../core/theme/app_colors.dart';

// ── Liquid glass nav constants ────────────────────────────────────────────────

const double _kGlassBarHeight     = 60.0;  // pill height
const double _kGlassBarMarginH    = 18.0;  // left/right margin
const double _kGlassBarMarginBot  = 12.0;  // space below pill (above safe area)
const double _kGlassBarTopPad     = 4.0;   // gap between button bottom & pill top
const double _kCenterBtnSize      = 56.0;  // practice button diameter
const double _kCenterBtnAbovePill = 22.0;  // button top-of-widget; centre lands ~2 px inside pill top
const double _kNotchRadius        = _kCenterBtnSize / 2 + 10; // 38 — arc cut from pill top

/// Extra bottom padding injected into MediaQuery for child screens.
const double _kNavExtraPad =
    _kCenterBtnAbovePill + _kGlassBarTopPad + _kGlassBarHeight + _kGlassBarMarginBot;

// ── Nav item data ─────────────────────────────────────────────────────────────

class _NavEntry {
  final IconData icon;
  final String Function(AppLocalizations) label;
  final String route;

  const _NavEntry({
    required this.icon,
    required this.label,
    required this.route,
  });
}

// ── Shell ─────────────────────────────────────────────────────────────────────

class JobseekerShell extends ConsumerStatefulWidget {
  final Widget child;
  /// Current matched location, passed explicitly from the router builder so
  /// the shell always has the child route's real path (not the shell prefix).
  final String location;

  const JobseekerShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  ConsumerState<JobseekerShell> createState() => _JobseekerShellState();
}

class _JobseekerShellState extends ConsumerState<JobseekerShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ── Slide-transition tracking ──────────────────────────────────────────────
  int  _navIdx         = 0;
  bool _slideFromRight = false;

  // ── Nav bar scroll-hide animation ─────────────────────────────────────────
  late final AnimationController _navScaleCtrl;
  late final Animation<double>   _navScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navScaleCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 260),
    );
    // begin=1.0 (full size), end=0.72 (shrunk when scrolling down)
    _navScale = Tween<double>(begin: 1.0, end: 0.72).animate(
      CurvedAnimation(parent: _navScaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navScaleCtrl.dispose();
    super.dispose();
  }

  // ── App lifecycle ─────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(candidateSubscriptionProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back from background — refresh immediately then restart poll
        notifier.refresh();
        notifier.resumePolling();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App going to background — pause poll to save battery
        notifier.pausePolling();
    }
  }

  // ── Scroll listener ────────────────────────────────────────────────────────
  bool _onScroll(ScrollNotification n) {
    if (n is ScrollUpdateNotification) {
      final delta = n.scrollDelta ?? 0;
      if (delta > 2.0) {
        // User scrolled down → shrink nav bar
        _navScaleCtrl.forward();
      } else if (delta < -2.0) {
        // User scrolled up → restore nav bar
        _navScaleCtrl.reverse();
      }
    }
    // Also restore when the user lifts their finger and the list settles
    if (n is ScrollEndNotification) {
      if (n.metrics.pixels <= 0) {
        _navScaleCtrl.reverse();
      }
    }
    return false; // don't absorb — let child scrollables keep working
  }

  /// Map a route location to a nav index (used to determine slide direction).
  static int _navIdxFromLoc(String loc) {
    if (loc.startsWith('/jobseeker/dashboard'))   { return 0; }
    if (loc == '/jobseeker' ||
        loc.startsWith('/jobseeker/jobs') ||
        loc.startsWith('/jobseeker/practice'))    { return 1; }
    if (loc.startsWith('/jobseeker/history'))     { return 2; }
    if (loc.startsWith('/jobseeker/invitations')) { return 3; }
    return 1;
  }

  @override
  void didUpdateWidget(JobseekerShell old) {
    super.didUpdateWidget(old);
    // Detect tab changes using the location prop that the router passes explicitly.
    // Using GoRouterState.of(context) inside the shell returns the shell's own
    // static state (not the child route's changing path), so we rely on the prop.
    if (widget.location != old.location) {
      final newIdx = _navIdxFromLoc(widget.location);
      _slideFromRight = newIdx > _navIdx;
      _navIdx         = newIdx;
      // Restore full-size nav bar when switching tabs
      _navScaleCtrl.reverse();
    }
  }

  // ── Nav bar with scroll-scale + sheet-slide animations ───────────────────
  Widget _buildNavBar(String location, Map<String, String> badges, bool isDark) {
    final hidden = ref.watch(navBarHiddenProvider);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: hidden ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 320),
      curve: hidden ? Curves.easeIn : Curves.easeOutCubic,
      child: _LiquidGlassNavBar(
        currentLocation: location,
        badges:          badges,
        isDark:          isDark,
      ),
      builder: (ctx, slideT, navBar) => Transform.translate(
        // Slide down by full nav-bar height when a sheet is open
        offset: Offset(0, slideT * (_kNavExtraPad + MediaQuery.of(ctx).padding.bottom + 16)),
        child: AnimatedBuilder(
          animation: _navScale,
          child: navBar,
          builder: (_, child) => Transform.scale(
            scale:     _navScale.value,
            alignment: Alignment.bottomCenter,
            child:     child,
          ),
        ),
      ),
    );
  }

  // ── Nav entries (drawer / tablet rail) ────────────────────────────────────
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
      icon: Icons.bookmark_rounded,
      label: (l) => l.navSaved,
      route: '/jobseeker/saved',
    ),
    _NavEntry(
      icon: Icons.mail_rounded,
      label: (l) => l.navInvitations,
      route: '/jobseeker/invitations',
      // badge set dynamically via pendingInvitationsCountProvider
    ),
    _NavEntry(
      icon: Icons.history_rounded,
      label: (l) => l.practiceHistory,
      route: '/jobseeker/history',
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
    final location = widget.location; // real child-route path from router builder
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 840;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final pendingInvites = ref.watch(pendingInvitationsCountProvider);
    // Dynamic badges: route → badge label
    final badges = <String, String>{
      if (pendingInvites > 0) '/jobseeker/invitations': '$pendingInvites',
    };

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

    // Subscription state listener — handles both directions:
    //   Free → Premium : show celebration dialog (one-time per upgrade cycle)
    //   Premium → Free : clear celebration key + show downgrade notification
    ref.listen<CandidateSubscriptionState>(candidateSubscriptionProvider,
        (prev, next) {
      // Only act on fully-loaded transitions (never while still loading)
      if (next.isLoading) return;

      final wasPremium    = prev?.isPremium ?? false;
      final wasNotPremium = !wasPremium;

      if (wasNotPremium && next.isPremium) {
        // ── Upgrade: Free → Premium ────────────────────────────────────────
        final userId = ref.read(authProvider).user?.id ?? '';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ref
                .read(candidateSubscriptionProvider.notifier)
                .maybeShowCelebration(context, userId: userId);
          }
        });
      } else if (wasPremium && !next.isPremium) {
        // ── Downgrade: Premium → Free ──────────────────────────────────────
        // Clear the celebration key so the dialog shows again on next upgrade.
        final userId = ref.read(authProvider).user?.id ?? '';
        ref.read(candidateSubscriptionProvider.notifier)
            .clearCelebrationKey(userId);
        // Show downgrade notification dialog (animated).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            _showShellAnimatedDialog(
              context: context,
              barrierDismissible: true,
              child: const _PlanDowngradeDialog(),
            );
          }
        });
      }
    });

    if (isTablet) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg(isDark),
        body: Row(
          children: [
            _NavigationRail(
              navEntries: _navEntries,
              badges: badges,
              currentLocation: location,
              isActive: _isActive,
              l10n: l10n,
              isDark: isDark,
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(child: GridBackground()),
                  Positioned.fill(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(isDark),
      extendBody: true,
      appBar: _JobseekerAppBar(),
      drawer: _JobseekerDrawer(
        navEntries: _navEntries,
        badges: badges,
        currentLocation: location,
        isActive: _isActive,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: MediaQuery(
        // Push content up so it's not hidden behind the glass nav bar
        data: MediaQuery.of(context).copyWith(
          padding: MediaQuery.of(context).padding.copyWith(
            bottom: MediaQuery.of(context).padding.bottom + _kNavExtraPad,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: GridBackground()),
            // Slide transition between top-level nav destinations.
            // Pure SlideTransition (no fade) keeps the effect clearly visible.
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final dir = _slideFromRight ? 1.0 : -1.0;
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(dir, 0),
                      end:   Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve:  Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(location),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),   // closes MediaQuery
      ),   // closes NotificationListener
      bottomNavigationBar: _NavSlide(
        visible: ref.watch(navBarVisibleProvider),
        child: _buildNavBar(location, badges, isDark),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: isDark
                ? const Color(0xFF0B1020).withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.72),
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
          icon: Icon(
            Icons.menu_rounded,
            color: AppColors.textPrimary(isDark),
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: const HireGenBrandMark(
        tagline: '',
        titleSize: 18,
        showIcon: false,
        forceLightText: false,
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
            child: UserAvatar(
              name: user?.name ?? 'User',
              imageUrl: user?.avatarUrl,
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
  final Map<String, String> badges;
  final String currentLocation;
  final bool Function(String, String) isActive;

  const _JobseekerDrawer({
    required this.navEntries,
    required this.badges,
    required this.currentLocation,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final l10n      = context.l10n;
    final user      = ref.watch(authProvider).user;
    final bg        = AppColors.appBarBg(isDark);
    final isPremium = ref.watch(candidateSubscriptionProvider).isPremium;

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
            child: const HireGenBrandMark(
              tagline: 'AI-Powered Interview Practice',
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
                      badge: badges[entry.route],
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
                      ? AppColors.darkChip
                      : AppColors.gray200,
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
                    UserAvatar(
                      name: user?.name ?? 'User',
                      imageUrl: user?.avatarUrl,
                      size: 40,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Candidate',
                            style: TextStyle(
                              color: AppColors.textPrimary(isDark),
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
                    // Plan badge — updates live when subscription changes
                    _PlanBadge(isPremium: isPremium),
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
                            : AppColors.gray200,
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
  final Map<String, String> badges;
  final String currentLocation;
  final bool Function(String, String) isActive;
  final AppLocalizations l10n;
  final bool isDark;

  const _NavigationRail({
    required this.navEntries,
    required this.badges,
    required this.currentLocation,
    required this.isActive,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = AppColors.appBarBg(isDark);
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
            child: const HireGenBrandMark(
              tagline: 'AI-Powered Interview Practice',
              iconSize: 32,
              titleSize: 16,
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
                      badge: badges[entry.route],
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
                      ? AppColors.darkChip
                      : AppColors.gray200,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UserAvatar(
                  name: user?.name ?? 'User',
                  imageUrl: user?.avatarUrl,
                  size: 32,
                ),
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

// ── Plan badge (drawer footer) ────────────────────────────────────────────────

class _PlanBadge extends StatelessWidget {
  final bool isPremium;
  const _PlanBadge({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final color  = isPremium ? const Color(0xFF7C5CFC) : const Color(0xFF06B6D4);
    final label  = isPremium ? 'Premium' : 'Free';
    final icon   = isPremium ? Icons.workspace_premium_rounded : null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(isPremium),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(5),
          border:       Border.all(color: color.withValues(alpha: 0.40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 9, color: color),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
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

// ── Liquid Glass Nav Bar ──────────────────────────────────────────────────────

class _LiquidGlassNavBar extends StatelessWidget {
  final String             currentLocation;
  final Map<String, String> badges;
  final bool               isDark;

  const _LiquidGlassNavBar({
    required this.currentLocation,
    required this.badges,
    required this.isDark,
  });

  bool _active(String route) {
    if (route == '/jobseeker') return currentLocation == '/jobseeker';
    return currentLocation.startsWith(route);
  }

  bool get _browseActive =>
      currentLocation == '/jobseeker' ||
      currentLocation.startsWith('/jobseeker/jobs') ||
      currentLocation.startsWith('/jobseeker/practice');

  // 0=Dashboard, 1=Browse, 2=History, 3=Invitations
  int get _activeIndex {
    if (currentLocation.startsWith('/jobseeker/dashboard'))   return 0;
    if (currentLocation == '/jobseeker' ||
        currentLocation.startsWith('/jobseeker/jobs') ||
        currentLocation.startsWith('/jobseeker/practice'))    return 1;
    if (currentLocation.startsWith('/jobseeker/history'))     return 2;
    if (currentLocation.startsWith('/jobseeker/invitations')) return 3;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n     = context.l10n;
    final safePad  = MediaQuery.of(context).padding.bottom;
    final invBadge = badges['/jobseeker/invitations'];

    // Glass pill colors
    final pillBg = isDark
        ? const Color(0xFF1A1D2E).withValues(alpha: 0.74)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.70);
    final pillBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);

    // Total height: space above pill (for floating button) + pill + margins
    final totalHeight = _kCenterBtnAbovePill +
        _kGlassBarTopPad +
        _kGlassBarHeight +
        _kGlassBarMarginBot +
        safePad;

    // Button sits at y=0; pill starts at y = _kCenterBtnAbovePill + _kGlassBarTopPad
    final pillTop = _kCenterBtnAbovePill + _kGlassBarTopPad;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Single glass pill with circular notch cut from top centre ───
          Positioned(
            left:   _kGlassBarMarginH,
            right:  _kGlassBarMarginH,
            top:    pillTop,
            bottom: _kGlassBarMarginBot + safePad,
            child: Stack(
              children: [
                // Glass blur layer — clipped to notched pill shape
                Positioned.fill(
                  child: ClipPath(
                    clipper: const _NotchedBarClipper(),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                      child: Container(color: pillBg),
                    ),
                  ),
                ),
                // Border outline traced along the notched shape
                Positioned.fill(
                  child: CustomPaint(
                    painter: _NotchedBarBorderPainter(borderColor: pillBorder),
                  ),
                ),
                // ── Sliding active indicator ──────────────────────────────
                // A single purple pill that glides between the 4 tab positions.
                // Uses TweenAnimationBuilder so the same widget instance drives
                // animation across location changes without an explicit controller.
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: _activeIndex.toDouble(),
                      end:   _activeIndex.toDouble(),
                    ),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeInOutCubic,
                    builder: (context, t, _) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          // Gap = notch diameter; each half-pill gets equal width
                          final W    = constraints.maxWidth;
                          const gap  = _kNotchRadius * 2.0;
                          final pilW = (W - gap) / 2.0;

                          // Continuous center-x for fractional index t
                          final double cx;
                          if (t <= 1.0) {
                            // Within left pill: tab0=pilW*0.25, tab1=pilW*0.75
                            cx = pilW * 0.25 + t * pilW * 0.5;
                          } else if (t >= 2.0) {
                            // Within right pill: tab2=pilW*0.25, tab3=pilW*0.75
                            cx = pilW + gap + pilW * 0.25 + (t - 2.0) * pilW * 0.5;
                          } else {
                            // Crossing gap (tab1 → tab2): linear interpolation
                            final from = pilW * 0.75;
                            final to   = pilW + gap + pilW * 0.25;
                            cx = from + (to - from) * (t - 1.0);
                          }

                          const indW   = 50.0;
                          const indH   = 38.0;
                          final indTop = (_kGlassBarHeight - indH) / 2;

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
                        },
                      );
                    },
                  ),
                ),
                // Nav items — content gap keeps items away from notch area
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(children: [
                          _GlassNavItem(
                            icon:   Icons.home_rounded,
                            label:  l10n.navDashboard,
                            active: _active('/jobseeker/dashboard'),
                            isDark: isDark,
                            onTap:  () => context.go('/jobseeker/dashboard'),
                          ),
                          _GlassNavItem(
                            icon:   Icons.menu_book_rounded,
                            label:  l10n.navPractice,
                            active: _browseActive,
                            isDark: isDark,
                            onTap:  () => context.go('/jobseeker'),
                          ),
                        ]),
                      ),
                      const SizedBox(width: _kNotchRadius * 2), // dead-zone under notch
                      Expanded(
                        child: Row(children: [
                          _GlassNavItem(
                            icon:   Icons.history_rounded,
                            label:  l10n.navHistory,
                            active: _active('/jobseeker/history'),
                            isDark: isDark,
                            onTap:  () => context.go('/jobseeker/history'),
                          ),
                          _GlassNavItem(
                            icon:      Icons.mail_rounded,
                            label:     l10n.navInvitations,
                            active:    _active('/jobseeker/invitations'),
                            isDark:    isDark,
                            onTap:     () => context.go('/jobseeker/invitations'),
                            badgeText: invBadge,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Animated practice button (floats above pill) ──────────────────
          Positioned(
            top:   0,
            left:  0,
            right: 0,
            child: Center(
              child: _AnimatedPracticeButton(
                onTap: () => context.go('/jobseeker'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass nav item (icon-only) ────────────────────────────────────────────────

class _GlassNavItem extends StatelessWidget {
  final IconData icon;
  final String   label;   // kept for semantics / tooltip only
  final bool     active;
  final bool     isDark;
  final VoidCallback onTap;
  final String?  badgeText;

  const _GlassNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.isDark,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    // Background highlight is now the shared sliding indicator drawn beneath
    // all items — this widget only renders the icon and optional badge.
    final iconColor = active
        ? Colors.white
        : (isDark ? const Color(0xFF8A94A6) : const Color(0xFF9AA3B2));

    return Expanded(
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  scale: active ? 1.0 : 0.88,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(color: iconColor),
                    child: Icon(icon,
                      size:  active ? 22 : 20,
                      color: iconColor,
                    ),
                  ),
                ),
                // Notification badge
                if (badgeText != null)
                  Positioned(
                    top:   -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color:        const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText!,
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated practice button (static body, only icon morphs) ─────────────────

class _AnimatedPracticeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedPracticeButton({required this.onTap});

  @override
  State<_AnimatedPracticeButton> createState() =>
      _AnimatedPracticeButtonState();
}

class _AnimatedPracticeButtonState extends State<_AnimatedPracticeButton> {
  static const _icons = [
    Icons.play_arrow_rounded,
    Icons.flash_on_rounded,
    Icons.auto_awesome_rounded,
    Icons.psychology_rounded,
  ];

  int    _iconIdx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Cycle through icons every 1.6 s
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (mounted) {
        setState(() => _iconIdx = (_iconIdx + 1) % _icons.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width:  _kCenterBtnSize,
        height: _kCenterBtnSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
            colors: [Color(0xFF9F7AEA), Color(0xFF5B21B6)],
          ),
          boxShadow: [
            BoxShadow(
              color:        const Color(0xFF6C47FF).withValues(alpha: 0.55),
              blurRadius:   22,
              spreadRadius: -2,
              offset:       const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            _icons[_iconIdx],
            key:   ValueKey(_iconIdx),
            color: Colors.white,
            size:  28,
          ),
        ),
      ),
    );
  }
}

// ── Notched pill clipper ──────────────────────────────────────────────────────
//
// Produces a rounded-rectangle path with a circular arc removed from its top
// centre — like a pill with a bite taken out at the top.

class _NotchedBarClipper extends CustomClipper<Path> {
  const _NotchedBarClipper();

  static const _cr = 32.0;         // pill corner radius
  static const _nr = _kNotchRadius; // arc radius

  @override
  Path getClip(Size size) {
    final outer = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(_cr),
      ));
    // Circle centred on the TOP edge at mid-width → punches a smooth arc in
    final notch = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, 0),
        radius: _nr,
      ));
    return Path.combine(PathOperation.difference, outer, notch);
  }

  @override
  bool shouldReclip(_NotchedBarClipper old) => false;
}

// ── Notched pill border painter ───────────────────────────────────────────────
//
// Strokes the same notched path so the outline faithfully follows the arc cut.

class _NotchedBarBorderPainter extends CustomPainter {
  const _NotchedBarBorderPainter({required this.borderColor});
  final Color borderColor;

  static const _cr = 32.0;
  static const _nr = _kNotchRadius;

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
    final border = Path.combine(PathOperation.difference, outer, notch);
    canvas.drawPath(
      border,
      Paint()
        ..style       = PaintingStyle.stroke
        ..color       = borderColor
        ..strokeWidth = 1.0
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_NotchedBarBorderPainter old) =>
      old.borderColor != borderColor;
}

// ── Animated dialog helper (shell-local) ─────────────────────────────────────

Future<T?> _showShellAnimatedDialog<T>({
  required BuildContext context,
  required Widget child,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, __, ___) => child,
    transitionBuilder: (_, anim, __, dialogChild) {
      final scaleCurved = CurvedAnimation(
        parent: anim,
        curve:        Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      final fadeCurved = CurvedAnimation(
        parent: anim,
        curve:        Curves.easeOut,
        reverseCurve: Curves.easeIn,
      );
      final slideCurved = CurvedAnimation(
        parent: anim,
        curve:        Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: fadeCurved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end:   Offset.zero,
          ).animate(slideCurved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(scaleCurved),
            child: dialogChild,
          ),
        ),
      );
    },
  );
}

// ── Plan downgrade dialog ─────────────────────────────────────────────────────

class _PlanDowngradeDialog extends StatelessWidget {
  const _PlanDowngradeDialog();

  static const _lostFeatures = [
    'AI Feedback chi tiết & đánh giá nâng cao',
    'Luyện tập không giới hạn câu hỏi Code',
    'Lịch sử luyện tập đầy đủ',
    'Gửi Scorecard trực tiếp cho HR',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Amber/orange header ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF92400E), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('✦', style: TextStyle(color: Color(0xAAFFFFFF), fontSize: 14)),
                    Text('✦', style: TextStyle(color: Color(0xAAFFFFFF), fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Gói Premium đã kết thúc',
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              color: isDark ? const Color(0xFF111827) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tài khoản của bạn đã được chuyển về gói Free.',
                    style: TextStyle(
                      color:      isDark ? Colors.white : const Color(0xFF111827),
                      fontSize:   15,
                      fontWeight: FontWeight.w700,
                      height:     1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Các tính năng cao cấp sau đây đã bị hạn chế:',
                    style: TextStyle(
                      color:    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 13,
                      height:   1.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Lost features list
                  ..._lostFeatures.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.remove_circle_outline_rounded,
                            size: 16, color: Color(0xFFEF4444)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(
                              color:    isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                              fontSize: 13,
                              height:   1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),

                  const SizedBox(height: 18),

                  // Primary CTA: upgrade
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/jobseeker/subscription');
                      },
                      icon: const Icon(Icons.workspace_premium_rounded,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'Gia hạn Premium ngay',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Secondary: dismiss
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Đóng',
                        style: TextStyle(
                          color:    isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
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
                color: AppColors.textPrimary(isDark),
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
