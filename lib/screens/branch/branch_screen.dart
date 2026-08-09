import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common.dart';
import '../main_shell.dart';

class BranchScreen extends StatefulWidget {
  const BranchScreen({super.key});

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  bool _busy = false;

  List<Library> get _libs => SupabaseService.instance.libraries;
  String? get _currentId => SupabaseService.instance.libraryId;

  Future<void> _switch(Library lib) async {
    if (lib.id == _currentId) return;
    setState(() => _busy = true);
    await SupabaseService.instance.switchLibrary(lib.id);
    Repo.revision.value++;
    if (!mounted) return;
    // Rebuild the whole shell so every tab reflects the new branch.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  Future<void> _add() async {
    if (await _showForm() == true && mounted) setState(() {});
  }

  Future<void> _edit(Library lib) async {
    if (await _showForm(existing: lib) == true && mounted) setState(() {});
  }

  Future<void> _delete(Library lib) async {
    if (_libs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You must have at least one library.')));
      return;
    }
    final ok = await confirmDialog(context,
        title: 'Delete branch?',
        message:
            '"${lib.name}" and its data will be removed. This cannot be undone.');
    if (ok == true) {
      await SupabaseService.instance.deleteLibrary(lib.id);
      Repo.revision.value++;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Branch Management'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child:
                PillButton(icon: Icons.add_rounded, label: 'New', onTap: _add),
          ),
        ],
      ),
      body: _busy
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
              children: [
                Text('Switch between your libraries. All data (members, seats, '
                    'payments...) is kept separate per branch.',
                    style: GoogleFonts.lexend(
                        fontSize: 12.5, color: AppColors.inkSoft)),
                const SizedBox(height: 16),
                ..._libs.map(_tile),
              ],
            ),
    );
  }

  Widget _tile(Library lib) {
    final active = lib.id == _currentId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.rLg),
        onTap: active ? null : () => _switch(lib),
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.06) : AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.rLg),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
              width: active ? 1.4 : 1),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.heroGradient),
                  borderRadius: BorderRadius.circular(AppColors.rMd)),
              child: const Icon(Icons.local_library_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(lib.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w700, fontSize: 15.5)),
                      ),
                      if (active) ...[
                        const SizedBox(width: 8),
                        const StatusChip(
                            label: 'Current',
                            color: Colors.white,
                            bg: AppColors.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${lib.adminName} • ${lib.totalSeats} seats',
                      style: GoogleFonts.lexend(
                          fontSize: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.inkSoft),
              onSelected: (v) {
                if (v == 'switch') _switch(lib);
                if (v == 'edit') _edit(lib);
                if (v == 'delete') _delete(lib);
              },
              itemBuilder: (_) => [
                if (!active)
                  const PopupMenuItem(
                      value: 'switch', child: Text('Switch to this')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<bool?> _showForm({Library? existing}) {
    final nameC = TextEditingController(text: existing?.name ?? '');
    final adminC = TextEditingController(
        text: existing?.adminName ??
            SupabaseService.instance.library?.adminName ??
            '');
    final emailC = TextEditingController(text: existing?.adminEmail ?? '');
    final seatsC =
        TextEditingController(text: (existing?.totalSeats ?? 30).toString());

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
            Text(existing == null ? 'New Branch' : 'Edit Branch',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 18),
            TextField(
              controller: nameC,
              decoration:
                  const InputDecoration(hintText: 'Library / branch name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adminC,
              decoration: const InputDecoration(hintText: 'Admin name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(hintText: 'Admin email (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: seatsC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration:
                  const InputDecoration(hintText: 'Total seats (e.g. 65)'),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameC.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Enter a branch name')));
                    return;
                  }
                  final seats = int.tryParse(seatsC.text.trim()) ?? 30;
                  if (existing == null) {
                    await SupabaseService.instance.createLibrary(
                      name: name,
                      adminName: adminC.text.trim().isEmpty
                          ? 'Admin'
                          : adminC.text.trim(),
                      adminEmail: emailC.text.trim(),
                      totalSeats: seats,
                    );
                    Repo.revision.value++;
                  } else {
                    await SupabaseService.instance.updateLibrary(
                        existing.copyWith(
                            name: name,
                            adminName: adminC.text.trim(),
                            adminEmail: emailC.text.trim(),
                            totalSeats: seats));
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: Text(existing == null ? 'Create Branch' : 'Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
