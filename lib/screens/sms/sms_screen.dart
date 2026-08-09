import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/msg91_service.dart';
import '../../config/msg91_config.dart';
import '../../widgets/common.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({super.key});

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  bool _autoExpiry = true;
  bool _welcome = true;
  int _daysBefore = 3;
  bool _sending = false;
  late Future<List<Member>> _future;

  @override
  void initState() {
    super.initState();
    _future = Repo.instance.members();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _autoExpiry = p.getBool('sms_auto_expiry') ?? true;
      _welcome = p.getBool('sms_welcome') ?? true;
      _daysBefore = p.getInt('sms_days_before') ?? 3;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('sms_auto_expiry', _autoExpiry);
    await p.setBool('sms_welcome', _welcome);
    await p.setInt('sms_days_before', _daysBefore);
  }

  int _daysLeft(Member m) =>
      m.expiresAt == null ? 9999 : m.expiresAt!.difference(DateTime.now()).inDays;

  List<Member> _expiring(List<Member> all) => all
      .where((m) => _daysLeft(m) >= 0 && _daysLeft(m) <= _daysBefore)
      .toList()
    ..sort((a, b) => _daysLeft(a).compareTo(_daysLeft(b)));

  Future<void> _sendAll(List<Member> targets) async {
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No members are expiring in this window.')));
      return;
    }
    setState(() => _sending = true);
    int ok = 0;
    for (final m in targets) {
      final sent = await Msg91Service.instance.sendReminder(m.phone, {
        'name': m.name,
        'days': '${_daysLeft(m)}',
      });
      if (sent) ok++;
    }
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_simulated
            ? '$ok reminder(s) simulated (configure MSG91 Flow ID to send real SMS).'
            : '$ok reminder(s) sent successfully.')));
  }

  bool get _simulated => Msg91Config.smsFlowId == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Auto SMS Reminder'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: FutureBuilder<List<Member>>(
        future: _future,
        builder: (context, snap) {
          final members = snap.data ?? [];
          final expiring = _expiring(members);
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
            children: [
              if (_simulated)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(AppColors.rMd),
                      border: Border.all(color: const Color(0xFFF3D9A6))),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'Demo mode: reminders are simulated. Add an MSG91 Flow ID in msg91_config.dart to send real SMS.',
                            style: GoogleFonts.lexend(
                                fontSize: 12, color: AppColors.inkSoft)),
                      ),
                    ],
                  ),
                ),
              PremiumCard(
                child: Column(
                  children: [
                    _toggle('Membership expiry reminder',
                        'Auto-notify members before their plan ends', _autoExpiry,
                        (v) {
                      setState(() => _autoExpiry = v);
                      _save();
                    }),
                    const Divider(height: 22),
                    _toggle('Welcome SMS',
                        'Send a welcome message when a member joins', _welcome,
                        (v) {
                      setState(() => _welcome = v);
                      _save();
                    }),
                    const Divider(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Remind before',
                                  style: GoogleFonts.lexend(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text('Days before expiry to notify',
                                  style: GoogleFonts.lexend(
                                      fontSize: 12,
                                      color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        _stepper(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionHeader(title: 'Expiring soon (${expiring.length})'),
              const SizedBox(height: 12),
              if (expiring.isEmpty)
                const EmptyState(
                    icon: Icons.notifications_off_rounded,
                    title: 'Nobody expiring',
                    subtitle: 'No memberships end within the reminder window.')
              else
                ...expiring.map(_memberTile),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<List<Member>>(
        future: _future,
        builder: (context, snap) {
          final expiring = _expiring(snap.data ?? []);
          return FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            onPressed: _sending ? null : () => _sendAll(expiring),
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white),
            label: Text(_sending ? 'Sending...' : 'Send Reminders',
                style: GoogleFonts.lexend(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          );
        },
      ),
    );
  }

  Widget _toggle(String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(sub,
                  style: GoogleFonts.lexend(
                      fontSize: 12, color: AppColors.inkSoft)),
            ],
          ),
        ),
        Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged),
      ],
    );
  }

  Widget _stepper() {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.circular(AppColors.rMd)),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 18),
            onPressed: _daysBefore > 1
                ? () {
                    setState(() => _daysBefore--);
                    _save();
                  }
                : null,
          ),
          Text('$_daysBefore d',
              style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 18),
            onPressed: _daysBefore < 30
                ? () {
                    setState(() => _daysBefore++);
                    _save();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _memberTile(Member m) {
    final d = _daysLeft(m);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Avatar(name: m.name, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name,
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(m.phone,
                      style: GoogleFonts.lexend(
                          fontSize: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
            StatusChip(
                label: d == 0 ? 'Today' : 'in $d d',
                color: d <= 1 ? AppColors.danger : AppColors.warning,
                bg: d <= 1 ? AppColors.dangerBg : AppColors.warningBg),
          ],
        ),
      ),
    );
  }
}
