import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../data/providers/app_providers.dart';
import '../../hr_generate/data/generation_api.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n   = context.l10n;

    return Column(
      children: [
        // ── Tab bar ──────────────────────────────────────────────────────
        Container(
          color: isDark ? const Color(0xFF0B1020) : Colors.white,
          child: TabBar(
            controller:        _tabCtrl,
            isScrollable:      true,
            tabAlignment:      TabAlignment.start,
            indicatorColor:    const Color(0xFF6C47FF),
            labelColor:        const Color(0xFF6C47FF),
            unselectedLabelColor: isDark
                ? const Color(0xFF6B7280)
                : const Color(0xFF9CA3AF),
            labelStyle:  const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: l10n.profileTab),
              Tab(text: l10n.preferencesTab),
              Tab(text: l10n.notificationsTab),
              Tab(text: l10n.securityTab),
              Tab(text: l10n.billingTab),
            ],
          ),
        ),

        // ── Tab views ─────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children:   const [
              _ProfileTab(),
              _PreferencesTab(),
              _NotificationsTab(),
              _SecurityTab(),
              _BillingTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Profile Tab ───────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  final _nameCtrl    = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _titleCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl.text    = user?.name    ?? '';
    _companyCtrl.text = user?.company ?? '';
    _titleCtrl.text   = user?.title   ?? '';
    _phoneCtrl.text   = user?.phone   ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _titleCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() { _saving = true; _error = null; });
    try {
      final dio = buildGenerationDio();
      await dio.patch('/api/users/me/hr-profile', data: {
        'fullName':    _nameCtrl.text.trim(),
        'companyName': _companyCtrl.text.trim(),
        'jobTitle':    _titleCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e is DioException
            ? (e.response?.data?['message'] ?? 'Update failed')
            : 'Update failed';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user   = ref.watch(authProvider).user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Center(
            child: Column(
              children: [
                _InitialsAvatar(name: user?.name ?? 'HR', size: 72),
                const SizedBox(height: 8),
                Text(user?.email ?? '',
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_error != null)
            Container(
              margin:  const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 12)),
            ),

          _SettingsField(
            label:      'Full Name',
            controller: _nameCtrl,
            isDark:     isDark,
          ),
          const SizedBox(height: 12),
          _SettingsField(
            label:      'Company',
            controller: _companyCtrl,
            isDark:     isDark,
          ),
          const SizedBox(height: 12),
          _SettingsField(
            label:      'Job Title',
            controller: _titleCtrl,
            isDark:     isDark,
          ),
          const SizedBox(height: 12),
          _SettingsField(
            label:       'Phone',
            controller:  _phoneCtrl,
            isDark:      isDark,
            inputType:   TextInputType.phone,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C47FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      width:  18,
                      height: 18,
                      child:  CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Profile',
                      style: TextStyle(
                          fontSize:   14,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preferences Tab ───────────────────────────────────────────────────────────

class _PreferencesTab extends ConsumerWidget {
  const _PreferencesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final thMode    = ref.watch(themeProvider);
    final lang      = ref.watch(languageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Theme', isDark: isDark),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ThemeCard(
                  label:    'Light',
                  icon:     Icons.light_mode_rounded,
                  selected: thMode == ThemeMode.light,
                  isDark:   isDark,
                  onTap: () =>
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ThemeCard(
                  label:    'Dark',
                  icon:     Icons.dark_mode_rounded,
                  selected: thMode == ThemeMode.dark,
                  isDark:   isDark,
                  onTap: () =>
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ThemeCard(
                  label:    'System',
                  icon:     Icons.settings_display_rounded,
                  selected: thMode == ThemeMode.system,
                  isDark:   isDark,
                  onTap: () =>
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _SectionLabel(label: 'Language', isDark: isDark),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LangCard(
                  flag:     '🇺🇸',
                  label:    'English',
                  selected: lang == 'en',
                  isDark:   isDark,
                  onTap: () =>
                      ref.read(languageProvider.notifier).setLanguage('en'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LangCard(
                  flag:     '🇻🇳',
                  label:    'Vietnamese',
                  selected: lang == 'vi',
                  isDark:   isDark,
                  onTap: () =>
                      ref.read(languageProvider.notifier).setLanguage('vi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Notifications Tab ─────────────────────────────────────────────────────────

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  bool _genComplete = true;
  bool _planReady   = true;
  bool _failures    = true;
  bool _weekly      = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _NotifTile(
            title:       'Generation Complete',
            description: 'Notify when AI finishes generating questions',
            value:       _genComplete,
            isDark:      isDark,
            onChange:    (v) => setState(() => _genComplete = v),
          ),
          _NotifTile(
            title:       'Plan Ready',
            description: 'Notify when a plan is ready for your review',
            value:       _planReady,
            isDark:      isDark,
            onChange:    (v) => setState(() => _planReady = v),
          ),
          _NotifTile(
            title:       'Generation Failures',
            description: 'Notify when a generation job fails',
            value:       _failures,
            isDark:      isDark,
            onChange:    (v) => setState(() => _failures = v),
          ),
          _NotifTile(
            title:       'Weekly Summary',
            description: 'Get a weekly summary of your activity',
            value:       _weekly,
            isDark:      isDark,
            onChange:    (v) => setState(() => _weekly = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width:  double.infinity,
            child:  FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification preferences saved')),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C47FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Preferences'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Security Tab ──────────────────────────────────────────────────────────────

class _SecurityTab extends StatefulWidget {
  const _SecurityTab();

  @override
  State<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<_SecurityTab> {
  final _currCtrl = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _showCurr  = false;
  bool _showNew   = false;
  bool _showConf  = false;
  bool _saving    = false;
  String? _error;

  @override
  void dispose() {
    _currCtrl.dispose();
    _newCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() { _error = null; });
    final curr = _currCtrl.text;
    final newP = _newCtrl.text;
    final conf = _confCtrl.text;

    if (curr.isEmpty || newP.isEmpty || conf.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    if (newP.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters');
      return;
    }
    if (newP != conf) {
      setState(() => _error = 'New passwords do not match');
      return;
    }

    setState(() => _saving = true);
    try {
      final dio = buildGenerationDio();
      await dio.patch('/api/users/me/password', data: {
        'currentPassword': curr,
        'newPassword':     newP,
        'confirmPassword': conf,
      });
      _currCtrl.clear();
      _newCtrl.clear();
      _confCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e is DioException
            ? (e.response?.data?['message'] ?? 'Password change failed')
            : 'Password change failed';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Change Password', isDark: isDark),
          const SizedBox(height: 12),

          if (_error != null)
            Container(
              margin:  const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 12)),
            ),

          _PasswordField(
            label:      'Current Password',
            controller: _currCtrl,
            show:       _showCurr,
            isDark:     isDark,
            onToggle:   () => setState(() => _showCurr = !_showCurr),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            label:      'New Password',
            controller: _newCtrl,
            show:       _showNew,
            isDark:     isDark,
            onToggle:   () => setState(() => _showNew = !_showNew),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            label:      'Confirm New Password',
            controller: _confCtrl,
            show:       _showConf,
            isDark:     isDark,
            onToggle:   () => setState(() => _showConf = !_showConf),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _changePassword,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C47FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      width:  18,
                      height: 18,
                      child:  CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Change Password'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Billing Tab ───────────────────────────────────────────────────────────────

class _BillingTab extends StatefulWidget {
  const _BillingTab();

  @override
  State<_BillingTab> createState() => _BillingTabState();
}

class _BillingTabState extends State<_BillingTab> {
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

  Future<void> _selectPlan(String p) async {
    setState(() => _plan = p);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hiregen-hr-plan', p);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan changed to ${_planName(p)}')),
      );
    }
  }

  static const _plans = [
    _PlanData(
      id:       'basic',
      name:     'Basic',
      price:    '\$0',
      features: ['5 JDs/month', '50 Questions', 'Community support'],
    ),
    _PlanData(
      id:       'professional',
      name:     'Professional',
      price:    '\$29',
      features: ['50 JDs/month', '800 Questions', 'Email support',
          'Question editor'],
      recommended: true,
    ),
    _PlanData(
      id:       'business',
      name:     'Business',
      price:    '\$79',
      features: ['200 JDs/month', '5000 Questions', 'Priority support',
          'Exports', 'Team collaboration'],
    ),
    _PlanData(
      id:       'enterprise',
      name:     'Enterprise',
      price:    'Custom',
      features: ['Unlimited JDs', 'Unlimited Questions', 'Dedicated support',
          'Custom integrations', 'SLA'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current plan banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C47FF), Color(0xFF3B82F6)],
                begin:  Alignment.topLeft,
                end:    Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _planName(_plan),
                        style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   18,
                            fontWeight: FontWeight.w800),
                      ),
                      const Text('Current Plan',
                          style: TextStyle(
                              color:    Color(0xCCFFFFFF),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Active',
                      style: TextStyle(
                          color:      Colors.white,
                          fontSize:   11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Usage bars (mock)
          _SectionLabel(label: 'Usage This Month', isDark: isDark),
          const SizedBox(height: 10),
          _UsageBar(label: 'JDs Processed',      used: 24, max: 50,   isDark: isDark),
          const SizedBox(height: 8),
          _UsageBar(label: 'Questions Generated', used: 186, max: 800, isDark: isDark),
          const SizedBox(height: 8),
          _UsageBar(label: 'Exports',             used: 12, max: 40,   isDark: isDark),
          const SizedBox(height: 20),

          // Plan cards
          _SectionLabel(label: 'Change Plan', isDark: isDark),
          const SizedBox(height: 10),
          ..._plans.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child:   _PlanCard(
                  data:     p,
                  selected: _plan == p.id,
                  isDark:   isDark,
                  onSelect: () => _selectPlan(p.id),
                ),
              )),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _planName(String p) {
    switch (p) {
      case 'basic':        return 'Basic Plan';
      case 'professional': return 'Professional Plan';
      case 'business':     return 'Business Plan';
      case 'enterprise':   return 'Enterprise Plan';
      default:             return 'Plan';
    }
  }
}

class _PlanData {
  final String id;
  final String name;
  final String price;
  final List<String> features;
  final bool recommended;

  const _PlanData({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
    this.recommended = false,
  });
}

// ── Common Settings Widgets ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
            color:      isDark ? Colors.white : const Color(0xFF111827),
            fontSize:   15,
            fontWeight: FontWeight.w700),
      );
}

class _SettingsField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final TextInputType? inputType;

  const _SettingsField({
    required this.label,
    required this.controller,
    required this.isDark,
    this.inputType,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color:      isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                  fontSize:   12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller:  controller,
            keyboardType: inputType,
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 14),
            decoration: InputDecoration(
              filled:        true,
              fillColor:     isDark
                  ? const Color(0xFF111827)
                  : const Color(0xFFF9FAFB),
              border:        OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:   BorderSide(
                    color: isDark
                        ? const Color(0xFF2D3562)
                        : const Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF6C47FF)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 14),
            ),
          ),
        ],
      );
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool show;
  final bool isDark;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.show,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color:    isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller:   controller,
            obscureText:  !show,
            style: TextStyle(
                color:    isDark ? Colors.white : const Color(0xFF111827),
                fontSize: 14),
            decoration: InputDecoration(
              filled:        true,
              fillColor:     isDark
                  ? const Color(0xFF111827)
                  : const Color(0xFFF9FAFB),
              suffixIcon: IconButton(
                icon: Icon(
                  show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: const Color(0xFF6B7280),
                  size:  20,
                ),
                onPressed: onToggle,
              ),
              border:        OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:   BorderSide(
                    color: isDark
                        ? const Color(0xFF2D3562)
                        : const Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6C47FF)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 14),
            ),
          ),
        ],
      );
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6C47FF).withValues(alpha: 0.12)
                : isDark
                    ? const Color(0xFF1A1F35)
                    : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6C47FF)
                  : isDark
                      ? const Color(0xFF2D3562)
                      : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected
                      ? const Color(0xFF6C47FF)
                      : const Color(0xFF6B7280),
                  size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: selected
                          ? const Color(0xFF6C47FF)
                          : isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                      fontSize:   11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _LangCard extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LangCard({
    required this.flag,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6C47FF).withValues(alpha: 0.12)
                : isDark
                    ? const Color(0xFF1A1F35)
                    : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6C47FF)
                  : isDark
                      ? const Color(0xFF2D3562)
                      : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: selected
                          ? const Color(0xFF6C47FF)
                          : isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                      fontSize:   12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _NotifTile extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChange;

  const _NotifTile({
    required this.title,
    required this.description,
    required this.value,
    required this.isDark,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F35) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF2D3562)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color:      isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                          fontSize:   13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: const TextStyle(
                          color:    Color(0xFF6B7280),
                          fontSize: 11)),
                ],
              ),
            ),
            Switch(
              value:          value,
              onChanged:      onChange,
              activeColor:    const Color(0xFF6C47FF),
              activeTrackColor:
                  const Color(0xFF6C47FF).withValues(alpha: 0.3),
            ),
          ],
        ),
      );
}

