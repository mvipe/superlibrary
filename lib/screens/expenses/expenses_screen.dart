import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late Future<List<Expense>> _future;
  final _rupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _future = Repo.instance.expenses();
  }

  void _reload() => setState(() => _future = Repo.instance.expenses());

  Future<void> _add() async {
    final ok = await _showForm();
    if (ok == true) _reload();
  }

  Future<void> _edit(Expense e) async {
    final ok = await _showForm(existing: e);
    if (ok == true) _reload();
  }

  Future<void> _delete(Expense e) async {
    final ok = await confirmDialog(context,
        title: 'Delete expense?', message: '"${e.title}" will be removed.');
    if (ok == true) {
      await Repo.instance.deleteExpense(e.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Manage Expenses'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: FutureBuilder<List<Expense>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final list = snap.data ?? [];
          final total = list.fold<double>(0, (s, e) => s + e.amount);
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.heroGradient),
                  borderRadius: BorderRadius.circular(AppColors.rLg),
                  boxShadow: AppTheme.heroShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Expenses',
                              style: GoogleFonts.lexend(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(_rupee.format(total),
                                style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 28)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppColors.rMd),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: list.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'No expenses yet',
                        subtitle: 'Tap + to record your first expense.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) => _tile(list[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(Expense e) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppColors.rMd)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('dd').format(e.spentOn),
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 16)),
                Text(DateFormat('MMM').format(e.spentOn),
                    style: GoogleFonts.lexend(
                        color: AppColors.primary, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                if (e.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(e.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                          fontSize: 12, color: AppColors.inkSoft)),
                ],
                const SizedBox(height: 4),
                Text(_rupee.format(e.amount),
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                        fontSize: 15)),
              ],
            ),
          ),
          IconButton(
              onPressed: () => _edit(e),
              icon: const Icon(Icons.edit_rounded,
                  size: 20, color: AppColors.info)),
          IconButton(
              onPressed: () => _delete(e),
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppColors.danger)),
        ],
      ),
    );
  }

  Future<bool?> _showForm({Expense? existing}) {
    final titleC = TextEditingController(text: existing?.title ?? '');
    final amountC =
        TextEditingController(text: existing?.amount.toStringAsFixed(0) ?? '');
    final noteC = TextEditingController(text: existing?.note ?? '');
    DateTime date = existing?.spentOn ?? DateTime.now();

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppColors.rXl))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'Add Expense' : 'Edit Expense',
                  style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w800, fontSize: 20)),
              const SizedBox(height: 18),
              _label('Date'),
              InkWell(
                borderRadius: BorderRadius.circular(AppColors.rMd),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setSheet(() => date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppColors.rMd),
                  ),
                  child: Row(
                    children: [
                      Text(DateFormat('d MMM yyyy').format(date),
                          style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Icon(Icons.calendar_month_rounded,
                          color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _label('Title'),
              TextField(
                controller: titleC,
                decoration:
                    const InputDecoration(hintText: 'e.g. Electricity Bill'),
              ),
              const SizedBox(height: 14),
              _label('Amount'),
              TextField(
                controller: amountC,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    hintText: '0', prefixText: '₹  '),
              ),
              const SizedBox(height: 14),
              _label('Note (optional)'),
              TextField(
                controller: noteC,
                decoration:
                    const InputDecoration(hintText: 'Short description'),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleC.text.trim();
                    final amount = double.tryParse(amountC.text.trim()) ?? 0;
                    if (title.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content:
                              Text('Enter a title and a valid amount')));
                      return;
                    }
                    if (existing == null) {
                      await Repo.instance.saveExpense(
                          Repo.instance.newExpense(
                              title: title,
                              amount: amount,
                              note: noteC.text.trim(),
                              spentOn: date),
                          isNew: true);
                    } else {
                      await Repo.instance.saveExpense(existing.copyWith(
                          title: title,
                          amount: amount,
                          note: noteC.text.trim(),
                          spentOn: date));
                    }
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: Text(existing == null ? 'Add Expense' : 'Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600, color: AppColors.ink)),
      );
}
