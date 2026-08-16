import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/ui_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../hr_generate/data/generation_api.dart';
import '../../../subscription/subscription_provider.dart'
    show MySubscription;
import '../../../subscription/payment/upgrade_payment_sheet.dart';
import '../../providers/candidate_subscription_provider.dart';
import '../../../../core/widgets/app_skeleton.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

dynamic _v(Map j, String k, [String? k2]) => j[k] ?? (k2 != null ? j[k2] : null);

Map<String, dynamic> _unwrapJ(dynamic raw) {
  if (raw is! Map) return {};
  final d = raw['data'];
  return Map<String, dynamic>.from(d is Map ? d : raw);
}

String _fmtNum(num v) {
  final s = v.toInt().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fmtDate(String raw) {
  if (raw.isEmpty) return '—';
  try {
    final d = DateTime.parse(raw).toLocal();
    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return raw;
  }
}

// ── Candidate Usage model ─────────────────────────────────────────────────────

class _CandidateUsage {
  final int practiceUsed;
  final int? practiceLimit;
  const _CandidateUsage({required this.practiceUsed, this.practiceLimit});
}

final _candidateUsageProvider =
    FutureProvider.autoDispose<_CandidateUsage>((ref) async {
  final isPremium = ref.watch(candidateSubscriptionProvider).isPremium;
  try {
    final dio = buildGenerationDio();
    final res = await dio.get('/api/me/usage');
    dynamic raw = res.data;
    List<dynamic> rows;
    if (raw is List) {
      rows = raw;
    } else if (raw is Map) {
      final d = raw['data'] ?? raw['items'] ?? raw;
      rows = d is List ? d : [];
    } else {
      rows = [];
    }
    int used = 0;
    for (final r in rows) {
      if (r is! Map) continue;
      final type = (_v(r, 'usageType', 'UsageType') ?? '').toString();
      if (type == 'CandidateFeedback') {
        used = ((_v(r, 'usedCount', 'UsedCount') ?? 0) as num).toInt();
        break;
      }
    }
    if (used == 0 && rows.isNotEmpty) {
      final j = _unwrapJ(raw);
      used = ((_v(j, 'practiceSessionUsed', 'PracticeSessionUsed') ??
               _v(j, 'practiceCount', 'PracticeCount') ??
               _v(j, 'sessionCount', 'SessionCount') ??
               0) as num)
          .toInt();
    }
    return _CandidateUsage(
      practiceUsed: used,
      practiceLimit: isPremium ? null : 5,
    );
  } catch (_) {
    return _CandidateUsage(
      practiceUsed: 0,
      practiceLimit: isPremium ? null : 5,
    );
  }
});

// ── Remote plan model ─────────────────────────────────────────────────────────

class _CandidatePlan {
  final String planCode;
  final String planName;
  final num priceMonthly;
  final String currency;
  final List<String> features;

  const _CandidatePlan({
    required this.planCode,
    required this.planName,
    required this.priceMonthly,
    required this.currency,
    this.features = const [],
  });

  bool get isPremium => planCode.toUpperCase().contains('PREMIUM');

  factory _CandidatePlan.fromJson(Map<String, dynamic> j) {
    dynamic v(String k, [String? k2]) => j[k] ?? (k2 != null ? j[k2] : null);
    final rawF = v('features', 'Features');
    return _CandidatePlan(
      planCode:     (v('planCode',     'PlanCode')     ?? '').toString(),
      planName:     (v('planName',     'PlanName')     ?? '').toString(),
      priceMonthly: ((v('priceMonthly', 'PriceMonthly') ?? 0) as num),
      currency:     (v('currency',     'Currency')     ?? 'VND').toString(),
      features:     rawF is List ? rawF.whereType<String>().toList() : [],
    );
  }
}

final _candidatePlansProvider =
    FutureProvider.autoDispose<List<_CandidatePlan>>((ref) async {
  try {
    final dio = buildGenerationDio();
    final res = await dio.get(
      '/api/plans',
      queryParameters: {'audience': 'Candidate'},
    );
    dynamic raw = res.data;
    List<dynamic> list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      final d = raw['data'] ?? raw['items'] ?? raw['plans'] ?? raw;
      list = d is List ? d : [];
    } else {
      list = [];
    }
    return list
        .whereType<Map>()
        .map((e) => _CandidatePlan.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } catch (_) {
    return [];
  }
});

// ── Fallback feature lists ────────────────────────────────────────────────────

const _kFreeFeatures = [
  'Truy cập hạn chế bộ câu hỏi',
  '5 lượt luyện tập mỗi tháng',
  'Chỉ điểm AI cơ bản',
  'Lưu tối đa 10 phiên',
  'Không chia sẻ Scorecard cho HR',
];

const _kPremFeatures = [
  'Toàn quyền truy cập tất cả bộ câu hỏi',
  'Lượt luyện tập không giới hạn',
  'Đánh giá AI nâng cao & phản hồi chi tiết',
  'Lịch sử luyện tập không giới hạn',
  'Gửi Scorecard trực tiếp cho HR',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class CandidateSubscriptionScreen extends ConsumerWidget {
  /// When [embedded] is true (inside a settings tab), the AppBar is hidden
  /// and the background is transparent so the outer Scaffold shows through.
  final bool embedded;
  const CandidateSubscriptionScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(candidateSubscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = state.isLoading && state.subscription == null
        ? SubscriptionSkeleton(isDark: isDark)
        : RefreshIndicator(
            color:    AppColors.brandPurple,
            onRefresh: () async {
              await ref
                  .read(candidateSubscriptionProvider.notifier)
                  .refresh();
              ref.invalidate(_candidateUsageProvider);
              ref.invalidate(_candidatePlansProvider);
            },
            child: _Body(isDark: isDark, embedded: embedded),
          );

    if (embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF070C18) : const Color(0xFFF3F4F8),
      appBar: AppBar(
        backgroundColor:  isDark ? const Color(0xFF0B1020) : Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF374151)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Thanh toán',
            style: TextStyle(
              color:      isDark ? Colors.white : const Color(0xFF111827),
              fontSize:   17,
              fontWeight: FontWeight.w700,
            )),
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh_rounded),
            color:   isDark ? Colors.white54 : const Color(0xFF6B7280),
            tooltip: 'Làm mới',
            onPressed: () {
              ref.read(candidateSubscriptionProvider.notifier).refresh();
              ref.invalidate(_candidateUsageProvider);
              ref.invalidate(_candidatePlansProvider);
            },
          ),
        ],
      ),
      body: body,
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final bool isDark;
  final bool embedded;
  const _Body({required this.isDark, required this.embedded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state      = ref.watch(candidateSubscriptionProvider);
    final sub        = state.subscription;
    final usageAsync = ref.watch(_candidateUsageProvider);
    final plansAsync = ref.watch(_candidatePlansProvider);
    final authUser   = ref.watch(authProvider).user;

    final plans    = plansAsync.valueOrNull ?? [];
    final freePlan = plans.where((p) => !p.isPremium).firstOrNull ??
        const _CandidatePlan(
          planCode:     'CANDIDATE_FREE',
          planName:     'Miễn phí',
          priceMonthly: 0,
          currency:     'VND',
          features:     _kFreeFeatures,
        );
    final premPlan = plans.where((p) => p.isPremium).firstOrNull ??
        _CandidatePlan(
          planCode:     'CANDIDATE_PREMIUM',
          planName:     'Premium',
          priceMonthly: 99000,
          currency:     sub?.currency ?? 'VND',
          features:     _kPremFeatures,
        );

    final freeFeatures =
        freePlan.features.isEmpty ? _kFreeFeatures : freePlan.features;
    final premFeatures =
        premPlan.features.isEmpty ? _kPremFeatures : premPlan.features;

    final isPremium = state.isPremium;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 52),
      children: [
        // ── Hero ─────────────────────────────────────────────────────────────
        _HeroCard(
          sub:        sub,
          usageAsync: usageAsync,
          isPremium:  isPremium,
          isDark:     isDark,
          onUpgrade:  () => _startUpgrade(context, ref),
        ),
        const SizedBox(height: 22),

        // ── Plan comparison ──────────────────────────────────────────────────
        _Label('So sánh gói', isDark: isDark),
        const SizedBox(height: 10),
        _PlanComparison(
          freePlan:        freePlan,
          freeFeatures:    freeFeatures,
          premPlan:        premPlan,
          premFeatures:    premFeatures,
          currentPlanCode: sub?.planCode ?? '',
          isDark:          isDark,
          onUpgrade:       () => _startUpgrade(context, ref),
        ),
        const SizedBox(height: 22),

        // ── Usage & Limits ───────────────────────────────────────────────────
        _Label('Sử dụng & Hạn mức', isDark: isDark),
        const SizedBox(height: 10),
        _UsageSection(
          sub:        sub,
          usageAsync: usageAsync,
          isDark:     isDark,
          isPremium:  isPremium,
          onUpgrade:  () => _startUpgrade(context, ref),
        ),
        const SizedBox(height: 22),

        // ── Payment history ──────────────────────────────────────────────────
        _PaymentHistorySection(isDark: isDark),
        const SizedBox(height: 16),

        // ── Payment info ─────────────────────────────────────────────────────
        _PaymentInfoSection(
          name:     authUser?.name ?? '',
          email:    authUser?.email ?? '',
          isDark:   isDark,
        ),

        // ── Error ────────────────────────────────────────────────────────────
        if (state.error != null) ...[
          const SizedBox(height: 16),
          _ErrorTile(msg: state.error!, isDark: isDark),
        ],
      ],
    );
  }

  Future<void> _startUpgrade(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(candidateSubscriptionProvider.notifier);
    final intent   = await notifier.upgrade();
    if (intent == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:  Text('Không thể tạo đơn thanh toán. Vui lòng thử lại.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!context.mounted) return;

    final userId = ref.read(authProvider).user?.id ?? '';
    final config = PaymentWaitConfig(
      pollInterval: kCandidatePollInterval,               // 15 s per spec §5.3
      checkStatus:  (code) => notifier.checkOrderStatus(code),
      onPaidRefresh: () async {
        await notifier.refresh();
        ref.invalidate(_candidateUsageProvider);
      },
      onCelebration: (ctx) =>
          notifier.maybeShowCelebration(ctx, userId: userId),
      onCreateNewOrder: () => notifier.upgrade(),
    );

    // Hide nav bar while sheet is open; restore when it closes (any way)
    ref.read(navBarVisibleProvider.notifier).state = false;
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => UpgradePaymentSheet(intent: intent, config: config),
    ).whenComplete(() {
      ref.read(navBarVisibleProvider.notifier).state = true;
    });
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  final bool   isDark;
  const _Label(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color:         isDark ? Colors.white : const Color(0xFF111827),
          fontSize:      16,
          fontWeight:    FontWeight.w700,
          letterSpacing: -0.1,
        ),
      );
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final MySubscription?              sub;
  final AsyncValue<_CandidateUsage> usageAsync;
  final bool                         isPremium;
  final bool                         isDark;
  final VoidCallback                 onUpgrade;

  const _HeroCard({
    required this.sub,
    required this.usageAsync,
    required this.isPremium,
    required this.isDark,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final fvp    = sub?.limits.freeVisiblePercent ?? 20;
    final usage  = usageAsync.valueOrNull;
    final used   = usage?.practiceUsed ?? 0;
    final limit  = usage?.practiceLimit ?? 5;
    final usageLabel = isPremium ? '∞' : '$used/$limit';

    // Premium card always uses a dark style; free card adapts to the theme.
    final cardDark = isDark || isPremium;

    final bg = isPremium
        ? const LinearGradient(
            colors: [Color(0xFF2D1B69), Color(0xFF1A0D3E)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)
        : (isDark
            ? const LinearGradient(
                colors: [Color(0xFF0F1629), Color(0xFF0A0F1E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : const LinearGradient(
                colors: [Color(0xFFF8F9FF), Color(0xFFF0EDFF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight));

    final cardBorderColor = isPremium
        ? const Color(0xFF7C5CFC).withValues(alpha: 0.5)
        : (isDark
            ? const Color(0xFF2D3556)
            : const Color(0xFFD5CCFF));

    final badgeBorderColor = isPremium
        ? const Color(0xFF7C5CFC).withValues(alpha: 0.6)
        : (cardDark ? const Color(0xFF4B5563) : const Color(0xFFB8ADFF));

    final badgeTextColor = isPremium
        ? const Color(0xFFD4B8FF)
        : (cardDark ? const Color(0xFF9CA3AF) : const Color(0xFF7056D6));

    final titleColor   = cardDark ? Colors.white : const Color(0xFF1A1040);
    final subtitleColor = cardDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Container(
      padding:    const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:     bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorderColor, width: 1.2),
        boxShadow: cardDark
            ? null
            : [
                BoxShadow(
                  color:      const Color(0xFF6C47FF).withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset:     const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: badge + upgrade button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPremium
                      ? null
                      : (cardDark
                          ? null
                          : const Color(0xFF6C47FF).withValues(alpha: 0.08)),
                  border: Border.all(color: badgeBorderColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPremium
                          ? Icons.workspace_premium_rounded
                          : Icons.star_border_rounded,
                      size:  11,
                      color: badgeTextColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isPremium ? 'GÓI PREMIUM' : 'GÓI MIỄN PHÍ',
                      style: TextStyle(
                        color:         badgeTextColor,
                        fontSize:      10,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!isPremium)
                GestureDetector(
                  onTap: onUpgrade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B35E8), Color(0xFF06B6D4)],
                        begin:  Alignment.centerLeft,
                        end:    Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:      const Color(0xFF5B35E8).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset:     const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            size: 13, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Nâng cấp lên Premium',
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Plan name
          Text(
            isPremium ? 'Premium' : 'Gói Miễn Phí',
            style: TextStyle(
              color:         titleColor,
              fontSize:      22,
              fontWeight:    FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPremium
                ? 'Bạn đang dùng gói Premium với toàn quyền truy cập tính năng.'
                : 'Bạn đang dùng Gói Miễn Phí với quyền truy cập luyện tập hạn chế.',
            style: TextStyle(
              color:    subtitleColor,
              fontSize: 12.5,
              height:   1.4,
            ),
          ),
          const SizedBox(height: 16),

          // 4 stat chips — pass cardDark so chips always match the card background
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatChip(
                  label: 'Lượt luyện tập',
                  value: usageAsync.when(
                    loading: () => '...',
                    error:   (_, __) => usageLabel,
                    data:    (u) => isPremium
                        ? '∞'
                        : '${u.practiceUsed}/${u.practiceLimit ?? 5}',
                  ),
                  cardDark: cardDark,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Mức AI Feedback',
                  value: isPremium ? 'Nâng cao' : 'Cơ bản',
                  cardDark: cardDark,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Truy cập câu hỏi',
                  value: isPremium ? 'Toàn bộ' : '${fvp}%/set',
                  cardDark: cardDark,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Gửi Scorecard cho HR',
                  value: isPremium ? 'Khả dụng' : '🔒 Bị khóa',
                  cardDark: cardDark,
                  locked: !isPremium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  /// True when the parent card has a dark background (dark mode OR premium card).
  final bool   cardDark;
  final bool   locked;

  const _StatChip({
    required this.label,
    required this.value,
    required this.cardDark,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipBg     = cardDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFF6C47FF).withValues(alpha: 0.07);
    final chipBorder = cardDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFF6C47FF).withValues(alpha: 0.18);
    final labelColor = cardDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF8B7EBF);
    final valueColor = locked
        ? (cardDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))
        : (cardDark ? Colors.white : const Color(0xFF1A1040));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        chipBg,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: chipBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 10.5)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color:      valueColor,
              fontSize:   14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan comparison ───────────────────────────────────────────────────────────

class _PlanComparison extends StatelessWidget {
  final _CandidatePlan freePlan;
  final _CandidatePlan premPlan;
  final List<String>  freeFeatures;
  final List<String>  premFeatures;
  final String        currentPlanCode;
  final bool          isDark;
  final VoidCallback  onUpgrade;

  const _PlanComparison({
    required this.freePlan,
    required this.premPlan,
    required this.freeFeatures,
    required this.premFeatures,
    required this.currentPlanCode,
    required this.isDark,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentFree =
        !currentPlanCode.toUpperCase().contains('PREMIUM');

    // IntrinsicHeight forces both cards to be as tall as the taller one,
    // and CrossAxisAlignment.stretch fills that height in each child.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Free card
          Expanded(
            child: _FreePlanCard(
              features:  freeFeatures,
              isCurrent: isCurrentFree,
              isDark:    isDark,
            ),
          ),
          const SizedBox(width: 10),
          // Premium card
          Expanded(
            child: _PremiumPlanCard(
              premPlan:  premPlan,
              features:  premFeatures,
              isCurrent: !isCurrentFree,
              isDark:    isDark,
              onUpgrade: onUpgrade,
            ),
          ),
        ],
      ),
    );
  }
}

class _FreePlanCard extends StatelessWidget {
  final List<String> features;
  final bool         isCurrent;
  final bool         isDark;

  const _FreePlanCard({
    required this.features,
    required this.isCurrent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderC = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final labelC = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final textC  = isDark ? Colors.white : const Color(0xFF111827);

    return Container(
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: borderC),
      ),
      child: Column(
        // Fill the height imposed by IntrinsicHeight + stretch
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GÓI MIỄN PHÍ',
                  style: TextStyle(
                      color:      labelC,
                      fontSize:   9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6),
                ),
                const SizedBox(height: 6),
                Text('Miễn phí',
                    style: TextStyle(
                        color:      textC,
                        fontSize:   20,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: borderC),

          // Features — Expanded so they fill the remaining height
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < features.length; i++) ...[
                    _FeatureRow(
                        text: features[i], isPremium: false, isDark: isDark),
                    if (i < features.length - 1) const SizedBox(height: 7),
                  ],
                ],
              ),
            ),
          ),

          // Button pinned at the bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  disabledForegroundColor: labelC,
                  disabledBackgroundColor:
                      isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                  side: BorderSide(color: borderC),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Gói hiện tại',
                  style: TextStyle(
                      color:      labelC,
                      fontSize:   13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPlanCard extends StatelessWidget {
  final _CandidatePlan premPlan;
  final List<String>   features;
  final bool           isCurrent;
  final bool           isDark;
  final VoidCallback   onUpgrade;

  const _PremiumPlanCard({
    required this.premPlan,
    required this.features,
    required this.isCurrent,
    required this.isDark,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    const purp   = AppColors.brandPurple;
    final cardBg = isDark ? const Color(0xFF160D33) : const Color(0xFFF0EEFF);
    final border = purp.withValues(alpha: isDark ? 0.60 : 0.40);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Card body — fills the height imposed by IntrinsicHeight + stretch
        Container(
          decoration: BoxDecoration(
            color:        cardBg,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color:      purp.withValues(alpha: 0.18),
                blurRadius: 16,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 50, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PREMIUM',
                      style: TextStyle(
                          color:      purp,
                          fontSize:   9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text:  'đ${_fmtNum(premPlan.priceMonthly)}',
                          style: const TextStyle(
                              color:      Colors.white,
                              fontSize:   20,
                              fontWeight: FontWeight.w900),
                        ),
                        const TextSpan(
                          text:  ' /tháng',
                          style: TextStyle(
                              color:   Color(0xFF9CA3AF),
                              fontSize: 11),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(height: 1, color: purp.withValues(alpha: 0.18)),

              // Features — Expanded so they fill the remaining height
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < features.length; i++) ...[
                        _FeatureRow(
                            text: features[i], isPremium: true, isDark: isDark),
                        if (i < features.length - 1) const SizedBox(height: 7),
                      ],
                    ],
                  ),
                ),
              ),

              // CTA button pinned at the bottom
              if (!isCurrent)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B35E8), Color(0xFF06B6D4)],
                          begin:  Alignment.centerLeft,
                          end:    Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton(
                        onPressed: onUpgrade,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding:         const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Nâng cấp ngay',
                                style: TextStyle(
                                    color:      Colors.white,
                                    fontSize:   13,
                                    fontWeight: FontWeight.w700)),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded,
                                size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // "ĐỀ XUẤT" badge — top-right corner
        Positioned(
          top:   -1,
          right: -1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color:        purp,
              borderRadius: const BorderRadius.only(
                topRight:    Radius.circular(14),
                bottomLeft:  Radius.circular(10),
              ),
            ),
            child: const Text(
              'ĐỀ XUẤT',
              style: TextStyle(
                  color:         Colors.white,
                  fontSize:      9,
                  fontWeight:    FontWeight.w800,
                  letterSpacing: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final bool   isPremium;
  final bool   isDark;
  const _FeatureRow({
    required this.text, required this.isPremium, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final checkColor = isPremium
        ? const Color(0xFF10B981)
        : isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final textColor = isDark
        ? (isPremium ? const Color(0xFFE5E7EB) : const Color(0xFF9CA3AF))
        : (isPremium ? const Color(0xFF374151) : const Color(0xFF6B7280));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            isPremium ? Icons.check_rounded : Icons.close_rounded,
            size:  13,
            color: checkColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(color: textColor, fontSize: 11.5, height: 1.4)),
        ),
      ],
    );
  }
}

// ── Usage section ─────────────────────────────────────────────────────────────

class _UsageSection extends StatelessWidget {
  final MySubscription?              sub;
  final AsyncValue<_CandidateUsage> usageAsync;
  final bool                         isDark;
  final bool                         isPremium;
  final VoidCallback                 onUpgrade;

  const _UsageSection({
    required this.sub,
    required this.usageAsync,
    required this.isDark,
    required this.isPremium,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg  = isDark ? const Color(0xFF111827) : Colors.white;
    final borderC = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final labelC  = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    final usage     = usageAsync.valueOrNull;
    final used      = usage?.practiceUsed ?? 0;
    final limit     = usage?.practiceLimit ?? 5;
    final isOver    = !isPremium && used > limit;
    final ratio     = isPremium ? 1.0 : (used / limit).clamp(0.0, 1.0);
    final barColor  = isOver
        ? const Color(0xFFEF4444)
        : ratio > 0.75
            ? const Color(0xFFF59E0B)
            : AppColors.brandPurple;
    final fvp       = sub?.limits.freeVisiblePercent ?? 20;
    final qRatio    = (fvp / 100.0).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: borderC),
      ),
      child: Column(
        children: [
          // Row 1: Lượt luyện tập
          _UsageRow(
            icon:       Icons.fitness_center_rounded,
            iconColor:  AppColors.brandPurple,
            title:      'Lượt luyện tập',
            isDark:     isDark,
            trailingLabel: isPremium
                ? '∞'
                : usageAsync.isLoading
                    ? '...'
                    : '$used/$limit',
            trailingLabelColor: isOver ? const Color(0xFFEF4444) : labelC,
            barValue:   isPremium ? null : ratio,
            barColor:   barColor,
          ),
          Divider(height: 1, color: borderC),

          // Row 2: Mức AI Feedback
          _UsageRow(
            icon:       Icons.psychology_rounded,
            iconColor:  const Color(0xFF8B5CF6),
            title:      'Mức AI Feedback',
            isDark:     isDark,
            chipLabel:  isPremium ? 'Nâng cao' : 'Cơ bản',
            chipColor:  isPremium ? AppColors.brandPurple : const Color(0xFF64748B),
            barValue:   isPremium ? 1.0 : 0.38,
            barColor:   isPremium ? const Color(0xFF10B981) : null,
            grayBar:    !isPremium,
          ),
          Divider(height: 1, color: borderC),

          // Row 3: Truy cập câu hỏi
          _UsageRow(
            icon:       Icons.library_books_rounded,
            iconColor:  const Color(0xFF3B82F6),
            title:      'Truy cập câu hỏi',
            isDark:     isDark,
            barValue:   isPremium ? 1.0 : qRatio.clamp(0.05, 0.45),
            barColor:   isPremium ? const Color(0xFF10B981) : null,
            grayBar:    !isPremium,
          ),
          Divider(height: 1, color: borderC),

          // Row 4: Gửi Scorecard cho HR
          _UsageRow(
            icon:       Icons.description_rounded,
            iconColor:  const Color(0xFFF59E0B),
            title:      'Gửi Scorecard cho HR',
            isDark:     isDark,
            chipLabel:  isPremium ? 'Khả dụng' : 'Bị khóa',
            chipColor:  isPremium ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            chipIcon:   isPremium ? null : Icons.lock_rounded,
          ),
          Divider(height: 1, color: borderC),

          // Footer
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nâng cấp để mở khóa tất cả tính năng Premium.',
                      style: TextStyle(color: labelC, fontSize: 12),
                    ),
                  ),
                  GestureDetector(
                    onTap: onUpgrade,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Nâng cấp lên Premium',
                          style: TextStyle(
                            color:      AppColors.brandPurple,
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded,
                            size: 14, color: AppColors.brandPurple),
                      ],
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

class _UsageRow extends StatelessWidget {
  final IconData  icon;
  final Color     iconColor;
  final String    title;
  final bool      isDark;

  // Optional right side: plain label or chip
  final String? trailingLabel;
  final Color?  trailingLabelColor;
  final String? chipLabel;
  final Color?  chipColor;
  final IconData? chipIcon;

  // Optional progress bar
  final double? barValue;
  final Color?  barColor;
  /// When true: renders a decorative grey bar (visible in both light & dark).
  final bool    grayBar;

  const _UsageRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isDark,
    this.trailingLabel,
    this.trailingLabelColor,
    this.chipLabel,
    this.chipColor,
    this.chipIcon,
    this.barValue,
    this.barColor,
    this.grayBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final textC  = isDark ? Colors.white : const Color(0xFF111827);
    final showBar = barValue != null;

    // ── Bar colors ────────────────────────────────────────────────────────────
    // grayBar (decorative): use a clearly visible grey pair in both themes.
    // Colored bar (real progress): use barColor + standard light track.
    final barTrack = isDark
        ? const Color(0xFF1E2640)
        : (grayBar ? const Color(0xFFF1F5F9) : const Color(0xFFE5E7EB));
    final barFill = grayBar
        ? (isDark ? const Color(0xFF4B5563) : const Color(0xFFB0BBC8))
        : (barColor ?? AppColors.brandPurple);

    // ── Chip colors ───────────────────────────────────────────────────────────
    // In light mode, chipColor at low alpha on white = invisible.
    // Use a solid muted bg in light mode for grey chips.
    Color chipBg(Color c) => isDark
        ? c.withValues(alpha: 0.15)
        : c.withValues(alpha: 0.08);
    Color chipBorder(Color c) => isDark
        ? c.withValues(alpha: 0.30)
        : c.withValues(alpha: 0.30);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color:        iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        color:      textC,
                        fontSize:   13.5,
                        fontWeight: FontWeight.w600)),
              ),
              if (trailingLabel != null)
                Text(
                  trailingLabel!,
                  style: TextStyle(
                      color:      trailingLabelColor ??
                          (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                      fontSize:   13,
                      fontWeight: FontWeight.w700),
                ),
              if (chipLabel != null && chipColor != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color:        chipBg(chipColor!),
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(color: chipBorder(chipColor!)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chipIcon != null) ...[
                        Icon(chipIcon, size: 10, color: chipColor),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        chipLabel!,
                        style: TextStyle(
                          color:      chipColor,
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (showBar) ...[
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value:           barValue,
                minHeight:       5,
                backgroundColor: barTrack,
                valueColor:      AlwaysStoppedAnimation<Color>(barFill),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Payment history ───────────────────────────────────────────────────────────

class _PaymentHistorySection extends StatelessWidget {
  final bool isDark;
  const _PaymentHistorySection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg  = isDark ? const Color(0xFF111827) : Colors.white;
    final borderC = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final labelC  = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final textC   = isDark ? Colors.white : const Color(0xFF111827);

    return Container(
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: borderC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color:        const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      size: 16, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 10),
                Text('Lịch sử thanh toán',
                    style: TextStyle(
                        color:      textC,
                        fontSize:   14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Divider(height: 1, color: borderC),

          // Empty state
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color:        isDark
                          ? const Color(0xFF1F2937)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.monetization_on_outlined,
                        size: 26, color: labelC),
                  ),
                  const SizedBox(height: 12),
                  Text('Chưa có lịch sử thanh toán.',
                      style: TextStyle(
                          color:      textC,
                          fontSize:   14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Các giao dịch của bạn sẽ hiển thị tại đây sau khi nâng cấp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: labelC, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment info ──────────────────────────────────────────────────────────────

class _PaymentInfoSection extends StatelessWidget {
  final String name;
  final String email;
  final bool   isDark;

  const _PaymentInfoSection({
    required this.name,
    required this.email,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg  = isDark ? const Color(0xFF111827) : Colors.white;
    final borderC = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final labelC  = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final textC   = isDark ? Colors.white : const Color(0xFF111827);

    return Container(
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: borderC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color:        AppColors.brandPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.credit_card_rounded,
                      size: 16, color: AppColors.brandPurple),
                ),
                const SizedBox(width: 10),
                Text('Thông tin thanh toán',
                    style: TextStyle(
                        color:      textC,
                        fontSize:   14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Divider(height: 1, color: borderC),

          // Rows
          _InfoRow(
            label: 'Họ và tên',
            value: name.isNotEmpty ? name : '—',
            isDark: isDark, borderC: borderC,
            labelC: labelC, textC: textC,
          ),
          _InfoRow(
            label: 'Email',
            value: email.isNotEmpty ? email : '—',
            isDark: isDark, borderC: borderC,
            labelC: labelC, textC: textC,
          ),
          _InfoRow(
            label: 'Phương thức thanh toán',
            value: 'Chưa có phương thức thanh toán',
            isDark: isDark, borderC: borderC,
            labelC: labelC, textC: labelC,
            last: true,
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:  Text('Tính năng sắp ra mắt'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textC,
                      side: BorderSide(color: borderC),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text('Cập nhật thông tin',
                        style: TextStyle(
                            fontSize:   12.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:  Text('Tính năng sắp ra mắt'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textC,
                      side: BorderSide(color: borderC),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon:  Icon(Icons.credit_card_rounded,
                        size: 14, color: textC),
                    label: const Text('Đổi phương thức',
                        style: TextStyle(
                            fontSize:   12.5,
                            fontWeight: FontWeight.w600)),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   isDark;
  final Color  borderC;
  final Color  labelC;
  final Color  textC;
  final bool   last;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
    required this.borderC,
    required this.labelC,
    required this.textC,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Label — shrinks if needed but prefers natural width
              Flexible(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(color: labelC, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              // Value — takes remaining space, right-aligned, can wrap 2 lines
              Flexible(
                flex: 3,
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color:      textC,
                      fontSize:   13.5,
                      fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: borderC),
      ],
    );
  }
}

// ── Error tile ────────────────────────────────────────────────────────────────

class _ErrorTile extends StatelessWidget {
  final String msg;
  final bool   isDark;
  const _ErrorTile({required this.msg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.30)),
      ),
      child: Text(msg,
          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
    );
  }
}
