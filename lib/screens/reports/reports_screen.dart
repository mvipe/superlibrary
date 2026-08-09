import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common.dart';

enum ReportType {
  overview,
  collection,
  payments,
  bookIssues,
  expenses,
  seats,
  tax,
  members,
}

extension ReportTypeX on ReportType {
  String get label => switch (this) {
        ReportType.overview => 'Overview',
        ReportType.collection => 'Collection',
        ReportType.payments => 'Payments',
        ReportType.bookIssues => 'Book Issue / Return',
        ReportType.expenses => 'Expenses',
        ReportType.seats => 'Seats',
        ReportType.tax => 'Tax',
        ReportType.members => 'Members',
      };
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportType _type = ReportType.overview;
  int _refreshTick = 0;
  final _rupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  Future<void> _pickType() async {
    final picked = await showSearchablePicker<ReportType>(
      context,
      title: 'Select report',
      items: ReportType.values,
      label: (t) => t.label,
      searchHint: 'Search report',
    );
    if (picked != null) setState(() => _type = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Reports'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: PickerField(
              hint: 'Select report',
              value: _type.label,
              sub: 'Tap to switch report',
              icon: Icons.expand_more_rounded,
              onTap: _pickType,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                setState(() => _refreshTick++);
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: KeyedSubtree(
                key: ValueKey('$_type-$_refreshTick'),
                child: _body(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return switch (_type) {
      ReportType.overview => _OverviewReport(rupee: _rupee),
      ReportType.collection => _CollectionReport(rupee: _rupee),
      ReportType.payments => _PaymentsReport(rupee: _rupee),
      ReportType.bookIssues => const _BookIssuesReport(),
      ReportType.expenses => _ExpensesReport(rupee: _rupee),
      ReportType.seats => const _SeatsReport(),
      ReportType.tax => const _TaxReport(),
      ReportType.members => const _MembersReport(),
    };
  }
}

// ---------------------------------------------------------------------
// Shared little building blocks
// ---------------------------------------------------------------------
Widget _statRow(List<Widget> cards) => Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ]
      ],
    );

Widget _statCard(
    String label, String value, Color color, Color bg, IconData icon) {
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(AppColors.rMd)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: GoogleFonts.lexend(
                  fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lexend(fontSize: 11.5, color: AppColors.inkSoft)),
      ],
    ),
  );
}

Widget _loading() =>
    Center(child: CircularProgressIndicator(color: AppColors.primary));

// =====================================================================
// OVERVIEW (KPIs + issued/returned chart + top books)
// =====================================================================
class _OverviewReport extends StatefulWidget {
  final NumberFormat rupee;
  const _OverviewReport({required this.rupee});
  @override
  State<_OverviewReport> createState() => _OverviewReportState();
}