class _UsageBar extends StatelessWidget {
  final String label;
  final int used;
  final int max;
  final bool isDark;

  const _UsageBar({
    required this.label,
    required this.used,
    required this.max,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pct   = (used / max).clamp(0.0, 1.0);
    final color = pct > 0.85
        ? const Color(0xFFEF4444)
        : pct > 0.6
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color:    isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontSize: 12)),
            Text('$used / $max',
                style: TextStyle(
                    color:      isDark ? Colors.white : const Color(0xFF111827),
                    fontSize:   12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:           pct,
            backgroundColor: isDark
                ? const Color(0xFF1E2640)
                : const Color(0xFFE5E7EB),
            valueColor:      AlwaysStoppedAnimation<Color>(color),
            minHeight:       6,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _PlanData data;
  final bool selected;
  final bool isDark;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.data,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF6C47FF).withValues(alpha: 0.08)
                : isDark
                    ? const Color(0xFF1A1F35)
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6C47FF)
                  : isDark
                      ? const Color(0xFF2D3562)
                      : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio
              Container(
                width:  20,
                height: 20,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? const Color(0xFF6C47FF) : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF6C47FF)
                        : const Color(0xFF6B7280),
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 12)
                    : null,
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(data.name,
                            style: TextStyle(
                                color:      isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                                fontSize:   14,
                                fontWeight: FontWeight.w700)),
                        if (data.recommended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:        const Color(0xFF6C47FF)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Recommended',
                                style: TextStyle(
                                    color:      Color(0xFF6C47FF),
                                    fontSize:   9,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                        const Spacer(),
                        Text(data.price,
                            style: TextStyle(
                                color:      isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                                fontSize:   16,
                                fontWeight: FontWeight.w800)),
                        if (data.price != 'Custom')
                          Text('/mo',
                              style: const TextStyle(
                                  color:    Color(0xFF6B7280),
                                  fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...data.features.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              const Icon(Icons.check_rounded,
                                  size:  13,
                                  color: Color(0xFF10B981)),
                              const SizedBox(width: 5),
                              Text(f,
                                  style: TextStyle(
                                      color:    isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                      fontSize: 11)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _InitialsAvatar({required this.name, required this.size});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'H';
  }

  @override
  Widget build(BuildContext context) => Container(
        width:  size,
        height: size,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C47FF), Color(0xFF3B82F6)],
            begin:  Alignment.topLeft,
            end:    Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _initials,
            style: TextStyle(
                color:      Colors.white,
                fontSize:   size * 0.32,
                fontWeight: FontWeight.w700),
          ),
        ),
      );
}
