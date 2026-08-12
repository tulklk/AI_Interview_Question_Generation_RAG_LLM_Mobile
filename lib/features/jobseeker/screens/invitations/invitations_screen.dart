import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../models/jobseeker_models.dart';
import '../../providers/jobseeker_providers.dart';

const _kPrimary  = Color(0xFF6C47FF);
const _kAmber    = Color(0xFFF59E0B);
const _kGreen    = Color(0xFF10B981);
const _kGray     = Color(0xFF6B7280);

class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state  = ref.watch(invitationsProvider);

    final bg      = AppColors.surfaceBg(isDark);
    final textPri = AppColors.textPrimary(isDark);
    final textSub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lời mời phỏng vấn',
                          style: TextStyle(
                            color: textPri,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${state.invitations.length} lời mời',
                          style: TextStyle(color: textSub, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (state.isLoading)
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, color: textSub),
                      onPressed: () => ref.read(invitationsProvider.notifier).load(),
                    ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),

            const SizedBox(height: 12),

            // ── Tab bar ───────────────────────────────────────────────────────
            _TabBar(state: state, isDark: isDark),

            const SizedBox(height: 8),

            // ── Body ──────────────────────────────────────────────────────────
            Expanded(
              child: _Body(
                state:   state,
                isDark:  isDark,
                textPri: textPri,
                textSub: textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _TabBar extends ConsumerWidget {
  final InvitationsState state;
  final bool isDark;
  const _TabBar({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = [
      _TabItem('all',      'Tất cả',          state.invitations.length, _kPrimary),
      _TabItem('pending',  'Chờ phản hồi',    state.pendingCount,       _kAmber),
      _TabItem('accepted', 'Đã nhận',         state.acceptedCount,      _kGreen),
      _TabItem('rejected', 'Đã từ chối',      state.rejectedCount,      _kGray),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tab    = tabs[i];
          final active = state.activeTab == tab.key;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(invitationsProvider.notifier).setTab(tab.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? tab.color.withValues(alpha: 0.15)
                    : isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? tab.color.withValues(alpha: 0.5)
                      : isDark ? AppColors.darkChip : AppColors.gray200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: active ? tab.color : _kGray,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (tab.count > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: active ? tab.color : _kGray.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tab.count}',
                        style: TextStyle(
                          color: active ? Colors.white : _kGray,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabItem {
  final String key, label;
  final int count;
  final Color color;
  const _TabItem(this.key, this.label, this.count, this.color);
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final InvitationsState state;
  final bool isDark;
  final Color textPri, textSub;
  const _Body({required this.state, required this.isDark, required this.textPri, required this.textSub});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.invitations.isEmpty) {
      return _Skeleton(isDark: isDark);
    }

    if (state.error != null && state.invitations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 56,
                color: isDark ? const Color(0xFF4A5578) : const Color(0xFF9CA3AF)),
              const SizedBox(height: 16),
              Text('Không tải được', style: TextStyle(color: textPri, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(state.error!, style: TextStyle(color: textSub, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => ref.read(invitationsProvider.notifier).load(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = state.paged;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mail_outline_rounded, color: _kPrimary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Không có lời mời nào',
              style: TextStyle(color: textPri, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhà tuyển dụng sẽ gửi lời mời tại đây\nkhi họ muốn bạn thực hành.',
              style: TextStyle(color: textSub, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms);
    }

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () => ref.read(invitationsProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        itemCount: items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == items.length) {
            return Center(
              child: TextButton(
                onPressed: () => ref.read(invitationsProvider.notifier).loadMore(),
                child: const Text('Xem thêm', style: TextStyle(color: _kPrimary)),
              ),
            );
          }
          return _InvitationCard(
            key:     ValueKey(items[i].id),
            inv:     items[i],
            index:   i,
            isDark:  isDark,
            textPri: textPri,
            textSub: textSub,
          );
        },
      ),
    );
  }
}

// ── Invitation card ───────────────────────────────────────────────────────────

class _InvitationCard extends ConsumerWidget {
  final Invitation inv;
  final int index;
  final bool isDark;
  final Color textPri, textSub;

  const _InvitationCard({
    super.key,
    required this.inv,
    required this.index,
    required this.isDark,
    required this.textPri,
    required this.textSub,
  });

  Color get _statusColor {
    switch (inv.status) {
      case InvitationStatus.accepted: return _kGreen;
      case InvitationStatus.rejected: return _kGray;
      case InvitationStatus.pending:  return _kAmber;
    }
  }

  String get _statusLabel {
    switch (inv.status) {
      case InvitationStatus.accepted: return 'Đã nhận';
      case InvitationStatus.rejected: return 'Đã từ chối';
      case InvitationStatus.pending:  return 'Chờ phản hồi';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final border  = isDark ? AppColors.darkChip : AppColors.gray200;
    final opacity = inv.status == InvitationStatus.rejected ? 0.55 : 1.0;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showDetailSheet(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Company avatar ─────────────────────────────────────────
              _CompanyAvatar(
                size:     44,
                radius:   11,
                logoUrl:  inv.companyLogo,
                initials: inv.companyInitials,
                color:    inv.companyColor,
              ),
              const SizedBox(width: 12),

              // ── Company + position + time ──────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.company,
                      style: TextStyle(
                        color: textPri,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inv.questionSetTitle,
                      style: TextStyle(color: textSub, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(inv.invitedAt),
                      style: TextStyle(
                        color: textSub.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Status + detail button ─────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        color: _kPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.04, end: 0);
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : AppColors.white;
    final textPri = AppColors.textPrimary(isDark);
    final textSub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final border  = isDark ? AppColors.darkChip : AppColors.gray200;

    // Slide nav bar off-screen while sheet is open
    ref.read(navBarHiddenProvider.notifier).state = true;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        maxChildSize: 0.92,
        builder: (ctx, ctrl) => Column(
          children: [
            // ── Drag handle ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // ── Scrollable body ──────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // Company header
                  Row(
                    children: [
                      _CompanyAvatar(
                        size:     48,
                        radius:   12,
                        logoUrl:  inv.companyLogo,
                        initials: inv.companyInitials,
                        color:    inv.companyColor,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inv.company,
                              style: TextStyle(
                                color: textPri,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _relativeTime(inv.invitedAt),
                              style: TextStyle(color: textSub, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Info card ───────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.menu_book_rounded,
                          iconColor: _kPrimary,
                          label: 'Bộ câu hỏi',
                          value: inv.questionSetTitle,
                          textPri: textPri, textSub: textSub,
                          border: border,
                          showDivider: true,
                        ),
                        if (inv.totalQuestions > 0)
                          _InfoRow(
                            icon: Icons.quiz_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            label: 'Số câu hỏi',
                            value: '${inv.totalQuestions} câu hỏi',
                            textPri: textPri, textSub: textSub,
                            border: border,
                            showDivider: true,
                          ),
                        _InfoRow(
                          icon: Icons.schedule_rounded,
                          iconColor: _kAmber,
                          label: 'Thời gian mời',
                          value: DateFormat('dd/MM/yyyy – HH:mm').format(inv.invitedAt),
                          textPri: textPri, textSub: textSub,
                          border: border,
                          showDivider: inv.respondedAt != null,
                        ),
                        if (inv.respondedAt != null)
                          _InfoRow(
                            icon: Icons.check_circle_rounded,
                            iconColor: _kGreen,
                            label: 'Đã phản hồi',
                            value: DateFormat('dd/MM/yyyy – HH:mm').format(inv.respondedAt!),
                            textPri: textPri, textSub: textSub,
                            border: border,
                            showDivider: false,
                          ),
                      ],
                    ),
                  ),

                  // ── HR message card ─────────────────────────────────────
                  if (inv.hrNote != null && inv.hrNote!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _HrMessageCard(
                      message: inv.hrNote!,
                      isDark: isDark,
                      textPri: textPri,
                      textSub: textSub,
                      border: border,
                    ),
                  ],

                  // ── Candidate response card ─────────────────────────────
                  if (inv.responseMessage != null && inv.responseMessage!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ResponseCard(
                      message: inv.responseMessage!,
                      isDark: isDark,
                      textPri: textPri,
                      textSub: textSub,
                      border: border,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // "Xem bộ câu hỏi" button
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      context.push('/jobseeker/sets/${inv.questionSetId}');
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: const Text('Xem bộ câu hỏi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),

                  // Accept / Reject actions (pending only)
                  if (inv.status == InvitationStatus.pending) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              _confirmReject(context, ref);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(color: Color(0xFFEF4444)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Từ chối',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              _showAcceptDialog(context, ref);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _kPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Chấp nhận',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Restore nav bar when sheet is dismissed (swipe, tap outside, or button)
      if (context.mounted) {
        ref.read(navBarHiddenProvider.notifier).state = false;
      }
    });
  }

  void _showAcceptDialog(BuildContext context, WidgetRef ref) {
    final msgCtrl   = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool phoneTouched = false;
    final formKey   = GlobalKey<FormState>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final textPri = AppColors.textPrimary(isDark);
    final textSub = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final fieldFill = isDark ? AppColors.darkCard : const Color(0xFFF9FAFB);
    final border = isDark ? AppColors.darkChip : AppColors.gray200;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Chấp nhận lời mời',
              style: TextStyle(color: textPri, fontWeight: FontWeight.w800)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lời nhắn cho nhà tuyển dụng (không bắt buộc)',
                    style: TextStyle(color: textSub, fontSize: 12)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: msgCtrl,
                  maxLength: 2000,
                  maxLines: 3,
                  style: TextStyle(color: textPri, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cảm ơn bạn đã mời…',
                    hintStyle: TextStyle(color: textSub.withValues(alpha: 0.6), fontSize: 13),
                    filled: true, fillColor: fieldFill,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: border)),
                    counterStyle: TextStyle(color: textSub, fontSize: 11),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Số điện thoại (không bắt buộc)',
                    style: TextStyle(color: textSub, fontSize: 12)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: textPri, fontSize: 13),
                  onChanged: (_) => setState(() => phoneTouched = true),
                  decoration: InputDecoration(
                    hintText: '09xxxxxxxx',
                    hintStyle: TextStyle(color: textSub.withValues(alpha: 0.6), fontSize: 13),
                    filled: true, fillColor: fieldFill,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: border)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFEF4444))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    errorStyle: const TextStyle(fontSize: 11),
                  ),
                  validator: (v) {
                    if (!phoneTouched) return null;
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    if (!RegExp(r'^0\d{9}$').hasMatch(t)) {
                      return 'Số điện thoại không hợp lệ (10 chữ số, bắt đầu bằng 0)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Huỷ', style: TextStyle(color: textSub)),
            ),
            FilledButton(
              onPressed: () async {
                setState(() => phoneTouched = true);
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final ok = await ref.read(invitationsProvider.notifier).accept(
                  inv.id,
                  responseMessage: msgCtrl.text.trim().isEmpty ? null : msgCtrl.text.trim(),
                  phoneNumber:     phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Đã chấp nhận lời mời' : 'Chấp nhận thất bại. Thử lại.'),
                    backgroundColor: ok ? _kGreen : const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReject(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Từ chối lời mời',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontWeight: FontWeight.w800,
            )),
        content: Text(
          'Bạn có chắc muốn từ chối lời mời từ ${inv.company}?\nHành động này không thể hoàn tác.',
          style: TextStyle(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            fontSize: 13, height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Giữ lại', style: TextStyle(color: _kPrimary)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(invitationsProvider.notifier).reject(inv.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Đã từ chối lời mời' : 'Từ chối thất bại. Thử lại.'),
                  backgroundColor: ok
                      ? (isDark ? const Color(0xFF374151) : const Color(0xFF6B7280))
                      : const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

// ── Relative time helper ──────────────────────────────────────────────────────

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60)  return 'Vừa xong';
  if (diff.inMinutes < 60)  return '${diff.inMinutes} phút trước';
  if (diff.inHours   < 24)  return '${diff.inHours} giờ trước';
  if (diff.inDays    < 7)   return '${diff.inDays} ngày trước';
  if (diff.inDays    < 30)  return '${(diff.inDays / 7).floor()} tuần trước';
  if (diff.inDays    < 365) return '${(diff.inDays / 30).floor()} tháng trước';
  return '${(diff.inDays / 365).floor()} năm trước';
}

// ── Info row (inside the bordered info card) ──────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label, value;
  final Color    textPri, textSub, border;
  final bool     showDivider;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.textPri,
    required this.textSub,
    required this.border,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: textPri,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(color: border, height: 1, indent: 58, endIndent: 0),
      ],
    );
  }
}

// ── HR message card (styled letter) ───────────────────────────────────────────

class _HrMessageCard extends StatefulWidget {
  final String message;
  final bool   isDark;
  final Color  textPri, textSub, border;
  const _HrMessageCard({
    required this.message,
    required this.isDark,
    required this.textPri,
    required this.textSub,
    required this.border,
  });
  @override
  State<_HrMessageCard> createState() => _HrMessageCardState();
}

class _HrMessageCardState extends State<_HrMessageCard> {
  bool _expanded = false;

  static const _kCollapsedLines = 6;

  @override
  Widget build(BuildContext context) {
    final bg     = widget.isDark
        ? const Color(0xFF1E1B3A)
        : const Color(0xFFF3F0FF);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: _kPrimary.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mail_rounded, size: 14, color: _kPrimary),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Lời nhắn từ HR',
                  style: TextStyle(
                    color: _kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // ── Message body ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 260),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                widget.message,
                maxLines: _kCollapsedLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.textPri,
                  fontSize: 13.5,
                  height: 1.65,
                ),
              ),
              secondChild: Text(
                widget.message,
                style: TextStyle(
                  color: widget.textPri,
                  fontSize: 13.5,
                  height: 1.65,
                ),
              ),
            ),
          ),

          // ── Expand / Collapse toggle ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expanded ? 'Thu gọn' : 'Xem đầy đủ',
                    style: const TextStyle(
                      color: _kPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _kPrimary,
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

// ── Candidate response card ────────────────────────────────────────────────────

class _ResponseCard extends StatelessWidget {
  final String message;
  final bool   isDark;
  final Color  textPri, textSub, border;
  const _ResponseCard({
    required this.message,
    required this.isDark,
    required this.textPri,
    required this.textSub,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? const Color(0xFF0F2A1A)
        : const Color(0xFFF0FDF4);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: _kGreen.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.reply_rounded, size: 14, color: _kGreen),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Phản hồi của bạn',
                  style: TextStyle(
                    color: _kGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              message,
              style: TextStyle(
                color: textPri,
                fontSize: 13.5,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Company avatar (logo image or coloured initials fallback) ─────────────────

class _CompanyAvatar extends StatelessWidget {
  final double  size;
  final double  radius;
  final String? logoUrl;
  final String  initials;
  final Color   color;

  const _CompanyAvatar({
    required this.size,
    required this.radius,
    required this.logoUrl,
    required this.initials,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
        border:       Border.all(color: color.withValues(alpha: 0.28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null
          ? Image.network(
              logoUrl!,
              width:  size,
              height: size,
              fit:    BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() => Center(
    child: Text(
      initials,
      style: TextStyle(
        color:      color,
        fontSize:   size * 0.30,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  final bool isDark;
  const _Skeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.white;
    final shimmer = isDark ? AppColors.darkChip : AppColors.gray200;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => Container(
        height: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkChip : AppColors.gray200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 14, width: 120, color: shimmer, margin: const EdgeInsets.only(bottom: 6)),
                Container(height: 11, width: 80, color: shimmer),
              ])),
              Container(height: 22, width: 70, decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(6))),
            ]),
            const SizedBox(height: 12),
            Container(height: 13, width: double.infinity, color: shimmer, margin: const EdgeInsets.only(bottom: 6)),
            Container(height: 13, width: 200, color: shimmer),
          ],
        ),
      ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(),
    );
  }
}
