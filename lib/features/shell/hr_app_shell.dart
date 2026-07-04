import 'dart:math' show cos, pi, sin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/i18n/app_localizations.dart';
import '../../data/providers/app_providers.dart';
import '../../core/widgets/bottom_nav_widgets.dart';
import '../../features/hr_generate/presentation/widgets/generation_progress_badge.dart';

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
      appBar: _AppBar(location: currentLocation),
      drawer: _HRDrawer(currentLocation: currentLocation),
      body: Stack(
        children: [
          RepaintBoundary(child: navigationShell),
          if (showBadge)
            Positioned(
              bottom: isWide ? 24 : 88,
              right:  16,
              child:  const GenerationProgressBadge(),
            ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : _HRBottomBar(
              currentLocation: currentLocation,
              isDark:          isDark,
              navigationShell: navigationShell,
            ),
      floatingActionButton: isWide
          ? null
          : _HRCenterFab(currentLocation: currentLocation),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
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
    return l10n.appName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final lang = ref.watch(languageProvider);
    final thMode = ref.watch(themeProvider);
    final user = ref.watch(authProvider).user;

    final themeIcon = thMode == ThemeMode.dark
        ? Icons.light_mode_rounded
        : Icons.dark_mode_rounded;

    return AppBar(
      toolbarHeight: 56,
      backgroundColor: isDark ? const Color(0xFF0B1020) : Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      leading: Builder(
        builder: (ctx) => IconButton(
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
        // Theme toggle
        IconButton(
          icon: Icon(themeIcon,
              color:
                  isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
          iconSize: 22,
          onPressed: () => ref.read(themeProvider.notifier).toggle(),
          tooltip: thMode == ThemeMode.dark ? l10n.lightMode : l10n.darkMode,
        ),
        // Language switcher
        InkWell(
          onTap: () => ref.read(languageProvider.notifier).toggle(),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lang == 'vi' ? '🇻🇳' : '🇺🇸',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 2),
                Text(
                  lang == 'vi' ? 'VI' : 'EN',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Notifications
        Stack(
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
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C47FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('2',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
        // User avatar
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => context.go('/hr/profile'),
            child: _UserAvatar(
              name: user?.name ?? 'HR',
              avatarUrl: user?.avatarUrl,
              size: 32,
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
  String _plan = 'professional';

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString('hiregen-hr-plan') ?? 'professional';
    if (mounted) setState(() => _plan = v);
  }

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
            badge: 'New'),
        _NavItem(
            label: l10n.history,
            route: '/hr/history',
            icon: Icons.history_rounded,
            badge: '7'),
        _NavItem(
            label: l10n.knowledgeBase,
            route: '/hr/knowledge',
            icon: Icons.menu_book_rounded,
            badge: null),
        _NavItem(
            label: l10n.settings,
            route: '/hr/settings',
            icon: Icons.settings_rounded,
            badge: null),
      ];

  bool _isActive(String route) {
    final loc = widget.currentLocation;
    if (route == '/hr/dashboard')
      return loc == '/hr' || loc.startsWith('/hr/dashboard');
    return loc.startsWith(route);
  }

  void _navigate(BuildContext ctx, String route) {
    Navigator.of(ctx).pop();
    if (route == '/hr/generate') {
      context.go('/hr/generate');
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
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
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 20),
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
                                fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: 'AI',
                            style: TextStyle(
                                color: Color(0xFF6C47FF),
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'AI-Powered Interview Question Generator',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                ),
              ],
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
                    if (_planBadge(_plan) != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _planColor(_plan).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: _planColor(_plan).withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _planBadge(_plan)!,
                          style: TextStyle(
                              color: _planColor(_plan),
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
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

  String? _planBadge(String p) {
    switch (p) {
      case 'professional':
        return 'Pro';
      case 'business':
        return 'Biz';
      case 'enterprise':
        return 'Ent.';
      default:
        return null;
    }
  }

  Color _planColor(String p) {
    switch (p) {
      case 'professional':
        return const Color(0xFF6C47FF);
      case 'business':
        return const Color(0xFF3B82F6);
      case 'enterprise':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF9CA3AF);
    }
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

// ── HR Bottom Bar (notched BottomAppBar) ─────────────────────────────────────

class _HRBottomBar extends StatelessWidget {
  final String currentLocation;
  final bool   isDark;
  final StatefulNavigationShell navigationShell;
  const _HRBottomBar({
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
              label:  l10n.dashboard,
              active: _active('/hr/dashboard'),
              isDark: isDark,
              onTap:  () => navigationShell.goBranch(0),
            ),
          ),
          Expanded(
            child: BNItem(
              icon:   Icons.history_rounded,
              label:  l10n.history,
              active: _active('/hr/history'),
              isDark: isDark,
              onTap:  () => navigationShell.goBranch(1),
            ),
          ),
          // Gap for the FAB notch — no label
          const SizedBox(width: 72),
          Expanded(
            child: BNItem(
              icon:   Icons.menu_book_rounded,
              label:  l10n.knowledgeBase,
              active: _active('/hr/knowledge'),
              isDark: isDark,
              onTap:  () => navigationShell.goBranch(2),
            ),
          ),
          Expanded(
            child: BNItem(
              icon:   Icons.account_circle_rounded,
              label:  l10n.profile,
              active: _active('/hr/profile'),
              isDark: isDark,
              onTap:  () => navigationShell.goBranch(3),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HR Centre FAB ────────────────────────────────────────────────────────────

class _HRCenterFab extends StatefulWidget {
  final String currentLocation;
  const _HRCenterFab({required this.currentLocation});

  @override
  State<_HRCenterFab> createState() => _HRCenterFabState();
}

class _HRCenterFabState extends State<_HRCenterFab>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _iconCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    // Icon: appear → breathe → float-away → pause → repeat  (2.4 s)
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  Widget _pulseRing(double phase) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final t = (_pulseCtrl.value + phase) % 1.0;
        final r = 28.0 + t * 22.0;
        final alpha = (1.0 - t) * 0.55;
        return SizedBox(
          width: r * 2,
          height: r * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6C47FF).withValues(alpha: alpha),
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/hr/generate'),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _pulseRing(0.0),
            _pulseRing(0.5),

            // Background circle + sparkle burst (all via CustomPaint)
            AnimatedBuilder(
              animation: Listenable.merge([_glowCtrl, _iconCtrl]),
              builder: (_, __) => CustomPaint(
                size: const Size(56, 56),
                painter: _FabPainter(
                  glow: _glowCtrl.value,
                  iconAnim: _iconCtrl.value,
                ),
              ),
            ),

            // Animated icon: appear → breathe → float away
            AnimatedBuilder(
              animation: _iconCtrl,
              builder: (_, __) {
                final t = _iconCtrl.value;
                final double scale;
                final double opacity;

                if (t < 0.18) {
                  // Bounce in
                  final p = t / 0.18;
                  scale   = Curves.easeOutBack.transform(p).clamp(0.0, 1.5);
                  opacity = (p * 1.6).clamp(0.0, 1.0);
                } else if (t < 0.58) {
                  // Hold with subtle breathing bob
                  final bp = (t - 0.18) / 0.40;
                  scale   = 1.0 + 0.03 * sin(bp * 2 * pi);
                  opacity = 1.0;
                } else if (t < 0.76) {
                  // Float upward & fade out
                  final p = (t - 0.58) / 0.18;
                  scale   = 1.0 + p * 0.42;
                  opacity = 1.0 - p;
                } else {
                  // Blank pause
                  scale   = 0.0;
                  opacity = 0.0;
                }

                return Transform.scale(
                  scale: scale.clamp(0.0, 1.5),
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 26,
                      shadows: [Shadow(color: Color(0x88FFFFFF), blurRadius: 8)],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FabPainter extends CustomPainter {
  final double glow;
  final double iconAnim;
  const _FabPainter({
    required this.glow,
    required this.iconAnim,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Breathing glow — extra burst when icon appears
    final appearBoost = iconAnim < 0.22 ? (1.0 - iconAnim / 0.22) * 0.30 : 0.0;
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()
        ..color = const Color(0xFF6C47FF)
            .withValues(alpha: (0.35 + 0.25 * glow + appearBoost).clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + glow * 6),
    );

    // Static radial gradient fill (no color rotation)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.topLeft,
          radius: 1.2,
          colors: [Color(0xFF8B65FF), Color(0xFF6C47FF)],
        ).createShader(rect),
    );

    // Inner top-left highlight
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Sparkle burst when icon appears (active 0.02 – 0.44)
    if (iconAnim > 0.02 && iconAnim < 0.44) {
      final st = ((iconAnim - 0.02) / 0.42).clamp(0.0, 1.0);
      // Fade in quickly, then fade out
      final alpha = (st < 0.25 ? st / 0.25 : 1.0 - (st - 0.25) / 0.75)
          .clamp(0.0, 1.0);
      final dotPaint = Paint()..style = PaintingStyle.fill;

      for (int i = 0; i < 8; i++) {
        final angle = i * pi / 4.0;
        final dist  = 10.0 + st * 18.0;
        final dotR  = (i.isEven ? 2.6 : 1.6) * (1.0 - st * 0.35);

        dotPaint.color = Colors.white.withValues(alpha: alpha * 0.88);
        canvas.drawCircle(
          Offset(center.dx + dist * cos(angle), center.dy + dist * sin(angle)),
          dotR.clamp(0.3, 3.0),
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FabPainter old) =>
      old.glow != glow || old.iconAnim != iconAnim;
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
  final isDark = Theme.of(context).brightness == Brightness.dark;

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
                'Bạn đã đăng nhập thành công vào HireGen AI.\nHãy bắt đầu tạo câu hỏi phỏng vấn ngay!',
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
                    style: TextStyle(
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
