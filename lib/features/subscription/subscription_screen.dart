import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'subscription_provider.dart';
import 'payment/upgrade_payment_sheet.dart';
import '../hr_generate/data/generation_api.dart';
import '../hr_generate/presentation/gen_colors.dart';
import '../../core/providers/ui_providers.dart';
import '../../core/widgets/grid_background.dart';
import '../../data/providers/app_providers.dart';

// ── Remote plan model (GET /api/plans?audience=HR) ────────────────────────────

class _RemotePlan {
  final String planCode;
  final String planName;
  final num priceMonthly;
  final String currency;
  final List<String> features;

  const _RemotePlan({
    required this.planCode,
    required this.planName,
    required this.priceMonthly,
    required this.currency,
    this.features = const [],
  });

  bool get isPremium => planCode.toUpperCase().contains('PREMIUM');

  factory _RemotePlan.fromJson(Map<String, dynamic> j) {
    dynamic v(String k, [String? k2]) => j[k] ?? (k2 != null ? j[k2] : null);

    final rawFeatures = v('features', 'Features');
    final List<String> features = rawFeatures is List
        ? rawFeatures.whereType<String>().toList()
        : [];

    return _RemotePlan(
      planCode:    (v('planCode',    'PlanCode')    ?? '').toString(),
      planName:    (v('planName',    'PlanName')    ?? '').toString(),
      priceMonthly: ((v('priceMonthly', 'PriceMonthly') ?? 0) as num),
      currency:    (v('currency',    'Currency')    ?? 'VND').toString(),
      features:    features,
    );
  }
}

