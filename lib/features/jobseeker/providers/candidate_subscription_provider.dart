import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../hr_generate/data/generation_api.dart';
import '../../subscription/subscription_provider.dart'
    show MySubscription, UpgradePaymentIntent;

// ── Helpers ───────────────────────────────────────────────────────────────────

dynamic _v(Map j, String k, [String? k2]) => j[k] ?? (k2 != null ? j[k2] : null);

Map<String, dynamic> _unwrap(dynamic raw) {
  if (raw is! Map) return {};
  final root = Map<String, dynamic>.from(raw);
  final d = root['data'];
  return d is Map ? Map<String, dynamic>.from(d) : root;
}

String _err(Object e) {
  if (e is DioException) {
    final body = e.response?.data;
    if (body is Map) {
      final msg = body['message'] ?? body['error'] ?? body['detail'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
  }
  return e.toString();
}

// ── Enums and model ───────────────────────────────────────────────────────────

/// §5.1 — Candidate only keeps planType in state (spec says "chỉ planType").
/// We add subscription for UI (billing page needs it).
enum CandidatePlanType { free, premium }

class CandidateSubscriptionState {
  final CandidatePlanType planType;
  final MySubscription? subscription;
  final bool isLoading;
  final String? error;

  const CandidateSubscriptionState({
    this.planType = CandidatePlanType.free, // §5.1 — always FREE on init
    this.subscription,
    this.isLoading = true,
    this.error,
  });

  bool get isPremium => planType == CandidatePlanType.premium;

  CandidateSubscriptionState copyWith({
    CandidatePlanType? planType,
    MySubscription? subscription,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      CandidateSubscriptionState(
        planType:     planType     ?? this.planType,
        subscription: subscription ?? this.subscription,
        isLoading:    isLoading    ?? this.isLoading,
        error:        clearError ? null : (error ?? this.error),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CandidateSubscriptionNotifier
    extends StateNotifier<CandidateSubscriptionState> {
  CandidateSubscriptionNotifier()
      : super(const CandidateSubscriptionState()) {
    _init();
  }

  /// §5.1 cache key
  static const _cacheKey = 'hiregena-candidate-plan';

  /// §5.7 celebration key prefix (no _hr_ prefix — distinct from HR)
  static const _celebKeyPrefix = 'hiregen_premium_ok_';

  /// Poll the subscription API every 30 s so admin-triggered upgrades are
  /// detected automatically without requiring the user to pull-to-refresh.
  static const _pollInterval = Duration(seconds: 30);
  Timer? _pollTimer;
  bool   _fetching = false; // guard against concurrent fetches

  // ── Initialise ─────────────────────────────────────────────────────────────

  Future<void> _init() async {
    // §5.1 order:
    // 1. State starts FREE (in constructor)
    // 2. Read cache → instant PREMIUM if previously saved
    // 3. Fetch API → overwrite + persist cache
    // 4. Start periodic poll so admin-triggered upgrades are detected
    await _readCache();
    await _fetchSubscription();
    _startPolling();
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  /// Start (or restart) the 30-second background poll.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (mounted) _fetchSubscription();
    });
  }

  /// Pause polling (e.g. while app is in background).
  void pausePolling() => _pollTimer?.cancel();

  /// Resume polling (e.g. when app comes back to foreground).
  void resumePolling() {
    if (!mounted) return;
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached == 'PREMIUM' && mounted) {
        state = state.copyWith(planType: CandidatePlanType.premium);
      }
    } catch (_) {}
  }

  Future<void> _fetchSubscription() async {
    // Guard against concurrent fetches (e.g. timer fires while manual refresh
    // or app-resume refresh is already in-flight).
    if (_fetching) return;
    _fetching = true;
    try {
      final dio = buildGenerationDio();
      final res = await dio.get('/api/me/subscription');
      final sub = MySubscription.fromJson(res.data);
      final isPremium = sub.isPremium;
      final planType =
          isPremium ? CandidatePlanType.premium : CandidatePlanType.free;

      // Persist cache
      _persistCache(isPremium);

      if (!mounted) return;
      state = state.copyWith(
        subscription: sub,
        planType: planType,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      // §5.1 — on error: keep current planType, don't force FREE
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: _err(e));
    } finally {
      _fetching = false;
    }
  }

  void _persistCache(bool isPremium) {
    SharedPreferences.getInstance().then((p) {
      p.setString(_cacheKey, isPremium ? 'PREMIUM' : 'FREE');
    }).catchError((_) {});
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Refresh without clearing existing data.
  Future<void> refresh() => _fetchSubscription();

  /// POST upgrade → UpgradePaymentIntent
  Future<UpgradePaymentIntent?> upgrade() async {
    try {
      final dio = buildGenerationDio();
      final res = await dio.post('/api/me/subscription/upgrade', data: {});
      return UpgradePaymentIntent.fromJson(res.data);
    } catch (e) {
      if (mounted) state = state.copyWith(error: _err(e));
      return null;
    }
  }

  /// Poll order status for payment sheet.
  Future<String?> checkOrderStatus(String orderCode) async {
    try {
      final dio = buildGenerationDio();
      final res =
          await dio.get('/api/me/subscription/upgrade/$orderCode');
      final j = _unwrap(res.data);
      return (_v(j, 'status', 'Status') ?? '').toString();
    } catch (_) {
      return null;
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      final dio = buildGenerationDio();
      final res = await dio.post('/api/me/subscription/cancel');
      final sub = MySubscription.fromJson(res.data);
      final isPremium = sub.isPremium;
      final planType =
          isPremium ? CandidatePlanType.premium : CandidatePlanType.free;
      _persistCache(isPremium);
      if (!mounted) return true;
      state = state.copyWith(subscription: sub, planType: planType);
      return true;
    } catch (e) {
      if (mounted) state = state.copyWith(error: _err(e));
      return false;
    }
  }

  void clearError() {
    if (mounted) state = state.copyWith(clearError: true);
  }

  // ── Celebration ─────────────────────────────────────────────────────────────

  /// Show celebration dialog once per user account upgrade.
  /// Key is `hiregen_premium_ok_{userId}` (spec §6.2) — matches web.
  /// Pass [userId] from `authProvider.user?.id`.
  Future<void> maybeShowCelebration(
      BuildContext context, {required String userId}) async {
    if (!state.isPremium) return;
    // Use userId so key is stable across re-upgrades within the same account
    // and distinct from HR key (`hiregen_hr_premium_ok_{userId}`).
    final key = '$_celebKeyPrefix${userId.isEmpty ? 'candidate' : userId}';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(key)) return;
      await prefs.setString(key, '1');
    } catch (_) {}
    if (!context.mounted) return;
    _showAnimatedDialog(
      context: context,
      barrierDismissible: false,
      child: const _CandidatePremiumCongratDialog(),
    );
  }

  /// Clear the celebration key on confirmed downgrade so the next upgrade
  /// shows the dialog again (spec §6.2 — clear only on real downgrade).
  Future<void> clearCelebrationKey(String userId) async {
    if (state.isPremium) return; // safety: only clear when actually free
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_celebKeyPrefix${userId.isEmpty ? 'candidate' : userId}';
      await prefs.remove(key);
    } catch (_) {}
  }
}

