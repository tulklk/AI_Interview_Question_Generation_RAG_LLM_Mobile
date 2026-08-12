import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../hr_generate/data/generation_api.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

dynamic _v(Map j, String camel, [String? pascal]) =>
    j[camel] ?? (pascal != null ? j[pascal] : null);

Map<String, dynamic> _unwrap(dynamic raw) {
  if (raw is! Map) return {};
  final root = Map<String, dynamic>.from(raw);
  final d = root['data'];
  return d is Map ? Map<String, dynamic>.from(d) : root;
}

bool _isPremium(String? planCode) =>
    (planCode ?? '').toUpperCase().contains('PREMIUM');

// ── §5.3 Models ───────────────────────────────────────────────────────────────

class SubscriptionLimits {
  final int generateCooldownHours;
  final bool generateUnlimited;
  final int planRegeneratePerDraft;
  final bool canExport;
  final int askAiPerMonth;
  final bool canPublish; // default true if key absent
  final int freeVisiblePercent; // default 20
  final bool canPersistHrRecommendation;
  final bool feedbackOnlyOnVisible;

  const SubscriptionLimits({
    this.generateCooldownHours = 24,
    this.generateUnlimited = false,
    this.planRegeneratePerDraft = 5,
    this.canExport = false,
    this.askAiPerMonth = 0,
    this.canPublish = true,
    this.freeVisiblePercent = 20,
    this.canPersistHrRecommendation = false,
    this.feedbackOnlyOnVisible = false,
  });

  factory SubscriptionLimits.fromJson(Map<String, dynamic> j) {
    // canPublish: true if key not present at all (§5.3 rule)
    final hasPublish = j.containsKey('canPublish') || j.containsKey('CanPublish');
    final rawPublish = _v(j, 'canPublish', 'CanPublish');
    bool canPublish = true;
    if (hasPublish) {
      if (rawPublish is bool) canPublish = rawPublish;
      else if (rawPublish != null) canPublish = rawPublish.toString() == 'true';
    }

    int fvp = ((_v(j, 'freeVisiblePercent', 'FreeVisiblePercent') ?? 0) as num).toInt();
    if (fvp == 0) fvp = 20;

    return SubscriptionLimits(
      generateCooldownHours:      ((_v(j, 'generateCooldownHours',      'GenerateCooldownHours')      ?? 24) as num).toInt(),
      generateUnlimited:           (_v(j, 'generateUnlimited',           'GenerateUnlimited')           as bool?) ?? false,
      planRegeneratePerDraft:     ((_v(j, 'planRegeneratePerDraft',     'PlanRegeneratePerDraft')     ?? 5)  as num).toInt(),
      canExport:                   (_v(j, 'canExport',                   'CanExport')                   as bool?) ?? false,
      askAiPerMonth:              ((_v(j, 'askAiPerMonth',              'AskAiPerMonth')              ?? 0)  as num).toInt(),
      canPublish:                  canPublish,
      freeVisiblePercent:          fvp,
      canPersistHrRecommendation: (_v(j, 'canPersistHrRecommendation', 'CanPersistHrRecommendation') as bool?) ?? false,
      feedbackOnlyOnVisible:       (_v(j, 'feedbackOnlyOnVisible',      'FeedbackOnlyOnVisible')      as bool?) ?? false,
    );
  }
}

class SubscriptionEntitlements {
  final bool canExport;
  final bool canAskAi;
  final bool generateUnlimited;
  final int freeVisiblePercent;
  final bool canPersistHrRecommendation;

  const SubscriptionEntitlements({
    this.canExport = false,
    this.canAskAi = false,
    this.generateUnlimited = false,
    this.freeVisiblePercent = 20,
    this.canPersistHrRecommendation = false,
  });

  /// Merge raw entitlements with limits using OR (§5.3)
  factory SubscriptionEntitlements.merge(
      Map<String, dynamic>? raw, SubscriptionLimits limits) {
    final r = raw ?? {};
    final rawExport    = (_v(r, 'canExport',    'CanExport')    as bool?) ?? false;
    final rawAskAi     = (_v(r, 'canAskAi',     'CanAskAi')     as bool?) ?? false;
    final rawUnlimited = (_v(r, 'generateUnlimited', 'GenerateUnlimited') as bool?) ?? false;
    final rawFvp       = ((_v(r, 'freeVisiblePercent', 'FreeVisiblePercent') ?? 0) as num).toInt();
    final rawPersist   = (_v(r, 'canPersistHrRecommendation', 'CanPersistHrRecommendation') as bool?) ?? false;

    return SubscriptionEntitlements(
      canExport:                  rawExport    || limits.canExport,
      canAskAi:                   rawAskAi     || limits.askAiPerMonth > 0,
      generateUnlimited:          rawUnlimited || limits.generateUnlimited,
      freeVisiblePercent:         rawFvp       > 0 ? rawFvp : limits.freeVisiblePercent,
      canPersistHrRecommendation: rawPersist   || limits.canPersistHrRecommendation,
    );
  }
}

