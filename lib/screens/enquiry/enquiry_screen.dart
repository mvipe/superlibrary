import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';

class EnquiryScreen extends StatefulWidget {
  const EnquiryScreen({super.key});

  @override
  State<EnquiryScreen> createState() => _EnquiryScreenState();
}

class _EnquiryScreenState extends State<EnquiryScreen> {
  late Future<List<Enquiry>> _future;
  int _filter = 0;
  static const _tabs = ['All', 'New', 'Follow Up', 'Converted', 'Closed'];

  @override
  void initState() {
    super.initState();
    _future = Repo.instance.enquiries();
  }

  void _reload() => setState(() => _future = Repo.instance.enquiries());

  List<Enquiry> _apply(List<Enquiry> list) {
    return switch (_filter) {
      1 => list.where((e) => e.status == EnquiryStatus.fresh).toList(),
      2 => list.where((e) => e.status == EnquiryStatus.followUp).toList(),
      3 => list.where((e) => e.status == EnquiryStatus.converted).toList(),
      4 => list.where((e) => e.status == EnquiryStatus.closed).toList(),
      _ => list,
    };
  }

  Future<void> _add() async {
    if (await _showForm() == true) _reload();
  }

  Future<void> _edit(Enquiry e) async {
    if (await _showForm(existing: e) == true) _reload();
  }

  Future<void> _delete(Enquiry e) async {
    final ok = await confirmDialog(context,
        title: 'Delete enquiry?', message: '${e.name} will be removed.');
    if (ok == true) {
      await Repo.instance.deleteEnquiry(e.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Enquiry Management'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
            child: FilterTabs(
                tabs: _tabs,
                selected: _filter,
                onChanged: (i) => setState(() => _filter = i)),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<Enquiry>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                final list = _apply(snap.data ?? []);
                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.assignment_rounded,
                      title: 'No enquiries',
                      subtitle: 'Add a walk-in lead with the Add button.');
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _tile(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Enquiry e) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _edit(e),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(name: e.name, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded,
                            size: 12, color: AppColors.inkFaint),
                        const SizedBox(width: 4),
                        Text(e.phone,
                            style: GoogleFonts.lexend(
                                fontSize: 12, color: AppColors.inkSoft)),
                      ],
                    ),
                  ],
                ),
              ),
              StatusChip(
                  label: e.status.label,
                  color: e.status.color,
                  bg: e.status.bg),
            ],
          ),
          if (e.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.scaffold,
                  borderRadius: BorderRadius.circular(AppColors.rMd)),
              child: Text(e.note,
                  style: GoogleFonts.lexend(
                      fontSize: 12.5, color: AppColors.inkSoft)),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(DateFormat('d MMM yyyy, h:mm a').format(e.createdAt),
                  style: GoogleFonts.lexend(
                      fontSize: 11, color: AppColors.inkFaint)),
              const Spacer(),
              InkWell(
                onTap: () => _delete(e),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 19, color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _showForm({Enquiry? existing}) {
    final nameC = TextEditingController(text: existing?.name ?? '');
    final phoneC = TextEditingController(text: existing?.phone ?? '');
    final noteC = TextEditingController(text: existing?.note ?? '');
    EnquiryStatus status = existing?.status ?? EnquiryStatus.fresh;

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
              Text(existing == null ? 'Add Enquiry' : 'Edit Enquiry',
                  style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w800, fontSize: 20)),
              const SizedBox(height: 18),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                    hintText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneC,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    hintText: 'Mobile number',
                    prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteC,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Note (shift interest, follow-up date...)'),
              ),
              const SizedBox(height: 14),
              Text('Status',
                  style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: EnquiryStatus.values.map((s) {
                  final active = s == status;
                  return GestureDetector(
                    onTap: () => setSheet(() => status = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? s.color : AppColors.card,
                        borderRadius: BorderRadius.circular(AppColors.rMd),
                        border: Border.all(
                            color: active ? s.color : AppColors.border),
                      ),
                      child: Text(s.label,
                          style: GoogleFonts.lexend(
                              color: active ? Colors.white : AppColors.inkSoft,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameC.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Enter a name')));
                      return;
                    }
                    if (existing == null) {
                      await Repo.instance.saveEnquiry(
                          Repo.instance.newEnquiry(
                              name: name,
                              phone: phoneC.text.trim(),
                              note: noteC.text.trim(),
                              status: status),
                          isNew: true);
                    } else {
                      await Repo.instance.saveEnquiry(existing.copyWith(
                          name: name,
                          phone: phoneC.text.trim(),
                          note: noteC.text.trim(),
                          status: status));
                    }
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: Text(existing == null ? 'Add Enquiry' : 'Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
