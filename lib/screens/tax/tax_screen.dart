import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key});

  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  late Future<List<Tax>> _future;

  @override
  void initState() {
    super.initState();
    _future = Repo.instance.taxes();
  }

  void _reload() => setState(() => _future = Repo.instance.taxes());

  Future<void> _add() async {
    if (await _showForm() == true) _reload();
  }

  Future<void> _edit(Tax t) async {
    if (await _showForm(existing: t) == true) _reload();
  }

  Future<void> _delete(Tax t) async {
    final ok = await confirmDialog(context,
        title: 'Delete tax?', message: '"${t.name}" will be removed.');
    if (ok == true) {
      await Repo.instance.deleteTax(t.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Tax Management'),
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
      body: FutureBuilder<List<Tax>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const EmptyState(
                icon: Icons.percent_rounded,
                title: 'No taxes',
                subtitle: 'Add GST or service charges applied on fees.');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final t = list[i];
              return PremiumCard(
                padding: const EdgeInsets.all(14),
                onTap: () => _edit(t),
                child: Row(
                  children: [
                    TintedIcon(
                        icon: Icons.percent_rounded,
                        color: AppColors.info,
                        bg: AppColors.infoBg,
                        box: 46,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(t.name,
                          style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w700, fontSize: 15.5)),
                    ),
                    Text('${t.percent.toStringAsFixed(t.percent % 1 == 0 ? 0 : 1)}%',
                        style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.primary)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _delete(t),
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 19, color: AppColors.danger),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _showForm({Tax? existing}) {
    final nameC = TextEditingController(text: existing?.name ?? '');
    final pctC =
        TextEditingController(text: existing?.percent.toString() ?? '');

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
            Text(existing == null ? 'Add Tax' : 'Edit Tax',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 18),
            TextField(
              controller: nameC,
              decoration: const InputDecoration(
                  hintText: 'Tax name (e.g. GST)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pctC,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(hintText: 'Percentage', suffixText: '%'),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameC.text.trim();
                  final pct = double.tryParse(pctC.text.trim()) ?? 0;
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Enter a tax name')));
                    return;
                  }
                  if (existing == null) {
                    await Repo.instance.saveTax(
                        Repo.instance.newTax(name: name, percent: pct),
                        isNew: true);
                  } else {
                    await Repo.instance.saveTax(
                        existing.copyWith(name: name, percent: pct));
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: Text(existing == null ? 'Add Tax' : 'Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