class _OverviewReportState extends State<_OverviewReport> {
  late final Future<ReportData> _report = Repo.instance.reports();
  late final Future<ChartSeries> _series = Repo.instance.issueReturnSeries();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReportData>(
      future: _report,
      builder: (context, snap) {
        if (!snap.hasData) return _loading();
        final r = snap.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          children: [
            _statRow([
              _statCard('Books Issued', '${r.booksIssued}', AppColors.info,
                  AppColors.infoBg, Icons.library_books_rounded),
              _statCard('In Stock', '${r.booksReturned}', AppColors.success,
                  AppColors.successBg, Icons.assignment_turned_in_rounded),
            ]),
            const SizedBox(height: 12),
            _statRow([
              _statCard('Members', '${r.newMembers}', const Color(0xFF7C3AED),
                  AppColors.tintPurple, Icons.groups_rounded),
              _statCard('Fine Collected', widget.rupee.format(r.fineCollected),
                  AppColors.warning, AppColors.warningBg,
                  Icons.currency_rupee_rounded),
            ]),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Issued vs Returned (7 days)'),
            const SizedBox(height: 12),
            PremiumCard(
              padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
              child: Column(
                children: [
                  SizedBox(height: 220, child: _chartArea()),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legend('Issued', AppColors.primary),
                      const SizedBox(width: 20),
                      _legend('Returned', AppColors.info),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Top Books Issued'),
            const SizedBox(height: 12),
            if (r.topBooks.isEmpty)
              const EmptyState(
                  icon: Icons.menu_book_rounded, title: 'No data yet')
            else
              ...r.topBooks.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _topBookTile(b),
                  )),
          ],
        );
      },
    );
  }

  Widget _chartArea() {
    return FutureBuilder<ChartSeries>(
      future: _series,
      builder: (context, snap) {
        if (!snap.hasData) return _loading();
        final s = snap.data!;
        final maxV =
            [...s.issued, ...s.returned, 4.0].reduce((a, b) => a > b ? a : b);
        final maxY = maxV.ceilToDouble() + 1;
        List<FlSpot> spots(List<double> d) =>
            [for (var i = 0; i < d.length; i++) FlSpot(i.toDouble(), d[i])];
        return LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY / 4).clamp(1, maxY),
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: AppColors.divider, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (maxY / 4).clamp(1, maxY),
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: GoogleFonts.lexend(
                          fontSize: 10, color: AppColors.inkFaint)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (v, _) {
                    final day = DateTime.now()
                        .subtract(Duration(days: (6 - v).toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(DateFormat('E').format(day)[0],
                          style: GoogleFonts.lexend(
                              fontSize: 10, color: AppColors.inkFaint)),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              _line(spots(s.issued), AppColors.primary),
              _line(spots(s.returned), AppColors.info),
            ],
          ),
        );
      },
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3,
              color: Colors.white,
              strokeWidth: 2,
              strokeColor: color),
        ),
        belowBarData:
            BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
      );

  Widget _legend(String label, Color color) => Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 6),
          Text(label,
              style:
                  GoogleFonts.lexend(fontSize: 12, color: AppColors.inkSoft)),
        ],
      );

  Widget _topBookTile(Book b) {
    final issued = b.totalCopies - b.availableCopies;
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [b.accent, b.accent.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(AppColors.rSm),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700, fontSize: 14.5)),
                Text(b.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        fontSize: 12, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$issued issued',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// COLLECTION
// =====================================================================
class _CollectionReport extends StatelessWidget {
  final NumberFormat rupee;
  const _CollectionReport({required this.rupee});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: Repo.instance.payments(),
      builder: (context, snap) {
        if (!snap.hasData) return _loading();
        final all = snap.data!;
        final paid = all.where((p) => p.status == PaymentStatus.paid);
        double total = paid.fold(0, (s, p) => s + p.amount);
        double cash = paid
            .where((p) => p.method == 'cash')
            .fold(0, (s, p) => s + p.amount);
        double online = total - cash;
        double pending = all
            .where((p) => p.status != PaymentStatus.paid)
            .fold(0, (s, p) => s + p.amount);
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          children: [
            _heroTotal('Total Collection', rupee.format(total),
                'Cash ${rupee.format(cash)}  •  Online ${rupee.format(online)}'),
            const SizedBox(height: 14),
            _statRow([
              _statCard('Online', rupee.format(online), AppColors.info,
                  AppColors.infoBg, Icons.account_balance_wallet_rounded),
              _statCard('Pending', rupee.format(pending), AppColors.danger,
                  AppColors.dangerBg, Icons.schedule_rounded),
            ]),
            const SizedBox(height: 20),
            SectionHeader(title: 'Paid transactions (${paid.length})'),
            const SizedBox(height: 12),
            ...paid.map((p) => _paymentTile(p, rupee)),
            if (paid.isEmpty)
              const EmptyState(
                  icon: Icons.receipt_long_rounded, title: 'No collection yet'),
          ],
        );
      },
    );
  }
}