class MySubscription {
  final String planCode;
  final String planName;
  final String audience;
  final String status;
  final num priceMonthly;
  final String currency;
  final String periodStart;
  final String periodEnd;
  final String? lastSuccessfulGenerateAt;
  final SubscriptionLimits limits;
  final int askAiUsed;
  final int askAiLimit;
  final int generateSetUsed;
  final SubscriptionEntitlements entitlements;

  bool get isPremium => _isPremium(planCode);

  const MySubscription({
    required this.planCode,
    required this.planName,
    required this.audience,
    required this.status,
    required this.priceMonthly,
    required this.currency,
    required this.periodStart,
    required this.periodEnd,
    this.lastSuccessfulGenerateAt,
    required this.limits,
    required this.askAiUsed,
    required this.askAiLimit,
    required this.generateSetUsed,
    required this.entitlements,
  });

  factory MySubscription.fromJson(dynamic raw) {
    final j = _unwrap(raw);

    // limits
    final rawLimits = _v(j, 'limits', 'Limits');
    final limits = rawLimits is Map
        ? SubscriptionLimits.fromJson(Map<String, dynamic>.from(rawLimits))
        : const SubscriptionLimits();

    // entitlements (OR-merge with limits)
    final rawEnt = _v(j, 'entitlements', 'Entitlements');
    final entitlements = SubscriptionEntitlements.merge(
      rawEnt is Map ? Map<String, dynamic>.from(rawEnt) : null,
      limits,
    );

    String currency = (_v(j, 'currency', 'Currency') ?? 'VND').toString();
    if (currency.trim().isEmpty) currency = 'VND';

    return MySubscription(
      planCode:   (_v(j, 'planCode',   'PlanCode')   ?? 'HR_FREE').toString(),
      planName:   (_v(j, 'planName',   'PlanName')   ?? 'Free').toString(),
      audience:   (_v(j, 'audience',   'Audience')   ?? 'HR').toString(),
      status:     (_v(j, 'status',     'Status')     ?? 'active').toString(),
      priceMonthly: ((_v(j, 'priceMonthly', 'PriceMonthly') ?? 0) as num),
      currency:   currency,
      periodStart: (_v(j, 'periodStart', 'PeriodStart') ?? '').toString(),
      periodEnd:   (_v(j, 'periodEnd',   'PeriodEnd')   ?? '').toString(),
      lastSuccessfulGenerateAt: _v(j, 'lastSuccessfulGenerateAt', 'LastSuccessfulGenerateAt')?.toString(),
      limits:      limits,
      askAiUsed:   ((_v(j, 'askAiUsed',   'AskAiUsed')   ?? 0) as num).toInt(),
      askAiLimit:  ((_v(j, 'askAiLimit',  'AskAiLimit')  ?? 0) as num).toInt(),
      generateSetUsed: ((_v(j, 'generateSetUsed', 'GenerateSetUsed') ?? 0) as num).toInt(),
      entitlements: entitlements,
    );
  }

  MySubscription copyWith({int? askAiUsed, int? askAiLimit}) => MySubscription(
        planCode:    planCode,
        planName:    planName,
        audience:    audience,
        status:      status,
        priceMonthly: priceMonthly,
        currency:    currency,
        periodStart: periodStart,
        periodEnd:   periodEnd,
        lastSuccessfulGenerateAt: lastSuccessfulGenerateAt,
        limits:      limits,
        askAiUsed:   askAiUsed  ?? this.askAiUsed,
        askAiLimit:  askAiLimit ?? this.askAiLimit,
        generateSetUsed: generateSetUsed,
        entitlements: entitlements,
      );
}

// ── §11 UpgradePaymentIntent ──────────────────────────────────────────────────

class UpgradePaymentIntent {
  final String orderCode;
  final String provider;
  final num amount;
  final String currency;
  final String status;
  final String expiresAt;
  final String? paymentUrl;
  final String? qrContent;
  final String? qrImageUrl;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? transferContent;

