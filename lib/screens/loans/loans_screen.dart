import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

enum LoanView { issued, returned, overdue }

class LoansScreen extends StatefulWidget {
  final LoanView view;
  const LoansScreen({super.key, required this.view});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  late LoanView _view;

  @override
  void initState() {
    super.initState();
    _view = widget.view;
  }

  String get _title => switch (_view) {
        LoanView.issued => 'Issued Books',
        LoanView.returned => 'Returned Books',
        LoanView.overdue => 'Overdue Books',
      };

  Future<void> _returnLoan(Loan l) async {
    final ok = await confirmDialog(context,
        title: 'Return book?',
        message: '"${l.bookTitle}" from ${l.memberName} will be marked returned.',
        confirmLabel: 'Return',
        danger: false);
    if (ok != true) return;
    await Repo.instance.returnLoan(l);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${l.bookTitle}" returned')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: FilterTabs(
              tabs: const ['Issued', 'Returned', 'Overdue'],
              selected: _view.index,
              onChanged: (i) => setState(() => _view = LoanView.values[i]),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => setState(() {}),
              child: _view == LoanView.returned
                  ? _returnedList()
                  : _loanList(overdueOnly: _view == LoanView.overdue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loanList({required bool overdueOnly}) {
    return FutureBuilder<List<Loan>>(
      future: overdueOnly
          ? Repo.instance.overdueLoans()
          : Repo.instance.activeLoans(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final loans = snap.data!;
        if (loans.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: overdueOnly ? 'No overdue books' : 'No books issued',
                  subtitle: overdueOnly
                      ? 'Everything is returned on time. 🎉'
                      : 'Issue a book from Issue / Return.'),
            ],
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
          itemCount: loans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _loanTile(loans[i]),
        );
      },
    );
  }

  Widget _loanTile(Loan l) {
    final overdue = l.isOverdue;
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.info, AppColors.info.withValues(alpha: 0.7)]),
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
                Text(l.bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text('Issued to ${l.memberName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        fontSize: 12, color: AppColors.inkSoft)),
                const SizedBox(height: 4),
                if (l.dueAt != null)
                  Text(
                      overdue
                          ? 'Overdue by ${l.daysOverdue}d'
                          : 'Due ${DateFormat('d MMM').format(l.dueAt!)}',
                      style: GoogleFonts.lexend(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: overdue ? AppColors.danger : AppColors.inkSoft)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _returnLoan(l),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('Return'),
          ),
        ],
      ),
    );
  }

  Widget _returnedList() {
    return FutureBuilder<List<Transaction>>(
      future: Repo.instance.returnedTransactions(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              EmptyState(
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'No returns yet'),
            ],
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final t = list[i];
            return PremiumCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(AppColors.rMd)),
                    child: const Icon(Icons.south_west_rounded,
                        color: AppColors.success, size: 18),
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
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('Returned by ${t.memberName}',
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
            );
          },
        );
      },
    );
  }
}
