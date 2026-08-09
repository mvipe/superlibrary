import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common.dart';
import 'collect_fee.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  int _filter = 0;
  late Future<List<Payment>> _future;
  late Future<PaymentTotals> _totals;
  static const _tabs = ['All', 'Paid', 'Pending', 'Overdue'];
  final _rupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Repo.instance.payments();
    _totals = Repo.instance.paymentTotals();
  }

  void _reload() => setState(_load);

  List<Payment> _apply(List<Payment> list) => switch (_filter) {
        1 => list.where((p) => p.status == PaymentStatus.paid).toList(),
        2 => list.where((p) => p.status == PaymentStatus.pending).toList(),
        3 => list.where((p) => p.status == PaymentStatus.overdue).toList(),
        _ => list,
      };

  Future<void> _collect() async {
    final saved = await showCollectFee(context);
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Payments'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
            child: FutureBuilder<PaymentTotals>(
              future: _totals,
              builder: (context, snap) {
                final t = snap.data ??
                    PaymentTotals(collection: 0, fine: 0, pending: 0);
                return Row(
                  children: [
                    _summaryTile(
                        'Total Collection',
                        _rupee.format(t.collection),
                        AppColors.success,
                        AppColors.successBg,
                        Icons.trending_up_rounded),
                    const SizedBox(width: 10),
                    _summaryTile('Fine Collected', _rupee.format(t.fine),
                        AppColors.warning, AppColors.warningBg,
                        Icons.error_outline_rounded),
                    const SizedBox(width: 10),
                    _summaryTile('Pending', _rupee.format(t.pending),
                        AppColors.danger, AppColors.dangerBg,
                        Icons.schedule_rounded),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: FilterTabs(
                tabs: _tabs,
                selected: _filter,
                onChanged: (i) => setState(() => _filter = i)),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<Payment>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                final filtered = _apply(snap.data ?? []);
                if (filtered.isEmpty) {
                  return const EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No payments yet',
                      subtitle: 'Collect a fee to see it here.');
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _paymentTile(filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: _collect,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('Collect Fee',
              style: GoogleFonts.lexend(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _summaryTile(
      String label, String value, Color color, Color bg, IconData icon) {
    return Expanded(
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
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(AppColors.rSm)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lexend(
                    fontSize: 10.5, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  String _receiptText(Payment p) {
    final lib = SupabaseService.instance.library;
    final f = DateFormat('d MMM yyyy, h:mm a');
    return '''
======= FEE RECEIPT =======
${lib?.name ?? 'SuperLibrary'}

Receipt No : ${p.id.substring(p.id.length >= 6 ? p.id.length - 6 : 0).toUpperCase()}
Date       : ${f.format(p.date)}
Member     : ${p.memberName} (${p.memberCode})
For        : ${p.typeLabel}
Method     : ${p.method}
Status     : ${p.status.label}

Amount     : ${_rupee.format(p.amount)}
===========================
Thank you!''';
  }

  void _showReceipt(Payment p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppColors.rXl))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Fee Receipt',
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.scaffold,
                  borderRadius: BorderRadius.circular(AppColors.rMd),
                  border: Border.all(color: AppColors.border)),
              child: Text(_receiptText(p),
                  style: GoogleFonts.robotoMono(
                      fontSize: 12.5, height: 1.5, color: AppColors.ink)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _receiptText(p)));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Receipt copied')));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Share.share(_receiptText(p),
                          subject: 'Fee Receipt — ${p.memberName}');
                    },
                    icon: const Icon(Icons.ios_share_rounded,
                        size: 18, color: Colors.white),
                    label: const Text('Share / Download'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentTile(Payment p) {
    final isFine = p.type == PaymentType.fine;
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _showReceipt(p),
      child: Row(
        children: [
          Avatar(name: p.memberName, url: p.photoUrl, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.memberName,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                        isFine
                            ? Icons.error_outline_rounded
                            : Icons.verified_rounded,
                        size: 13,
                        color: isFine ? AppColors.warning : AppColors.success),
                    const SizedBox(width: 4),
                    Text('${p.typeLabel} • ${p.method}',
                        style: GoogleFonts.lexend(
                            fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(DateFormat('d MMM yyyy').format(p.date),
                    style: GoogleFonts.lexend(
                        fontSize: 11.5, color: AppColors.inkFaint)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_rupee.format(p.amount),
                  style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isFine ? AppColors.danger : AppColors.ink)),
              const SizedBox(height: 6),
              StatusChip(
                  label: p.status.label,
                  color: p.status.color,
                  bg: p.status.bg),
            ],
          ),
        ],
      ),
    );
  }
}
