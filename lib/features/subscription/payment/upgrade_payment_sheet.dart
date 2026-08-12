import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../subscription_provider.dart' show UpgradePaymentIntent;

// ── Unified status sets (spec §2 + §8.1) ─────────────────────────────────────

const kPaymentSuccess = {'PAID', 'FREE', 'COMPLETED', 'CONFIRMED'};
const kPaymentFail    = {'EXPIRED', 'FAILED', 'CANCELLED', 'CANCELED'};

// HR poll interval per spec §5.2 (web: 3 s)
const kHrPollInterval        = Duration(seconds: 3);
// Candidate poll fallback per spec §5.3 (web: 15 s)
const kCandidatePollInterval = Duration(seconds: 15);

// ── PaymentWaitConfig — injected by each caller ───────────────────────────────

/// Async function to check a single order status; returns null on network error.
typedef CheckStatusFn    = Future<String?> Function(String orderCode);
/// Async function to refresh the subscription after payment succeeds.
typedef RefreshAfterPaidFn = Future<void> Function();
/// Callback to show the celebration dialog in the appropriate context.
typedef CelebrationFn    = void Function(BuildContext ctx);

class PaymentWaitConfig {
  /// HR = [kHrPollInterval] (3 s) | Candidate = [kCandidatePollInterval] (15 s).
  final Duration         pollInterval;
  final CheckStatusFn    checkStatus;
  final RefreshAfterPaidFn onPaidRefresh;
  final CelebrationFn    onCelebration;
  /// Optional: spawn a fresh upgrade order (web "Tạo đơn mới").
  /// Returns the new [UpgradePaymentIntent] or null on failure.
  final Future<UpgradePaymentIntent?> Function()? onCreateNewOrder;

  const PaymentWaitConfig({
    required this.pollInterval,
    required this.checkStatus,
    required this.onPaidRefresh,
    required this.onCelebration,
    this.onCreateNewOrder,
  });
}

// ── UpgradePaymentSheet ───────────────────────────────────────────────────────

class UpgradePaymentSheet extends StatefulWidget {
  final UpgradePaymentIntent intent;
  final PaymentWaitConfig    config;

  const UpgradePaymentSheet({
    super.key,
    required this.intent,
    required this.config,
  });

  @override
  State<UpgradePaymentSheet> createState() => _UpgradePaymentSheetState();
}