  const UpgradePaymentIntent({
    required this.orderCode,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.status,
    required this.expiresAt,
    this.paymentUrl,
    this.qrContent,
    this.qrImageUrl,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    this.transferContent,
  });

  factory UpgradePaymentIntent.fromJson(dynamic raw) {
    final j = _unwrap(raw);
    return UpgradePaymentIntent(
      orderCode:         (_v(j, 'orderCode',         'OrderCode')         ?? '').toString(),
      provider:          (_v(j, 'provider',          'Provider')          ?? 'SePay').toString(),
      amount:            ((_v(j, 'amount',           'Amount')            ?? 0) as num),
      currency:          (_v(j, 'currency',          'Currency')          ?? 'VND').toString(),
      status:            (_v(j, 'status',            'Status')            ?? 'Pending').toString(),
      expiresAt:         (_v(j, 'expiresAt',         'ExpiresAt')         ?? '').toString(),
      paymentUrl:        _v(j, 'paymentUrl',         'PaymentUrl')?.toString(),
      qrContent:         _v(j, 'qrContent',          'QrContent')?.toString(),
      qrImageUrl:        _v(j, 'qrImageUrl',         'QrImageUrl')?.toString(),
      bankName:          _v(j, 'bankName',           'BankName')?.toString(),
      bankAccountName:   _v(j, 'bankAccountName',   'BankAccountName')?.toString(),
      bankAccountNumber: _v(j, 'bankAccountNumber', 'BankAccountNumber')?.toString(),
      transferContent:   _v(j, 'transferContent',   'TransferContent')?.toString(),
    );
  }

  UpgradePaymentIntent mergeStatus(String newStatus) => UpgradePaymentIntent(
        orderCode:         orderCode,
        provider:          provider,
        amount:            amount,
        currency:          currency,
        status:            newStatus,
        expiresAt:         expiresAt,
        paymentUrl:        paymentUrl,
        qrContent:         qrContent,
        qrImageUrl:        qrImageUrl,
        bankName:          bankName,
        bankAccountName:   bankAccountName,
        bankAccountNumber: bankAccountNumber,
        transferContent:   transferContent,
      );
}

// ── §5.4 Cooldown helper ──────────────────────────────────────────────────────

({bool canGenerateNow, DateTime? cooldownEndsAt}) _calcCooldown(
    MySubscription? sub) {
  if (sub == null) return (canGenerateNow: true, cooldownEndsAt: null);
  final limits = sub.limits;
  final lastRaw = sub.lastSuccessfulGenerateAt;
  if (!limits.generateUnlimited && lastRaw != null && lastRaw.isNotEmpty) {
    try {
      final last = DateTime.parse(lastRaw).toLocal();
      final endsAt = last.add(Duration(hours: limits.generateCooldownHours));
      if (endsAt.isAfter(DateTime.now())) {
        return (canGenerateNow: false, cooldownEndsAt: endsAt);
      }
    } catch (_) {}
  }
  return (canGenerateNow: true, cooldownEndsAt: null);
}

// ── State ─────────────────────────────────────────────────────────────────────

class SubscriptionState {
  final MySubscription? subscription; // null = not yet loaded
  final bool isLoading;
  final String? error;
  final bool canGenerateNow;
  final DateTime? cooldownEndsAt;

  const SubscriptionState({
    this.subscription,
    this.isLoading = true,
    this.error,
    this.canGenerateNow = true,
    this.cooldownEndsAt,
  });

  /// §5.5 — MUST use `subscription != null`, NOT `!isLoading`
  bool get quotaBlocked => subscription != null && !canGenerateNow;

  bool get isPremium => subscription?.isPremium ?? false;