// ── Celebration dialog (Candidate copy) ──────────────────────────────────────

class _CandidatePremiumCongratDialog extends StatelessWidget {
  const _CandidatePremiumCongratDialog();

  static const _features = [
    'Luyện tập không giới hạn câu hỏi',
    'AI Feedback chi tiết & đánh giá nâng cao',
    'Lịch sử luyện tập không giới hạn',
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
            // ── Purple header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B21B6), Color(0xFF7C5CFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                // Sparkle decorations
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('✦', style: TextStyle(color: Color(0xAAFFFFFF), fontSize: 14)),
                    Text('✦', style: TextStyle(color: Color(0xAAFFFFFF), fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                // Crown circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chúc mừng!',
                  style: TextStyle(
                    color:      Colors.white,
                    fontSize:   24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]),
            ),

            // ── White / dark body ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              color: isDark ? const Color(0xFF111827) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color:      isDark ? Colors.white : const Color(0xFF111827),
                        fontSize:   16,
                        fontWeight: FontWeight.w700,
                        height:     1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Tài khoản đã được nâng cấp lên '),
                        const TextSpan(
                          text: 'Premium',
                          style: TextStyle(color: Color(0xFF7C5CFC)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bạn giờ đây có thể sử dụng tất cả tính năng cao cấp.',
                    style: TextStyle(
                      color:    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 13,
                      height:   1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Feature list
                  ..._features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 16, color: Color(0xFF7C5CFC)),
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

                  const SizedBox(height: 20),

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6C47FF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Bắt đầu ngay →',
                        style: TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.w700),
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

// ── Animated dialog helper ────────────────────────────────────────────────────

/// Shows a dialog with a spring-scale + fade enter animation and a
/// quick-scale + fade exit animation.
Future<T?> _showAnimatedDialog<T>({
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
    transitionBuilder: (_, anim, __, dialogChild) =>
        _dialogTransition(anim, dialogChild),
  );
}

Widget _dialogTransition(Animation<double> anim, Widget child) {
  // Separate curves for enter (spring) and exit (quick ease-in)
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
        child: child,
      ),
    ),
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final candidateSubscriptionProvider = StateNotifierProvider<
    CandidateSubscriptionNotifier, CandidateSubscriptionState>(
  (_) => CandidateSubscriptionNotifier(),
);