class _UpgradePaymentSheetState extends State<UpgradePaymentSheet>
    with WidgetsBindingObserver {

  late UpgradePaymentIntent _intent;
  DateTime?                 _expiresAt;
  Timer?                    _pollTimer;
  bool                      _finishing = false;
  bool                      _polling   = false;
  bool                      _creating  = false;

  bool get _isFreeOrder => _intent.amount <= 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _intent = widget.intent;

    try {
      _expiresAt = _intent.expiresAt.isEmpty
          ? null
          : DateTime.parse(_intent.expiresAt).toLocal();
    } catch (_) {
      _expiresAt = null;
    }

    if (!_isFreeOrder) {
      _pollOnce();                                    // immediate first check
      _pollTimer = Timer.periodic(widget.config.pollInterval, (_) => _pollOnce());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── App lifecycle (spec §5.6) ─────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isFreeOrder || _finishing) return;
    switch (state) {
      case AppLifecycleState.resumed:
        // Recalculate countdown from expiresAt and poll once immediately
        _pollOnce();
        _pollTimer?.cancel();
        _pollTimer = Timer.periodic(widget.config.pollInterval, (_) => _pollOnce());
        break;
      case AppLifecycleState.paused:
        _pollTimer?.cancel();
        break;
      default:
        break;
    }
  }

  // ── Polling (spec §5.2 HR / §5.3 Candidate) ──────────────────────────────

  Future<void> _pollOnce() async {
    if (_polling || _finishing || !mounted) return;
    _polling = true;
    final status = await widget.config.checkStatus(_intent.orderCode);
    _polling = false;
    if (!mounted || status == null) return;

    // applyStatusOnly — never overwrite QR/bank fields (spec §4.3)
    if (status != _intent.status) {
      setState(() => _intent = _intent.mergeStatus(status));
    }

    final upper = status.toUpperCase();
    if (kPaymentSuccess.contains(upper)) {
      await _finishPaid();
    } else if (kPaymentFail.contains(upper)) {
      _pollTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:  Text('Đơn thanh toán đã hết hạn hoặc bị huỷ.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Free-order activation (spec §5.4) ─────────────────────────────────────

  Future<void> _handleFreeActivate() async {
    if (_finishing) return;
    try {
      await widget.config.onPaidRefresh();
      await _finishPaid();
    } catch (_) {
      // Sub refresh failed → try order status once
      final status = await widget.config.checkStatus(_intent.orderCode);
      if (status != null && kPaymentSuccess.contains(status.toUpperCase())) {
        await _finishPaid();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:  Text('Đang chờ xác nhận. Vui lòng thử lại sau vài giây.'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  // ── finishPaid (spec §6.1) — single, guarded entry point ─────────────────

  Future<void> _finishPaid() async {
    if (_finishing) return;
    _finishing = true;
    _pollTimer?.cancel();

    try {
      await widget.config.onPaidRefresh();
    } catch (_) {
      // Refresh failed — unlock and let user retry via poll
      _finishing = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:  Text('Làm mới gói thất bại. Đơn đã thanh toán, vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content:         Text('Thanh toán thành công! Chào mừng Premium. 🎉'),
      behavior:        SnackBarBehavior.floating,
      backgroundColor: Color(0xFF6C47FF),
    ));

    // Defer celebration slightly so the sheet closes first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.config.onCelebration(context);
    });
  }

  // ── Create new order (web "Tạo đơn mới") ─────────────────────────────────

  Future<void> _handleCreateNewOrder() async {
    if (_creating || _finishing) return;
    setState(() => _creating = true);
    try {
      final newIntent = await widget.config.onCreateNewOrder!();
      if (!mounted) return;
      if (newIntent == null) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:  Text('Không thể tạo đơn mới. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      // Swap to the new intent and restart the polling cycle
      _pollTimer?.cancel();
      _finishing = false;
      _polling   = false;
      setState(() {
        _intent   = newIntent;
        _creating = false;
        try {
          _expiresAt = newIntent.expiresAt.isEmpty
              ? null
              : DateTime.parse(newIntent.expiresAt).toLocal();
        } catch (_) {
          _expiresAt = null;
        }
      });
      if (!_isFreeOrder) {
        _pollOnce();
        _pollTimer =
            Timer.periodic(widget.config.pollInterval, (_) => _pollOnce());
      }
    } catch (_) {
      if (mounted) setState(() => _creating = false);
    }
  }

  // ── Countdown helpers (spec §5.5 — always computed from expiresAt) ────────

  int get _secsLeft {
    if (_expiresAt == null) return 0;
    final rem = _expiresAt!.difference(DateTime.now());
    return rem.isNegative ? 0 : rem.inSeconds;
  }

  Color _countdownColor(int secs) {
    if (secs == 0)   return Colors.grey;
    if (secs <= 30)  return const Color(0xFFEF4444);
    if (secs <= 120) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  static String _fmtSecs(int s) {
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  // ── Status chip ───────────────────────────────────────────────────────────

  String get _statusLabel {
    final u = _intent.status.toUpperCase();
    if (kPaymentSuccess.contains(u)) return 'Đã thanh toán ✓';
    if (kPaymentFail.contains(u))    return 'Hết hạn / Huỷ';
    return 'Chờ thanh toán';
  }

  Color get _statusColor {
    final u = _intent.status.toUpperCase();
    if (kPaymentSuccess.contains(u)) return const Color(0xFF10B981);
    if (kPaymentFail.contains(u))    return const Color(0xFFEF4444);
    return const Color(0xFFF59E0B);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF111827) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Handle bar
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color:        isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Thanh toán nâng cấp Premium',
                style: TextStyle(
                  color:      isDark ? Colors.white : const Color(0xFF111827),
                  fontSize:   18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),

              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color:        _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: _statusColor.withValues(alpha: 0.30)),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                      color:      _statusColor,
                      fontSize:   12,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 20),

              // Amount strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B35E8), Color(0xFF7C5CFC)],
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text('Số tiền',
                        style: TextStyle(
                            color:    Colors.white.withValues(alpha: 0.70),
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _isFreeOrder
                          ? 'Miễn phí'
                          : '₫${_fmtNum(_intent.amount)}',
                      style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   26,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Free order: one-tap activation (spec §5.4) ────────────────
              if (_isFreeOrder) ...[
                _FreeActivatePanel(
                  onActivate: _handleFreeActivate,
                  isDark:     isDark,
                ),

              // ── Paid order: QR → countdown → bank info ────────────────────
              ] else ...[
                // QR: tier 1 → qrContent; tier 2 → qrImageUrl; tier 3 → text
                _QrPanel(intent: _intent, isDark: isDark),
                const SizedBox(height: 16),

                // Countdown (spec §5.5 — computed from expiresAt each tick)
                if (_expiresAt != null)
                  StreamBuilder<int>(
                    stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                    builder: (_, __) {
                      final secs  = _secsLeft;
                      final color = _countdownColor(secs);
                      return Column(
                        children: [
                          Text(
                            _fmtSecs(secs),
                            style: TextStyle(
                              color:         color,
                              fontSize:      32,
                              fontWeight:    FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thời gian còn lại',
                            style: TextStyle(
                                color:    isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF),
                                fontSize: 11),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 20),

                // Bank transfer info
                _BankTransferCard(intent: _intent, isDark: isDark),
              ],

              const SizedBox(height: 16),

              // Close (+ optional "Tạo đơn mới") buttons
              if (!_isFreeOrder && widget.config.onCreateNewOrder != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white60
                              : const Color(0xFF6B7280),
                          side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text('Đóng',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _creating
                          ? const SizedBox(
                              height: 48,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : FilledButton(
                              onPressed: _handleCreateNewOrder,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6C47FF),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                              ),
                              child: const Text('Tạo đơn mới',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.white60
                          : const Color(0xFF6B7280),
                      side: BorderSide(
                          color: isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Đóng',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Free-order activation panel (spec §5.4) ───────────────────────────────────

class _FreeActivatePanel extends StatelessWidget {
  final VoidCallback onActivate;
  final bool         isDark;
  const _FreeActivatePanel({required this.onActivate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        isDark ? const Color(0xFF1F2937) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 52, color: Color(0xFF10B981)),
          const SizedBox(height: 12),
          Text(
            'Gói của bạn đã được kích hoạt miễn phí.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color:      isDark ? Colors.white : const Color(0xFF111827),
                fontSize:   14,
                fontWeight: FontWeight.w600,
                height:     1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onActivate,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Kích hoạt ngay',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── QR panel — three-tier fallback (spec §4.1) ────────────────────────────────

class _QrPanel extends StatelessWidget {
  final UpgradePaymentIntent intent;
  final bool                 isDark;
  const _QrPanel({required this.intent, required this.isDark});

  static const _boxDecor = BoxDecoration(
    color:        Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: [
      BoxShadow(
        color:      Color(0x1A000000), // black @ 10 %
        blurRadius: 10,
        offset:     Offset(0, 3),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final qrImg = intent.qrImageUrl;
    final qr    = intent.qrContent;

    // ── Tier 1 — qrImageUrl ──────────────────────────────────────────────────
    // SePay renders a proper VietQR image on its server (EMVCo-compliant,
    // bank-scannable).  Always prefer this over a locally generated QR.
    if (qrImg != null && qrImg.isNotEmpty) {
      return Column(
        children: [
          Container(
            padding:    const EdgeInsets.all(14),
            decoration: _boxDecor,
            child: Image.network(
              qrImg,
              width: 200, height: 200,
              fit:   BoxFit.contain,
              // Show a spinner while the image loads
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      width: 200, height: 200,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2))),
              // On network failure → fall back to local QR (Tier 2)
              errorBuilder: (_, __, ___) => qr != null && qr.isNotEmpty
                  ? QrImageView(data: qr, size: 200)
                  : const Icon(Icons.qr_code_scanner_rounded,
                      size: 80, color: Color(0xFF6C47FF)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan mã QR bằng app ngân hàng',
            style: TextStyle(
                color:    isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                fontSize: 12),
          ),
        ],
      );
    }

    // ── Tier 2 — qrContent local render ─────────────────────────────────────
    // Only reached when qrImageUrl is absent.
    // qrContent may or may not be a valid VietQR string — use as best-effort.
    if (qr != null && qr.isNotEmpty) {
      return Column(
        children: [
          Container(
            padding:    const EdgeInsets.all(14),
            decoration: _boxDecor,
            child: QrImageView(data: qr, size: 200),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan mã QR bằng app ngân hàng',
            style: TextStyle(
                color:    isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
                fontSize: 12),
          ),
        ],
      );
    }

    // ── Tier 3 — text fallback + copy ────────────────────────────────────────
    return _QrTextFallback(
      text:   intent.transferContent ?? intent.orderCode,
      isDark: isDark,
    );
  }
}

// ── QR text fallback (spec §4.1 tier 3) ──────────────────────────────────────

class _QrTextFallback extends StatelessWidget {
  final String text;
  final bool   isDark;
  const _QrTextFallback({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(
          color:  isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width:  1.5,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_rounded, size: 36, color: Color(0xFF6C47FF)),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color:      isDark ? Colors.white : const Color(0xFF111827),
                fontSize:   13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:  Text('Đã copy nội dung chuyển khoản'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
              ));
            },
            icon:  const Icon(Icons.copy_rounded,
                size: 14, color: Color(0xFF6C47FF)),
            label: const Text('Sao chép',
                style: TextStyle(color: Color(0xFF6C47FF), fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Bank transfer info card (spec §4.2) ───────────────────────────────────────

class _BankTransferCard extends StatelessWidget {
  final UpgradePaymentIntent intent;
  final bool                 isDark;
  const _BankTransferCard({required this.intent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // transferContent ?? orderCode is the canonical copy target (spec §4.2)
    final rows = <MapEntry<String, String>>[
      if (intent.bankName?.isNotEmpty == true)
        MapEntry('Ngân hàng',             intent.bankName!),
      if (intent.bankAccountNumber?.isNotEmpty == true)
        MapEntry('Số tài khoản',          intent.bankAccountNumber!),
      if (intent.bankAccountName?.isNotEmpty == true)
        MapEntry('Chủ tài khoản',         intent.bankAccountName!),
      MapEntry(
        'Nội dung chuyển khoản',
        (intent.transferContent?.isNotEmpty == true)
            ? intent.transferContent!
            : intent.orderCode,
      ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
            color: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: rows
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.key,
                                style: TextStyle(
                                    color:    isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                    fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(e.value,
                                style: TextStyle(
                                    color:      isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                    fontSize:   13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: e.value));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:  Text('Đã copy ${e.key}'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:        const Color(0xFF6C47FF)
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.copy_rounded,
                              size: 14, color: Color(0xFF6C47FF)),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Format helper ─────────────────────────────────────────────────────────────

String _fmtNum(num v) {
  final s   = v.toInt().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
