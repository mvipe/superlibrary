import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common.dart';
import '../payments/payments_screen.dart';
import '../attendance/attendance_screen.dart';
import '../members/members_screen.dart';
import '../books/books_screen.dart';
import '../issue_return/issue_return_screen.dart';
import '../reports/reports_screen.dart';
import '../seat/seat_screen.dart';
import '../expenses/expenses_screen.dart';
import '../expiring/expiring_screen.dart';
import '../ai/ai_assistant_screen.dart';
import '../branch/branch_screen.dart';
import '../reports/collection_report_screen.dart';
import '../master/master_screen.dart';
import '../shift/shift_screen.dart';
import '../loans/loans_screen.dart';
import '../notifications/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onMenu;
  const DashboardScreen({super.key, required this.onMenu});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _future;
  late Future<(List<Member>, Map<String, double>)> _expiring;

  @override
  void initState() {
    super.initState();
    _reloadAll();
    Repo.revision.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    Repo.revision.removeListener(_onDataChanged);
    super.dispose();
  }

  void _reloadAll() {
    _future = Repo.instance.dashboard();
    _expiring = _loadExpiring();
  }

  Future<(List<Member>, Map<String, double>)> _loadExpiring() async {
    final r = await Future.wait([
      Repo.instance.expiringSoon(days: 7),
      Repo.instance.duesByMember(),
    ]);
    return (r[0] as List<Member>, r[1] as Map<String, double>);
  }

  // Any write anywhere in the app bumps Repo.revision; refresh live stats.
  void _onDataChanged() {
    if (mounted) setState(_reloadAll);
  }

  Future<void> _refresh() async {
    setState(_reloadAll);
    await _future;
  }

  String get _greetWord {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final lib = SupabaseService.instance.library;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: FutureBuilder<DashboardData>(
            future: _future,
            builder: (context, snap) {
              final d = snap.data;
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                children: [
                  _topBar(context),
                  const SizedBox(height: 18),
                  _greeting(lib),
                  const SizedBox(height: 18),
                  _heroCard(d),
                  const SizedBox(height: 14),
                  _issuedRow(d),
                  const SizedBox(height: 22),
                  _expiringSection(context),
                  const SizedBox(height: 4),
                  const SectionHeader(title: 'Quick Access'),
                  const SizedBox(height: 14),
                  _quickAccess(context),
                  const SizedBox(height: 22),
                  _aiBanner(context),
                  const SizedBox(height: 26),
                  const SectionHeader(title: 'Recent Activities'),
                  const SizedBox(height: 12),
                  _recentActivities(d),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final libs = SupabaseService.instance.libraries;
    final current = SupabaseService.instance.library;
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onMenu,
          child: Container(
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.menu_rounded, size: 26),
          ),
        ),
        const Spacer(),
        // One-tap branch switcher chip.
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BranchScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppColors.rMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.account_tree_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90),
                  child: Text(current?.name ?? 'Branch',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink)),
                ),
                if (libs.length > 1) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.unfold_more_rounded,
                      size: 15, color: AppColors.inkFaint),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          borderRadius: BorderRadius.circular(AppColors.rMd),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.notifications_none_rounded, size: 26),
          ),
        ),
      ],
    );
  }

  Widget _greeting(Library? lib) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_greetWord, 👋',
                  style: GoogleFonts.lexend(
                      fontSize: 14.5, color: AppColors.inkSoft)),
              const SizedBox(height: 4),
              Text('${lib?.adminName ?? 'Admin'} (Admin)',
                  style: GoogleFonts.lexend(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 2),
              Text('Welcome to ${lib?.name ?? 'your library'}',
                  style: GoogleFonts.lexend(
                      fontSize: 14, color: AppColors.inkSoft)),
            ],
          ),
        ),
        Container(
          width: 84,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppColors.heroGradient),
            borderRadius: BorderRadius.circular(AppColors.rLg),
          ),
          child: const Icon(Icons.auto_stories_rounded,
              color: Colors.white, size: 36),
        ),
      ],
    );
  }

  Widget _heroCard(DashboardData? d) {
    final date = DateFormat('d MMM, yyyy | EEEE').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppColors.rXl),
        boxShadow: AppTheme.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Today's Overview",
                  style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(date,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroStat(Icons.how_to_reg_rounded, 'Live Members',
                  '${d?.liveMembers ?? 0}'),
              _heroStat(Icons.groups_rounded, 'Total Members',
                  '${d?.totalMembers ?? 0}'),
              _heroStat(Icons.credit_card_rounded, 'Active',
                  '${d?.activeMemberships ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String label, String value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _push(const MembersScreen()),
        behavior: HitTestBehavior.opaque,
        child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppColors.rMd),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9.5,
                        height: 1.1)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _issuedRow(DashboardData? d) {
    return Row(
      children: [
        Expanded(
          child: _issuedCard(Icons.library_books_rounded, AppColors.info,
              AppColors.infoBg, 'Books Issued', '${d?.booksIssued ?? 0}',
              () => _push(const LoansScreen(view: LoanView.issued))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _issuedCard(
              Icons.assignment_turned_in_rounded,
              AppColors.success,
              AppColors.successBg,
              'Books Returned',
              '${d?.booksReturned ?? 0}',
              () => _push(const LoansScreen(view: LoanView.returned))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _issuedCard(Icons.error_outline_rounded, AppColors.danger,
              AppColors.dangerBg, 'Overdue Books', '${d?.overdueBooks ?? 0}',
              () => _push(const LoansScreen(view: LoanView.overdue))),
        ),
      ],
    );
  }

  void _push(Widget screen) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => screen));

  Widget _issuedCard(IconData icon, Color color, Color bg, String label,
      String value, VoidCallback onTap) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TintedIcon(icon: icon, color: color, bg: bg, box: 38, size: 19),
          const SizedBox(height: 10),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  GoogleFonts.lexend(fontSize: 11, color: AppColors.inkSoft)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.lexend(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _quickAccess(BuildContext context) {
    final items = <(IconData, Color, Color, String, Widget)>[
      (Icons.person_add_alt_1_rounded, const Color(0xFF7C3AED),
          AppColors.tintPurple, 'Members', const MembersScreen()),
      (Icons.menu_book_rounded, AppColors.info, AppColors.tintBlue, 'Books',
          const BooksScreen()),
      (Icons.swap_horiz_rounded, AppColors.warning, AppColors.tintAmber,
          'Issue / Return', const IssueReturnScreen()),
      (Icons.currency_rupee_rounded, AppColors.success, AppColors.tintMint,
          'Payments', const PaymentsScreen()),
      (Icons.event_seat_rounded, const Color(0xFF0EA5A0), AppColors.tintMint,
          'Seat', const SeatScreen()),
      (Icons.calendar_month_rounded, const Color(0xFFEC4899),
          AppColors.tintPink, 'Attendance', const AttendanceScreen()),
      (Icons.timelapse_rounded, AppColors.danger, AppColors.dangerBg,
          'Plan Expiry', const ExpiringScreen()),
      (Icons.receipt_long_rounded, AppColors.success, AppColors.tintMint,
          'Collection', const CollectionReportScreen()),
      (Icons.account_balance_wallet_rounded, AppColors.warning,
          AppColors.tintAmber, 'Expenses', const ExpensesScreen()),
      (Icons.access_time_filled_rounded, const Color(0xFF0EA5A0),
          AppColors.tintMint, 'Plans', const ShiftScreen()),
      (Icons.dashboard_customize_rounded, const Color(0xFF7C3AED),
          AppColors.tintPurple, 'Master', const MasterScreen()),
      (Icons.bar_chart_rounded, const Color(0xFF7C3AED), AppColors.tintPurple,
          'Reports', const ReportsScreen()),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (context, i) {
        final it = items[i];
        return GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => it.$5)),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppColors.rLg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Center(
                  child: TintedIcon(
                      icon: it.$1, color: it.$2, bg: it.$3, box: 44, size: 22),
                ),
              ),
              const SizedBox(height: 6),
              Text(it.$4,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexend(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink)),
            ],
          ),
        );
      },
    );
  }

  Widget _aiBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AiAssistantScreen())),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tintPurple.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppColors.rLg),
        border: Border.all(color: const Color(0xFFE3DBFB)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppColors.rMd),
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Color(0xFF7C3AED), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('AI Assistant',
                        style: GoogleFonts.lexend(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    const SizedBox(width: 8),
                    StatusChip(
                        label: 'NEW',
                        color: Colors.white,
                        bg: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Ask anything about your library',
                    style: GoogleFonts.lexend(
                        fontSize: 12.5, color: AppColors.inkSoft)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.inkFaint),
        ],
      ),
    ),
    );
  }

  Widget _expiringSection(BuildContext context) {
    return FutureBuilder<(List<Member>, Map<String, double>)>(
      future: _expiring,
      builder: (context, snap) {
        final members = snap.data?.$1 ?? [];
        if (members.isEmpty) return const SizedBox.shrink();
        final dues = snap.data?.$2 ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
                title: 'Memberships Expiring',
                actionLabel: 'View All',
                onAction: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExpiringScreen()))),
            const SizedBox(height: 12),
            ...members.take(3).map((m) {
              final d = m.expiresAt!.difference(DateTime.now()).inDays;
              final expired = d < 0;
              final due = dues[m.id] ?? 0;
              final label = expired
                  ? 'Expired ${-d}d ago'
                  : d == 0
                      ? 'Today'
                      : 'in $d days';
              final color = expired
                  ? AppColors.danger
                  : (d <= 3 ? AppColors.warning : AppColors.info);
              final bg = expired
                  ? AppColors.dangerBg
                  : (d <= 3 ? AppColors.warningBg : AppColors.infoBg);
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lexend(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5)),
                            Text(
                                '${m.plan ?? 'No plan'}${due > 0 ? ' • Due ₹${due.toStringAsFixed(0)}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lexend(
                                    fontSize: 12,
                                    color: due > 0
                                        ? AppColors.danger
                                        : AppColors.inkSoft)),
                          ],
                        ),
                      ),
                      StatusChip(label: label, color: color, bg: bg),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }

  Widget _recentActivities(DashboardData? d) {
    final acts = d?.recent ?? [];
    if (acts.isEmpty) {
      return const EmptyState(
          icon: Icons.history_rounded,
          title: 'No activity yet',
          subtitle: 'Issue or return a book to see it here.');
    }
    return Column(
      children: acts.map((t) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Avatar(name: t.memberName, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(t.bookTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lexend(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    color: AppColors.ink)),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                              t.isReturn
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              size: 14,
                              color: t.isReturn
                                  ? AppColors.success
                                  : AppColors.info),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                          '${t.isReturn ? 'Returned by' : 'Issued to'} ${t.memberName}',
                          style: GoogleFonts.lexend(
                              fontSize: 12, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                Text(_timeAgo(t.time),
                    style: GoogleFonts.lexend(
                        fontSize: 11.5, color: AppColors.inkFaint)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
