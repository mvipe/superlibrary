import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

class ExpiringScreen extends StatefulWidget {
  const ExpiringScreen({super.key});

  @override
  State<ExpiringScreen> createState() => _ExpiringScreenState();
}

class _ExpiringScreenState extends State<ExpiringScreen> {
  late Future<(List<Member>, Map<String, double>)> _future;
  final _rupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<Member>, Map<String, double>)> _load() async {
    final results = await Future.wait([
      Repo.instance.expiringSoon(days: 30),
      Repo.instance.duesByMember(),
    ]);
    return (results[0] as List<Member>, results[1] as Map<String, double>);
  }

  int _daysLeft(Member m) =>
      m.expiresAt!.difference(DateTime.now()).inDays;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Expiring Memberships'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: FutureBuilder<(List<Member>, Map<String, double>)>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final members = snap.data!.$1;
          final dues = snap.data!.$2;
          final expired = members.where((m) => _daysLeft(m) < 0).length;
          final in3 = members
              .where((m) => _daysLeft(m) >= 0 && _daysLeft(m) <= 3)
              .length;
          final in7 = members
              .where((m) => _daysLeft(m) >= 0 && _daysLeft(m) <= 7)
              .length;

          if (members.isEmpty) {
            return const EmptyState(
                icon: Icons.event_available_rounded,
                title: 'Nothing expiring',
                subtitle:
                    'Members with a plan get a 1-month expiry. None are due within 30 days.');
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
            children: [
              Row(
                children: [
                  Expanded(
                      child: _stat('Expired', '$expired', AppColors.danger,
                          AppColors.dangerBg)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _stat('≤ 3 days', '$in3', AppColors.warning,
                          AppColors.warningBg)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _stat('≤ 7 days', '$in7', AppColors.info,
                          AppColors.infoBg)),
                ],
              ),
              const SizedBox(height: 20),
              SectionHeader(title: 'Members (${members.length})'),
              const SizedBox(height: 12),
              ...members.map((m) => _tile(m, dues[m.id] ?? 0)),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.rLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 4,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.lexend(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label,
              style:
                  GoogleFonts.lexend(fontSize: 11.5, color: AppColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _tile(Member m, double due) {
    final d = _daysLeft(m);
    final expired = d < 0;
    final urgent = d <= 3;
    final color = expired
        ? AppColors.danger
        : urgent
            ? AppColors.warning
            : AppColors.info;
    final bg = expired
        ? AppColors.dangerBg
        : urgent
            ? AppColors.warningBg
            : AppColors.infoBg;
    final label = expired
        ? 'Expired ${-d}d ago'
        : d == 0
            ? 'Expires today'
            : 'in $d days';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Avatar(name: m.name, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.event_rounded,
                          size: 12, color: AppColors.inkFaint),
                      const SizedBox(width: 4),
                      Text(
                          '${m.plan ?? 'No plan'} • ${DateFormat('d MMM').format(m.expiresAt!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexend(
                              fontSize: 12, color: AppColors.inkSoft)),
                    ],
                  ),
                  if (due > 0) ...[
                    const SizedBox(height: 5),
                    Text('Due: ${_rupee.format(due)}',
                        style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(label: label, color: color, bg: bg),
                const SizedBox(height: 6),
                StatusChip(
                    label: due > 0 ? 'Pending' : 'Paid',
                    color: due > 0 ? AppColors.danger : AppColors.success,
                    bg: due > 0 ? AppColors.dangerBg : AppColors.successBg),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
