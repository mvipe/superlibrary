import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common.dart';

final _rupee =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  late Future<List<Invoice>> _future;

  @override
  void initState() {
    super.initState();
    _future = Repo.instance.invoices();
  }

  void _reload() => setState(() => _future = Repo.instance.invoices());

  Future<void> _create() async {
    final no = await Repo.instance.nextInvoiceNo();
    if (!mounted) return;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _InvoiceForm(invoiceNo: no)),
    );
    if (ok == true) _reload();
  }

  String invoiceText(Invoice inv) {
    final lib = SupabaseService.instance.library;
    final b = StringBuffer()
      ..writeln('========== INVOICE ==========')
      ..writeln(lib?.name ?? 'SuperLibrary')
      ..writeln('')
      ..writeln('Invoice : ${inv.invoiceNo}')
      ..writeln('Date    : ${DateFormat('d MMM yyyy').format(inv.date)}')
      ..writeln('Bill To : ${inv.billTo}${inv.phone.isNotEmpty ? ' (${inv.phone})' : ''}')
      ..writeln('-----------------------------');
    for (final it in inv.items) {
      b.writeln('${it.description}  —  ${_rupee.format(it.amount)}');
    }
    b
      ..writeln('-----------------------------')
      ..writeln('Subtotal : ${_rupee.format(inv.subtotal)}')
      ..writeln('Tax (${inv.taxPercent.toStringAsFixed(inv.taxPercent % 1 == 0 ? 0 : 1)}%) : ${_rupee.format(inv.taxAmount)}')
      ..writeln('TOTAL    : ${_rupee.format(inv.total)}');
    if (inv.notes.isNotEmpty) b.writeln('\nNote: ${inv.notes}');
    b.writeln('\nThank you!');
    return b.toString();
  }

  void _view(Invoice inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            Text('Invoice ${inv.invoiceNo}',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.scaffold,
                  borderRadius: BorderRadius.circular(AppColors.rMd),
                  border: Border.all(color: AppColors.border)),
              child: Text(invoiceText(inv),
                  style: GoogleFonts.robotoMono(fontSize: 12, height: 1.5)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: invoiceText(inv)));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invoice copied')));
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
                      Share.share(invoiceText(inv),
                          subject: 'Invoice ${inv.invoiceNo}');
                    },
                    icon: const Icon(Icons.ios_share_rounded,
                        size: 18, color: Colors.white),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await confirmDialog(context,
                      title: 'Delete invoice?',
                      message: '${inv.invoiceNo} will be removed.');
                  if (ok == true) {
                    await Repo.instance.deleteInvoice(inv.id);
                    _reload();
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger, size: 18),
                label: Text('Delete',
                    style: GoogleFonts.lexend(color: AppColors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Invoices'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Invoice',
            style: GoogleFonts.lexend(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: FutureBuilder<List<Invoice>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No invoices yet',
                subtitle: 'Tap New Invoice to generate one.');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final inv = list[i];
              return PremiumCard(
                padding: const EdgeInsets.all(14),
                onTap: () => _view(inv),
                child: Row(
                  children: [
                    TintedIcon(
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        bg: AppColors.primary.withValues(alpha: 0.1),
                        box: 46,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inv.invoiceNo,
                              style: GoogleFonts.lexend(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(
                              '${inv.billTo} • ${DateFormat('d MMM yyyy').format(inv.date)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lexend(
                                  fontSize: 12.5, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                    Text(_rupee.format(inv.total),
                        style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InvoiceForm extends StatefulWidget {
  final String invoiceNo;
  const _InvoiceForm({required this.invoiceNo});

  @override
  State<_InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<_InvoiceForm> {
  final _billTo = TextEditingController();
  final _phone = TextEditingController();
  final _tax = TextEditingController(text: '0');
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  final List<({TextEditingController desc, TextEditingController amt})> _items = [
    (desc: TextEditingController(), amt: TextEditingController()),
  ];
  bool _saving = false;

  double get _subtotal => _items.fold(
      0, (s, it) => s + (double.tryParse(it.amt.text.trim()) ?? 0));
  double get _taxPct => double.tryParse(_tax.text.trim()) ?? 0;
  double get _total => _subtotal + _subtotal * _taxPct / 100;

  @override
  void dispose() {
    _billTo.dispose();
    _phone.dispose();
    _tax.dispose();
    _notes.dispose();
    for (final it in _items) {
      it.desc.dispose();
      it.amt.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_billTo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter who the invoice is for')));
      return;
    }
    final items = _items
        .where((it) =>
            it.desc.text.trim().isNotEmpty ||
            (double.tryParse(it.amt.text.trim()) ?? 0) > 0)
        .map((it) => InvoiceItem(
            description: it.desc.text.trim(),
            amount: double.tryParse(it.amt.text.trim()) ?? 0))
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one item')));
      return;
    }
    setState(() => _saving = true);
    try {
      await Repo.instance.saveInvoice(
        Repo.instance.newInvoice(
          invoiceNo: widget.invoiceNo,
          billTo: _billTo.text.trim(),
          phone: _phone.text.trim(),
          date: _date,
          items: items,
          taxPercent: _taxPct,
          notes: _notes.text.trim(),
        ),
        isNew: true,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text('New Invoice • ${widget.invoiceNo}'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        color: AppColors.card,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white))
              : Text('Save Invoice • ${_rupee.format(_total)}'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _field('Bill To', _billTo, 'Member / customer name'),
          _field('Phone (optional)', _phone, 'Phone',
              keyboard: TextInputType.phone),
          _label('Date'),
          InkWell(
            borderRadius: BorderRadius.circular(AppColors.rMd),
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100));
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppColors.rMd)),
              child: Row(
                children: [
                  Text(DateFormat('d MMM yyyy').format(_date),
                      style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(Icons.calendar_month_rounded,
                      color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Items',
                  style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _items.add((
                      desc: TextEditingController(),
                      amt: TextEditingController()
                    ))),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add item'),
              ),
            ],
          ),
          ..._items.asMap().entries.map((e) {
            final it = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: it.desc,
                      decoration: const InputDecoration(hintText: 'Description'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: it.amt,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration:
                          const InputDecoration(hintText: '0', prefixText: '₹ '),
                    ),
                  ),
                  if (_items.length > 1)
                    IconButton(
                      onPressed: () => setState(() => _items.removeAt(e.key)),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.inkFaint),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          _field('Tax %', _tax, '0',
              keyboard: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {})),
          _field('Notes (optional)', _notes, 'Any note'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppColors.rLg),
                border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                _sum('Subtotal', _subtotal),
                const SizedBox(height: 6),
                _sum('Tax', _subtotal * _taxPct / 100),
                const Divider(height: 20),
                _sum('Total', _total, bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sum(String label, double v, {bool bold = false}) => Row(
        children: [
          Text(label,
              style: GoogleFonts.lexend(
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  color: bold ? AppColors.ink : AppColors.inkSoft)),
          const Spacer(),
          Text(_rupee.format(v),
              style: GoogleFonts.lexend(
                  fontSize: bold ? 16 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(t,
            style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: AppColors.inkSoft)),
      );

  Widget _field(String label, TextEditingController c, String hint,
      {TextInputType? keyboard,
      List<TextInputFormatter>? formatters,
      ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: c,
          keyboardType: keyboard,
          inputFormatters: formatters,
          onChanged: onChanged,
          decoration: InputDecoration(hintText: hint),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