// =====================================================================
// PAYMENTS (all, with status)
// =====================================================================
class _PaymentsReport extends StatelessWidget {
  final NumberFormat rupee;
  const _PaymentsReport({required this.rupee});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: Repo.instance.payments(),
      builder: (context, snap) {
        if (!snap.hasData) return _loading();
        final all = snap.data!;
        final paidN = all.where((p) => p.status == PaymentStatus.paid).length;
        final pendN = all.where((p) => p.status == PaymentStatus.pending).length;
        final overN = all.where((p) => p.status == PaymentStatus.overdue).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          children: [
            _statRow([
              _statCard('Paid', '$paidN', AppColors.success,
                  AppColors.successBg, Icons.check_circle_rounded),
              _statCard('Pending', '$pendN', AppColors.warning,
                  AppColors.warningBg, Icons.schedule_rounded),
              _statCard('Overdue', '$overN', AppColors.danger,
                  AppColors.dangerBg, Icons.error_outline_rounded),
            ]),
            const SizedBox(height: 20),
            SectionHeader(title: 'All payments (${all.length})'),
            const SizedBox(height: 12),
            ...all.map((p) => _paymentTile(p, rupee)),
            if (all.isEmpty)
              const EmptyState(
                  icon: Icons.payments_rounded, title: 'No payments yet'),
          ],
        );
      },
    );
  }
}

// =====================================================================
// BOOK ISSUES / RETURNS
// =====================================================================
class _BookIssuesReport extends StatelessWidget {
  const _BookIssuesReport();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Transaction>>(
      future: Repo.instance.monthTransactions(),
      builder: (context, snap) {
        if (!snap.hasData) return _loading();
        final txns = snap.data!..sort((a, b) => b.time.compareTo(a.time));
        final issued = txns.where((t) => !t.isReturn).length;
        final returned = txns.where((t) => t.isReturn).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          children: [
            _statRow([
              _statCard('Issued', '$issued', AppColors.info, AppColors.infoBg,
                  Icons.north_east_rounded),
              _statCard('Returned', '$returned', AppColors.success,
                  AppColors.successBg, Icons.south_west_rounded),
            ]),
            const SizedBox(height: 20),
            SectionHeader(title: 'This month (${txns.length})'),
            const SizedBox(height: 12),
            ...txns.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PremiumCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              color: t.isReturn
                                  ? AppColors.successBg
                                  : AppColors.infoBg,
                              borderRadius:
                                  BorderRadius.circular(AppColors.rMd)),
                          child: Icon(
                              t.isReturn
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              size: 18,
                              color: t.isReturn
                                  ? AppColors.success
                                  : AppColors.info),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.bookTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lexend(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text(
                                  '${t.isReturn ? 'Returned by' : 'Issued to'} ${t.memberName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lexend(
                                      fontSize: 12, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        Text(DateFormat('d MMM').format(t.time),
                            style: GoogleFonts.lexend(
                                fontSize: 11.5, color: AppColors.inkFaint)),
                      ],
                    ),
                  ),
                )),
            if (txns.isEmpty)
              const EmptyState(
                  icon: Icons.swap_horiz_rounded,
                  title: 'No issues/returns this month'),
          ],
        );
      },
    );
  }
}

// =====================================================================
// EXPENSES
// =====================================================================
class _ExpensesReport extends StatelessWidget {
  final NumberFormat rupee;
  const _ExpensesReport({required this.rupee});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Expense>>(
      future: Repo.instance.expenses(),
      builder: (context, snap) {
        if (!snap.hasData) return _loading();
        final all = snap.data!;
        final total = all.fold<double>(0, (s, e) => s + e.amount);
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          children: [
            _heroTotal('Total Expenses', rupee.format(total),
                '${all.length} entries'),
            const SizedBox(height: 20),
            SectionHeader(title: 'All expenses (${all.length})'),
            const SizedBox(height: 12),
            ...all.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PremiumCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lexend(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text(DateFormat('d MMM yyyy').format(e.spentOn),
                                  style: GoogleFonts.lexend(
                                      fontSize: 12, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        Text(rupee.format(e.amount),
                            style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.danger)),
                      ],
                    ),
                  ),
                )),
            if (all.isEmpty)
              const EmptyState(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'No expenses yet'),
          ],
        );
      },
    );
  }
}

// =====================================================================
// SEATS (occupancy per shift)
// =====================================================================
class _SeatsReport extends StatelessWidget {
  const _SeatsReport();

  Future<List<(Shift, int)>> _load() async {
    final shifts = await Repo.instance.shifts();
    return Future.wait(shifts.map((s) async =>
        (s, (await Repo.instance.allotments(s.name)).length)));
  }

