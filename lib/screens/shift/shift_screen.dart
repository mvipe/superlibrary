import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  late Future<List<Shift>> _future;
  final _rupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _future = Repo.instance.shifts();
  }

  void _reload() => setState(() => _future = Repo.instance.shifts());

  Future<void> _add() async {
    if (await _showForm() == true) _reload();
  }

  Future<void> _edit(Shift s) async {
    if (await _showForm(existing: s) == true) _reload();
  }

  Future<void> _delete(Shift s) async {
    final ok = await confirmDialog(context,
        title: 'Delete shift?', message: '"${s.name}" will be removed.');
    if (ok == true) {
      await Repo.instance.deleteShift(s.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Plans & Shifts'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child:
                PillButton(icon: Icons.add_rounded, label: 'Add', onTap: _add),
          ),
        ],
      ),
      body: FutureBuilder<List<Shift>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const EmptyState(
                icon: Icons.schedule_rounded, title: 'No shifts');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _tile(list[i]),
          );
        },
      ),
    );
  }

  Widget _tile(Shift s) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _edit(s),
      child: Row(
        children: [
          TintedIcon(
              icon: Icons.access_time_filled_rounded,
              color: AppColors.primary,
              bg: AppColors.primary.withValues(alpha: 0.1),
              box: 46,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700, fontSize: 15.5)),
                const SizedBox(height: 3),
                Text('${s.startTime} – ${s.endTime}',
                    style: GoogleFonts.lexend(
                        fontSize: 12.5, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_rupee.format(s.fee),
                  style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.success)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _delete(s),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 19, color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _showForm({Shift? existing}) {
    final nameC = TextEditingController(text: existing?.name ?? '');
    final startC = TextEditingController(text: existing?.startTime ?? '');
    final endC = TextEditingController(text: existing?.endTime ?? '');
    final feeC =
        TextEditingController(text: existing?.fee.toStringAsFixed(0) ?? '');

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppColors.rXl))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(existing == null ? 'Add Shift' : 'Edit Shift',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 18),
            TextField(
              controller: nameC,
              decoration: const InputDecoration(
                  hintText: 'Shift name (e.g. Morning)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startC,
                    decoration:
                        const InputDecoration(hintText: 'Start (06:00 AM)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: endC,
                    decoration:
                        const InputDecoration(hintText: 'End (12:00 PM)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feeC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration:
                  const InputDecoration(hintText: 'Monthly fee', prefixText: '₹  '),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameC.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Enter a shift name')));
                    return;
                  }
                  final fee = double.tryParse(feeC.text.trim()) ?? 0;
                  if (existing == null) {
                    await Repo.instance.saveShift(
                        Repo.instance.newShift(
                            name: name,
                            startTime: startC.text.trim(),
                            endTime: endC.text.trim(),
                            fee: fee),
                        isNew: true);
                  } else {
                    await Repo.instance.saveShift(existing.copyWith(
                        name: name,
                        startTime: startC.text.trim(),
                        endTime: endC.text.trim(),
                        fee: fee));
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: Text(existing == null ? 'Add Shift' : 'Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