  SubscriptionState copyWith({
    MySubscription? subscription,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? canGenerateNow,
    DateTime? cooldownEndsAt,
    bool clearCooldown = false,
  }) =>
      SubscriptionState(
        subscription:   subscription  ?? this.subscription,
        isLoading:      isLoading     ?? this.isLoading,
        error:          clearError    ? null : (error ?? this.error),
        canGenerateNow: canGenerateNow ?? this.canGenerateNow,
        cooldownEndsAt: clearCooldown ? null : (cooldownEndsAt ?? this.cooldownEndsAt),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = buildGenerationDio();
      final res = await dio.get('/api/me/subscription');
      final sub = MySubscription.fromJson(res.data);
      final cd  = _calcCooldown(sub);
      state = state.copyWith(
        subscription:   sub,
        isLoading:      false,
        canGenerateNow: cd.canGenerateNow,
        cooldownEndsAt: cd.cooldownEndsAt,
        clearCooldown:  cd.canGenerateNow,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     _err(e),
      );
    }
  }

  /// Refresh without clearing existing data (§5.5 — keeps old sub visible)
  Future<void> refresh() async {
    final hadData = state.subscription != null;
    if (!hadData) { await load(); return; }
    // Don't set isLoading: true — keeps old data visible during refresh
    try {
      final dio = buildGenerationDio();
      final res = await dio.get('/api/me/subscription');
      final sub = MySubscription.fromJson(res.data);
      final cd  = _calcCooldown(sub);
      state = state.copyWith(
        subscription:   sub,
        canGenerateNow: cd.canGenerateNow,
        cooldownEndsAt: cd.cooldownEndsAt,
        clearCooldown:  cd.canGenerateNow,
      );
    } catch (_) {
      // Silent — keep stale data
    }
  }

  /// §11.3 Initiate upgrade payment
  Future<UpgradePaymentIntent?> upgrade() async {
    try {
      final dio = buildGenerationDio();
      final res = await dio.post('/api/me/subscription/upgrade', data: {});
      return UpgradePaymentIntent.fromJson(res.data);
    } catch (e) {
      state = state.copyWith(error: _err(e));
      return null;
    }
  }

  /// §11.3 Poll order status
  Future<String?> checkOrderStatus(String orderCode) async {
    try {
      final dio = buildGenerationDio();
      final res = await dio.get('/api/me/subscription/upgrade/$orderCode');
      final j   = _unwrap(res.data);
      return (_v(j, 'status', 'Status') ?? '').toString();
    } catch (_) {
      return null;
    }
  }

  /// §11.7 Cancel subscription — response is new MySubscription
  Future<bool> cancelSubscription() async {
    try {
      final dio = buildGenerationDio();
      final res = await dio.post('/api/me/subscription/cancel');
      final sub = MySubscription.fromJson(res.data);
      final cd  = _calcCooldown(sub);
      state = state.copyWith(
        subscription:   sub,
        canGenerateNow: cd.canGenerateNow,
        cooldownEndsAt: cd.cooldownEndsAt,
        clearCooldown:  cd.canGenerateNow,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: _err(e));
      return false;
    }
  }

  /// §11.7 Buy Ask-AI pack — response is new MySubscription
  Future<bool> purchaseAskAiPack() async {
    try {
      final dio = buildGenerationDio();
      final res = await dio.post(
        '/api/me/packs/ask-ai',
        data: {'extraRequests': 200, 'amount': 99000},
      );
      final sub = MySubscription.fromJson(res.data);
      final cd  = _calcCooldown(sub);
      state = state.copyWith(
        subscription:   sub,
        canGenerateNow: cd.canGenerateNow,
        cooldownEndsAt: cd.cooldownEndsAt,
        clearCooldown:  cd.canGenerateNow,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: _err(e));
      return false;
    }
  }

  /// Called after successful generation to trigger cooldown refresh
  Future<void> onGenerationSuccess() => refresh();

  void clearError() => state = state.copyWith(clearError: true);

  static String _err(Object e) {
    if (e is DioException) {
      final body = e.response?.data;
      if (body is Map) {
        final msg = body['message'] ?? body['error'] ?? body['detail'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    }
    return e.toString();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
        (_) => SubscriptionNotifier());

/// Alias kept for backward compat with existing usages
final mySubscriptionProvider = subscriptionProvider;

final canGenerateNowProvider =
    Provider<bool>((ref) => ref.watch(subscriptionProvider).canGenerateNow);

final cooldownEndsAtProvider =
    Provider<DateTime?>((ref) => ref.watch(subscriptionProvider).cooldownEndsAt);

/// §5.6 feature flags
final hasFeatureProvider = Provider.family<bool, String>((ref, featureId) {
  final limits = ref.watch(subscriptionProvider).subscription?.limits;
  if (limits == null) return false;
  switch (featureId) {
    case 'export':            return limits.canExport;
    case 'askAi':             return limits.askAiPerMonth > 0;
    case 'publish':           return limits.canPublish;
    case 'unlimitedGenerate': return limits.generateUnlimited;
    default:                  return false;
  }
});

// ── QuotaWarningBanner ────────────────────────────────────────────────────────

class QuotaWarningBanner extends ConsumerWidget {
  const QuotaWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionProvider);
    final sub   = state.subscription;

    if (sub == null) return const SizedBox.shrink();
    if (sub.isPremium) return const SizedBox.shrink();

    final isBlocked = state.quotaBlocked;
    final color = isBlocked ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

    String msg;
    if (isBlocked) {
      if (state.cooldownEndsAt != null) {
        final rem = state.cooldownEndsAt!.difference(DateTime.now());
        final h = rem.inHours;
        final m = rem.inMinutes % 60;
        msg = 'Gói Free: chờ $h giờ $m phút hoặc nâng Premium để tạo tiếp.';
      } else {
        msg = 'Bạn đã hết lượt tạo câu hỏi trong kỳ này.';
      }
    } else {
      msg = 'Gói Free: còn ${ sub.limits.generateCooldownHours }h cooldown giữa các lần tạo.';
      return const SizedBox.shrink(); // only show when blocked or near limit
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(isBlocked ? Icons.block_rounded : Icons.warning_amber_rounded,
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: TextStyle(color: color, fontSize: 12, height: 1.4)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/hr/subscription'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Nâng cấp',
                  style: TextStyle(
                      color:      color,
                      fontSize:   11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PlanBadgeWidget ───────────────────────────────────────────────────────────

class PlanBadgeWidget extends ConsumerWidget {
  final double fontSize;
  const PlanBadgeWidget({super.key, this.fontSize = 10});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionProvider);
    final sub   = state.subscription;
    if (sub == null) return const SizedBox.shrink();

    final isPremium = sub.isPremium;
    final color     = isPremium ? const Color(0xFF6C47FF) : const Color(0xFF9CA3AF);
    final label     = isPremium ? 'Premium' : 'Free';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color:      color,
            fontSize:   fontSize,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── showQuotaDialog (backward compat) ─────────────────────────────────────────

Future<void> showQuotaDialog(BuildContext context,
    {String trigger = 'generate'}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _QuotaDialog(trigger: trigger),
  );
}

class _QuotaDialog extends ConsumerWidget {
  final String trigger;
  const _QuotaDialog({required this.trigger});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sub    = state.subscription;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C47FF), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              state.quotaBlocked
                  ? 'Đang trong thời gian cooldown'
                  : 'Đã hết lượt tạo câu hỏi',
              style: TextStyle(
                  color:      isDark ? Colors.white : const Color(0xFF111827),
                  fontSize:   20,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _message(state),
              style: TextStyle(
                  color:    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  fontSize: 13,
                  height:   1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!(sub?.isPremium ?? false)) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/hr/subscription');
                  },
                  icon:  const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Nâng cấp lên Premium'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng',
                  style: TextStyle(
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF))),
            ),
          ],
        ),
      ),
    );
  }

  String _message(SubscriptionState state) {
    if (state.cooldownEndsAt != null) {
      final rem = state.cooldownEndsAt!.difference(DateTime.now());
      final h   = rem.inHours;
      final m   = rem.inMinutes % 60;
      return 'Gói Free chỉ tạo bộ câu hỏi 1 lần / ${state.subscription?.limits.generateCooldownHours ?? 24} giờ.\n'
          'Còn ${h}h ${m}m. Vui lòng đợi hoặc nâng cấp Premium.';
    }
    return 'Bạn đã sử dụng hết lượt tạo câu hỏi trong kỳ này.\nNâng cấp để tạo không giới hạn.';
  }
}

// ── Premium congratulation dialog §11.6 ──────────────────────────────────────

Future<void> maybeShowPremiumDialog(
    BuildContext context, String userId, String? planCode) async {
  if (!(planCode ?? '').toUpperCase().contains('PREMIUM')) return;
  final prefs = await SharedPreferences.getInstance();
  final key   = 'hiregen_hr_premium_ok_$userId';
  if (prefs.containsKey(key)) return;
  await prefs.setString(key, '1');
  if (!context.mounted) return;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PremiumCongratDialog(),
  );
}

class _PremiumCongratDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C47FF), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            Text('Chào mừng Premium!',
                style: TextStyle(
                    color:      isDark ? Colors.white : const Color(0xFF111827),
                    fontSize:   24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              'Bạn đã mở khoá toàn bộ tính năng HireGen AI.\n'
              'Tạo bộ câu hỏi không giới hạn, export PDF/DOCX,\nAsk-AI không giới hạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color:  isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  fontSize: 13,
                  height:   1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C47FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Bắt đầu ngay',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