  @override
  Widget build(BuildContext context) {
    final total = SupabaseService.instance.library?.totalSeats ?? 30;
    return FutureBuilder<List<(Shift, int)>>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) return _loading();
        final rows = snap.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          children: [
            _heroTotal('Total Seats', '$total', 'Per-shift occupancy below'),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Occupancy by shift'),
            const SizedBox(height: 12),
            ...rows.map((r) {
              final shift = r.$1;
              final used = r.$2;
              final free = (total - used).clamp(0, total);
              final pct = total == 0 ? 0.0 : used / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(shift.name,
                              style: GoogleFonts.lexend(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const Spacer(),
                          Text('$used / $total',
                              style: GoogleFonts.lexend(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          minHeight: 8,
                          backgroundColor: AppColors.divider,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('$free seats available',
                          style: GoogleFonts.lexend(
                              fontSize: 12, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
              );
            }),
            if (rows.isEmpty)
              const EmptyState(
                  icon: Icons.event_seat_rounded, title: 'No shifts/plans yet'),
          ],
        );
      },
    );
  }
}

// =====================================================================
// TAX
// =====================================================================
class _TaxReport extends StatelessWidget {
  const _TaxReport();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Tax>>(
      future: Repo.instance.taxes(),
      builder: (context, snap) {
        if (!snap.hasData) return _loading();
        final all = snap.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          children: [
            SectionHeader(title: 'Configured taxes (${all.length})'),
            const SizedBox(height: 12),
            ...all.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PremiumCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        TintedIcon(
                            icon: Icons.percent_rounded,
                            color: AppColors.info,
                            bg: AppColors.infoBg,
                            box: 42,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(t.name,
                              style: GoogleFonts.lexend(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        Text(
                            '${t.percent.toStringAsFixed(t.percent % 1 == 0 ? 0 : 1)}%',
                            style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                )),
            if (all.isEmpty)
              const EmptyState(
                  icon: Icons.percent_rounded, title: 'No taxes configured'),
          ],
        );
      },
    );
  }
}

// =====================================================================
// MEMBERS
// =====================================================================
class _MembersReport extends StatelessWidget {
  const _MembersReport();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Member>>(
      future: Repo.instance.members(),
      builder: (context, snap) {
        if (!snap.hasData) return _loading();
        final all = snap.data!;
        int c(MemberStatus s) => all.where((m) => m.status == s).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
          children: [
            _statRow([
              _statCard('Total', '${all.length}', AppColors.info,
                  AppColors.infoBg, Icons.groups_rounded),
              _statCard('Active', '${c(MemberStatus.active)}',
                  AppColors.success, AppColors.successBg,
                  Icons.check_circle_rounded),
              _statCard('Expired', '${c(MemberStatus.expired)}',
                  AppColors.danger, AppColors.dangerBg,
                  Icons.error_outline_rounded),
            ]),
            const SizedBox(height: 20),
            SectionHeader(title: 'All members (${all.length})'),
            const SizedBox(height: 12),
            ...all.map((m) => Padding(
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lexend(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text(
                                  '${m.memberCode}${m.plan != null ? ' • ${m.plan}' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lexend(
                                      fontSize: 12, color: AppColors.inkSoft)),
                            ],
                          ),
                        ),
                        StatusChip(
                            label: m.status.label,
                            color: m.status.color,
                            bg: m.status.bg),
                      ],
                    ),
                  ),
                )),
            if (all.isEmpty)
              const EmptyState(
                  icon: Icons.groups_rounded, title: 'No members yet'),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// shared tile + hero used by several reports
// ---------------------------------------------------------------------
Widget _heroTotal(String label, String value, String sub) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: AppColors.heroGradient),
      borderRadius: BorderRadius.circular(AppColors.rXl),
      boxShadow: AppTheme.heroShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.lexend(
                color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 30)),
        ),
        const SizedBox(height: 4),
        Text(sub,
            style: GoogleFonts.lexend(
                color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
      ],
    ),
  );
}

Widget _paymentTile(Payment p, NumberFormat rupee) {
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                    '${p.typeLabel} • ${p.method} • ${DateFormat('d MMM').format(p.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        fontSize: 11.5, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rupee.format(p.amount),
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
