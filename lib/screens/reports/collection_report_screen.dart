import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

class CollectionReportScreen extends StatefulWidget {
  const CollectionReportScreen({super.key});

  @override
  State<CollectionReportScreen> createState() => _CollectionReportScreenState();
}

class _CollectionReportScreenState extends State<CollectionReportScreen> {
  late Future<List<Payment>> _future;
  int _period = 0;
  DateTimeRange? _custom;
  static const _tabs = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last Month',
    'Custom'
  ];
  final _rupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _future = Repo.instance.payments();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inPeriod(DateTime d) {
    final now = DateTime.now();
    return switch (_period) {
      0 => _sameDay(d, now),
      1 => _sameDay(d, now.subtract(const Duration(days: 1))),
      2 => d.isAfter(now.subtract(const Duration(days: 7))),
      3 => d.year == now.year && d.month == now.month - 1 ||
          (now.month == 1 && d.year == now.year - 1 && d.month == 12),
      _ => _custom == null
          ? true
          : !d.isBefore(DateTime(_custom!.start.year, _custom!.start.month,
                  _custom!.start.day)) &&
              !d.isAfter(DateTime(_custom!.end.year, _custom!.end.month,
                  _custom!.end.day, 23, 59, 59)),
    };
  }

  Future<void> _onTab(int i) async {
    if (i == 4) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDateRange: _custom,
      );
      if (range != null) {
        setState(() {
        _custom = range;
        _period = 4;
      });
      }
    } else {
      setState(() => _period = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Collection Report'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: FutureBuilder<List<Payment>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final all = (snap.data ?? []).where((p) => _inPeriod(p.date)).toList();
          final paid = all.where((p) => p.status == PaymentStatus.paid);
          double collection = paid.fold(0, (s, p) => s + p.amount);
          double membership = paid
              .where((p) => p.type == PaymentType.membership)
              .fold(0, (s, p) => s + p.amount);
          double fine = paid
              .where((p) => p.type == PaymentType.fine)
              .fold(0, (s, p) => s + p.amount);
          double pending = all
              .where((p) => p.status != PaymentStatus.paid)
              .fold(0, (s, p) => s + p.amount);
          double cash = paid
              .where((p) => p.method == 'cash')
              .fold(0, (s, p) => s + p.amount);
          double online = collection - cash;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            children: [
              FilterTabs(
                  tabs: _tabs, selected: _period, onChanged: _onTab),
              if (_period == 4 && _custom != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                      '${DateFormat('d MMM').format(_custom!.start)} – ${DateFormat('d MMM yyyy').format(_custom!.end)}',
                      style: GoogleFonts.lexend(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.heroGradient),
                  borderRadius: BorderRadius.circular(AppColors.rXl),
                  boxShadow: AppTheme.heroShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Collection',
                        style: GoogleFonts.lexend(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(_rupee.format(collection),
                          style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 32)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _heroMini('Cash', _rupee.format(cash)),
                        Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withValues(alpha: 0.25)),
                        _heroMini('Online', _rupee.format(online)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _statCard('Membership', _rupee.format(membership),
                      AppColors.success, AppColors.successBg),
                  const SizedBox(width: 12),
                  _statCard('Fine', _rupee.format(fine), AppColors.warning,
                      AppColors.warningBg),
                  const SizedBox(width: 12),
                  _statCard('Pending', _rupee.format(pending), AppColors.danger,
                      AppColors.dangerBg),
                ],
              ),
              const SizedBox(height: 22),
              SectionHeader(title: 'Transactions (${all.length})'),
              const SizedBox(height: 12),
              if (all.isEmpty)
                const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No collection in this period')
              else
                ...all.map(_row),
            ],
          );
        },
      ),
    );
  }

  Widget _heroMini(String label, String value) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.lexend(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
        ),
      );

  Widget _statCard(String label, String value, Color color, Color bg) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(AppColors.rSm)),
                child: Icon(Icons.circle, color: color, size: 12),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              Text(label,
                  style: GoogleFonts.lexend(
                      fontSize: 11, color: AppColors.inkSoft)),
            ],
          ),
        ),
      );

  Widget _row(Payment p) {
    final isFine = p.type == PaymentType.fine;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Avatar(name: p.memberName, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.memberName,
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${p.typeLabel} • ${p.method} • ${DateFormat('d MMM').format(p.date)}',
                      style: GoogleFonts.lexend(
                          fontSize: 11.5, color: AppColors.inkSoft)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_rupee.format(p.amount),
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: isFine ? AppColors.danger : AppColors.ink)),
                const SizedBox(height: 4),
                StatusChip(
                    label: p.status.label,
                    color: p.status.color,
                    bg: p.status.bg),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