final _plansProvider =
    FutureProvider.family<List<_RemotePlan>, String>((ref, audience) async {
  try {
    final dio = buildGenerationDio();
    final res =
        await dio.get('/api/plans', queryParameters: {'audience': audience});
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
        .map((e) => _RemotePlan.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  } catch (_) {
    return [];
  }
});

// ── Entry point ───────────────────────────────────────────────────────────────

class SubscriptionScreen extends ConsumerWidget {
  /// `HR` or `Candidate` — controls which plans list is fetched.
  final String audience;

  const SubscriptionScreen({super.key, this.audience = 'HR'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gc     = GenColors.of(context);

    return Scaffold(
      backgroundColor: gc.bg,
      appBar: AppBar(
        backgroundColor:  isDark ? const Color(0xFF0B1020) : Colors.white,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF374151)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          audience == 'Candidate' ? 'Thanh toán' : 'Gói dịch vụ',
          style: TextStyle(
            color:      isDark ? Colors.white : const Color(0xFF111827),
            fontSize:   16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            onPressed: () => ref.read(subscriptionProvider.notifier).refresh(),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: GridBackdrop(
        child: RefreshIndicator(
        onRefresh: () => ref.read(subscriptionProvider.notifier).refresh(),
        child: state.isLoading && state.subscription == null
            ? const Center(child: CircularProgressIndicator())
            : _SubscriptionBody(
                state: state,
                isDark: isDark,
                gc: gc,
                audience: audience,
              ),
      ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _SubscriptionBody extends ConsumerWidget {
  final SubscriptionState state;
  final bool isDark;
  final GenColors gc;
  final String audience;

  const _SubscriptionBody({
    required this.state,
    required this.isDark,
    required this.gc,
    required this.audience,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(_plansProvider(audience));
    final sub        = state.subscription;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
      children: [
        if (sub != null) _CurrentPlanCard(sub: sub, state: state, isDark: isDark, gc: gc),
        if (sub != null) const SizedBox(height: 16),
        if (sub != null) _UsageCard(sub: sub, state: state, isDark: isDark, gc: gc),
        const SizedBox(height: 28),
        Text(
          audience == 'Candidate' ? 'So sánh gói' : 'Các gói dịch vụ',
          style: TextStyle(
            color:      isDark ? Colors.white : const Color(0xFF111827),
            fontSize:   17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return _FallbackPlanCards(
                sub: sub,
                isDark: isDark,
                gc: gc,
                audience: audience,
              );
            }
            return Column(
              children: plans.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RemotePlanCard(
                  plan:      p,
                  isCurrent: sub?.planCode == p.planCode,
                  isDark:    isDark,
                  gc:        gc,
                ),
              )).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => _FallbackPlanCards(
            sub: sub,
            isDark: isDark,
            gc: gc,
            audience: audience,
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          _ErrorTile(msg: state.error!, isDark: isDark),
        ],
      ],
    );
  }
}

// ── Current plan card ─────────────────────────────────────────────────────────

class _CurrentPlanCard extends ConsumerWidget {
  final MySubscription sub;
  final SubscriptionState state;
  final bool isDark;
  final GenColors gc;

  const _CurrentPlanCard({
    required this.sub,
    required this.state,
    required this.isDark,
    required this.gc,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = sub.isPremium;
    final planColor = isPremium ? const Color(0xFF6C47FF) : const Color(0xFF6B7280);

    final String endLabel = _fmtDate(sub.periodEnd);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1F3A), const Color(0xFF0F1428)]
              : [const Color(0xFFEEF2FF), const Color(0xFFF4F5FB)],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium
              ? planColor.withValues(alpha: 0.4)
              : gc.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:  planColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPremium ? Icons.workspace_premium_rounded : Icons.person_rounded,
                  color: planColor,
                  size:  26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gói hiện tại',
                      style: TextStyle(
                        color:      gc.textSub,
                        fontSize:   11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub.planName,
                      style: TextStyle(
                        color:      isDark ? Colors.white : const Color(0xFF111827),
                        fontSize:   20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:        planColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPremium ? 'PREMIUM' : 'FREE',
                  style: TextStyle(
                    color:      planColor,
                    fontSize:   11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: 'Hiệu lực đến',
                  value: endLabel,
                  icon:  Icons.calendar_today_rounded,
                  isDark: isDark,
                  gc:    gc,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoChip(
                  label: 'Giá / tháng',
                  value: sub.priceMonthly == 0
                      ? 'Miễn phí'
                      : '${_fmt(sub.priceMonthly)} ${sub.currency}',
                  icon:  Icons.payments_rounded,
                  isDark: isDark,
                  gc:    gc,
                ),
              ),
            ],
          ),
          // Cooldown warning
          if (state.quotaBlocked && state.cooldownEndsAt != null) ...[
            const SizedBox(height: 12),
            _CooldownChip(endsAt: state.cooldownEndsAt!, isDark: isDark),
          ],
          // Cancel button (premium only)
          if (isPremium) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Huỷ đăng ký',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (_) => const _DowngradeConfirmDialog(),
    );
  }
}

// ── Downgrade confirmation dialog ─────────────────────────────────────────────

class _DowngradeConfirmDialog extends ConsumerStatefulWidget {
  const _DowngradeConfirmDialog();

  @override
  ConsumerState<_DowngradeConfirmDialog> createState() =>
      _DowngradeConfirmDialogState();
}

class _DowngradeConfirmDialogState
    extends ConsumerState<_DowngradeConfirmDialog> {
  bool _loading = false;

  static const _lostFeatures = [
    'Generate bộ câu hỏi không giới hạn (quay lại cooldown 24 giờ)',
    'Export PDF / DOCX',
    'Ask-AI trong Studio',
    'Publish Marketplace không giới hạn',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color:  const Color(0xFFF59E0B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded,
                  size: 32, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 16),
            Text(
              'Hạ về gói Free',
              style: TextStyle(
                color:      isDark ? Colors.white : const Color(0xFF111827),
                fontSize:   20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn sẽ mất ngay các tính năng Premium sau:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:    isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            // Feature-loss list
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color:        const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _lostFeatures
                    .map((f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.close_rounded,
                                  size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  f,
                                  style: const TextStyle(
                                    color:    Color(0xFFEF4444),
                                    fontSize: 12,
                                    height:   1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6C47FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Giữ Premium',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _loading
                      ? const SizedBox(
                          height: 44,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: _doDowngrade,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Hạ về Free',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doDowngrade() async {
    if (_loading) return;
    setState(() => _loading = true);
    final ok = await ref
        .read(subscriptionProvider.notifier)
        .cancelSubscription();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Đã huỷ đăng ký. Gói Free có hiệu lực từ kỳ tới.'
          : 'Huỷ đăng ký thất bại. Vui lòng thử lại.'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ── Usage / Quota card ────────────────────────────────────────────────────────

class _UsageCard extends StatelessWidget {
  final MySubscription sub;
  final SubscriptionState state;
  final bool isDark;
  final GenColors gc;

  const _UsageCard({
    required this.sub,
    required this.state,
    required this.isDark,
    required this.gc,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlimited = sub.limits.generateUnlimited;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        gc.card,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: gc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thống kê sử dụng',
              style: TextStyle(
                  color:      isDark ? Colors.white : const Color(0xFF111827),
                  fontSize:   14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _UsageStat(
            icon:        Icons.auto_awesome_rounded,
            label:       'Bộ câu hỏi đã tạo',
            value:       sub.generateSetUsed.toString(),
            suffix:      isUnlimited ? '' : ' (không giới hạn)',
            isDark:      isDark,
            gc:          gc,
          ),
          if (sub.askAiLimit > 0) ...[
            const SizedBox(height: 10),
            _UsageProgressStat(
              icon:    Icons.chat_bubble_outline_rounded,
              label:   'Ask-AI đã dùng',
              used:    sub.askAiUsed,
              total:   sub.askAiLimit,
              isDark:  isDark,
              gc:      gc,
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String suffix;
  final bool isDark;
  final GenColors gc;

  const _UsageStat({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix = '',
    required this.isDark,
    required this.gc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: GenColors.primary),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: gc.textSub, fontSize: 13)),
        const Spacer(),
        Text(
          '$value$suffix',
          style: TextStyle(
              color:      isDark ? Colors.white : const Color(0xFF111827),
              fontSize:   13,
              fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _UsageProgressStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int used;
  final int total;
  final bool isDark;
  final GenColors gc;

  const _UsageProgressStat({
    required this.icon,
    required this.label,
    required this.used,
    required this.total,
    required this.isDark,
    required this.gc,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (used / total).clamp(0.0, 1.0);
    final barColor = ratio > 0.85
        ? const Color(0xFFEF4444)
        : ratio > 0.6
            ? const Color(0xFFF59E0B)
            : GenColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: GenColors.primary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: gc.textSub, fontSize: 13)),
            const Spacer(),
            Text('$used / $total',
                style: TextStyle(
                    color:      isDark ? Colors.white : const Color(0xFF111827),
                    fontSize:   13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:           ratio,
            minHeight:       5,
            backgroundColor: isDark ? const Color(0xFF1E2640) : const Color(0xFFE5E7EB),
            valueColor:      AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

// ── Remote plan card (from API) ───────────────────────────────────────────────

class _RemotePlanCard extends ConsumerWidget {
  final _RemotePlan plan;
  final bool isCurrent;
  final bool isDark;
  final GenColors gc;

  const _RemotePlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isDark,
    required this.gc,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planColor = plan.isPremium ? const Color(0xFF6C47FF) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? GenColors.primary.withValues(alpha: 0.08) : gc.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? GenColors.primary : gc.border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                plan.isPremium
                    ? Icons.workspace_premium_rounded
                    : Icons.person_rounded,
                color: planColor,
                size:  20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.planName,
                  style: TextStyle(
                    color:      isDark ? Colors.white : const Color(0xFF111827),
                    fontSize:   15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        planColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Hiện tại',
                      style: TextStyle(
                          color:      planColor,
                          fontSize:   10,
                          fontWeight: FontWeight.w700)),
                ),
              if (!isCurrent) ...[
                Text(
                  plan.priceMonthly == 0
                      ? 'Miễn phí'
                      : '${_fmt(plan.priceMonthly)} ${plan.currency}/tháng',
                  style: TextStyle(
                      color:      planColor,
                      fontSize:   12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_rounded, size: 14, color: planColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(f,
                            style: TextStyle(color: gc.textSub, fontSize: 12)),
                      ),
                    ],
                  ),
                )),
          ],
          if (!isCurrent && plan.isPremium) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _startUpgrade(context, ref),
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: Text('Nâng cấp lên ${plan.planName}'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C47FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startUpgrade(BuildContext context, WidgetRef ref) async {
    final intent = await ref.read(subscriptionProvider.notifier).upgrade();
    if (intent == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:  Text('Không thể tạo đơn thanh toán. Vui lòng thử lại.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (!context.mounted) return;

    // Build the config, capturing ref — no ref stored in widget tree (spec §7.1)
    final userId = ref.read(authProvider).user?.id ?? '';
    final config = PaymentWaitConfig(
      pollInterval: kHrPollInterval,                      // 3 s per spec §5.2
      checkStatus:  (code) =>
          ref.read(subscriptionProvider.notifier).checkOrderStatus(code),
      onPaidRefresh: () =>
          ref.read(subscriptionProvider.notifier).refresh(),
      onCelebration: (ctx) =>
          maybeShowPremiumDialog(ctx, userId, intent.status),
      onCreateNewOrder: () =>
          ref.read(subscriptionProvider.notifier).upgrade(),
    );

    // Hide nav bar while sheet is open; restore when it closes (any way)
    ref.read(navBarVisibleProvider.notifier).state = false;
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder:            (_) => UpgradePaymentSheet(intent: intent, config: config),
    ).whenComplete(() {
      ref.read(navBarVisibleProvider.notifier).state = true;
    });
  }
}

// ── Fallback plan cards (when API fails) ──────────────────────────────────────

class _FallbackPlanCards extends ConsumerWidget {
  final MySubscription? sub;
  final bool isDark;
  final GenColors gc;
  final String audience;

  const _FallbackPlanCards({
    this.sub,
    required this.isDark,
    required this.gc,
    this.audience = 'HR',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFree = !(sub?.isPremium ?? false);
    final isCandidate = audience == 'Candidate';

    final freePlan = _RemotePlan(
      planCode: isCandidate ? 'CANDIDATE_FREE' : 'HR_FREE',
      planName: 'Miễn phí',
      priceMonthly: 0,
      currency: 'VND',
      features: isCandidate
          ? const [
              'Truy cập hạn chế bộ câu hỏi',
              '5 lượt luyện tập mỗi tháng',
              'Chỉ điểm AI cơ bản',
              'Lưu tối đa 10 phiên',
              'Không chia sẻ Scorecard cho HR',
            ]
          : const [
              '5 lượt tạo câu hỏi / tháng',
              'Tối đa 20 câu / bộ',
            ],
    );
    final premPlan = _RemotePlan(
      planCode: isCandidate ? 'CANDIDATE_PREMIUM' : 'HR_PREMIUM',
      planName: 'Premium',
      priceMonthly: isCandidate ? 99000 : 299000,
      currency: 'VND',
      features: isCandidate
          ? const [
              'Toàn quyền truy cập tất cả bộ câu hỏi',
              'Lượt luyện tập không giới hạn',
              'Đánh giá AI nâng cao & phản hồi chi tiết',
              'Lịch sử luyện tập không giới hạn',
              'Gửi Scorecard trực tiếp cho HR',
            ]
          : const [
              'Không giới hạn lượt tạo',
              'Export PDF/DOCX',
              'Ask-AI không giới hạn',
              'Ưu tiên hỗ trợ',
            ],
    );

    return Column(
      children: [
        _RemotePlanCard(plan: freePlan, isCurrent: isFree, isDark: isDark, gc: gc),
        const SizedBox(height: 12),
        _RemotePlanCard(plan: premPlan, isCurrent: !isFree, isDark: isDark, gc: gc),
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final GenColors gc;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.gc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: gc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: gc.textSub),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: gc.textSub, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color:      isDark ? Colors.white : const Color(0xFF111827),
                  fontSize:   13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CooldownChip extends StatefulWidget {
  final DateTime endsAt;
  final bool isDark;

  const _CooldownChip({required this.endsAt, required this.isDark});

  @override
  State<_CooldownChip> createState() => _CooldownChipState();
}

class _CooldownChipState extends State<_CooldownChip> {
  Timer? _t;
  Duration _rem = Duration.zero;

  @override
  void initState() {
    super.initState();
    _rem = widget.endsAt.difference(DateTime.now());
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _rem = widget.endsAt.difference(DateTime.now());
        if (_rem.isNegative) { _rem = Duration.zero; _t?.cancel(); }
      });
    });
  }

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final h = _rem.inHours;
    final m = _rem.inMinutes % 60;
    final s = _rem.inSeconds % 60;
    final text = h > 0 ? '${h}h ${m}m' : m > 0 ? '${m}m ${s}s' : '${s}s';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:        const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 6),
          Text(
            'Cooldown còn lại: $text',
            style: const TextStyle(
                color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String msg;
  final bool isDark;

  const _ErrorTile({required this.msg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Text(
        msg,
        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
      ),
    );
  }
}

// ── Format helper ─────────────────────────────────────────────────────────────

String _fmtDate(String raw) {
  if (raw.isEmpty) return '—';
  try {
    final d = DateTime.parse(raw).toLocal();
    return '${d.day}/${d.month}/${d.year}';
  } catch (_) {
    return raw;
  }
}

String _fmt(num v) {
  final s = v.toInt().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
