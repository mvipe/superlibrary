import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import 'member_form.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  int _filter = 0;
  String _query = '';
  late Future<List<Member>> _future;
  static const _tabs = ['All', 'Active', 'Inactive', 'Expired'];

  @override
  void initState() {
    super.initState();
    _future = Repo.instance.members();
  }

  void _reload() => setState(() => _future = Repo.instance.members());

  List<Member> _apply(List<Member> list) {
    var l = list;
    if (_filter == 1) {
      l = l.where((m) => m.status == MemberStatus.active).toList();
    }
    if (_filter == 2) {
      l = l.where((m) => m.status == MemberStatus.inactive).toList();
    }
    if (_filter == 3) {
      l = l.where((m) => m.status == MemberStatus.expired).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      l = l
          .where((m) =>
              m.name.toLowerCase().contains(q) ||
              m.memberCode.toLowerCase().contains(q) ||
              m.phone.contains(q))
          .toList();
    }
    return l;
  }

  Future<void> _add() async {
    final code = await Repo.instance.nextMemberCode();
    if (!mounted) return;
    final saved = await showMemberForm(context, suggestedCode: code);
    if (saved == true) {
      // Jump back to the "All" tab so the newly added member is visible.
      setState(() {
        _filter = 0;
        _query = '';
        _future = Repo.instance.members();
      });
    }
  }

  Future<void> _edit(Member m) async {
    final saved = await showMemberForm(context, existing: m);
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Members'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context))
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: PillButton(
                icon: Icons.add_rounded, label: 'Add', onTap: _add),
          ),
        ],
      ),
      body: FutureBuilder<List<Member>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final all = snap.data ?? [];
          final total = all.length;
          final active =
              all.where((m) => m.status == MemberStatus.active).length;
          final expired =
              all.where((m) => m.status == MemberStatus.expired).length;
          final filtered = _apply(all);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: Row(
                  children: [
                    _miniStat(
                        'Total', '$total', AppColors.info, AppColors.infoBg),
                    const SizedBox(width: 10),
                    _miniStat('Active', '$active', AppColors.success,
                        AppColors.successBg),
                    const SizedBox(width: 10),
                    _miniStat('Expired', '$expired', AppColors.danger,
                        AppColors.dangerBg),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, ID or mobile',
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 20, color: AppColors.inkFaint),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: FilterTabs(
                    tabs: _tabs,
                    selected: _filter,
                    onChanged: (i) => setState(() => _filter = i)),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final f = Repo.instance.members();
                    setState(() => _future = f);
                    await f;
                  },
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            EmptyState(
                                icon: Icons.groups_rounded,
                                title: 'No members yet',
                                subtitle:
                                    'Tap Add to register your first member.'),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _memberTile(filtered[i]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
              height: 4,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            Text(label,
                style: GoogleFonts.lexend(
                    fontSize: 11.5, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  Widget _memberTile(Member m) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _edit(m),
      child: Row(
        children: [
          Avatar(name: m.name, url: m.photoUrl, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(m.memberCode,
                        style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft)),
                    const SizedBox(width: 6),
                    Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                            color: AppColors.inkFaint,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(m.email.isEmpty ? m.phone : m.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexend(
                              fontSize: 12, color: AppColors.inkFaint)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(
                  label: m.status.label,
                  color: m.status.color,
                  bg: m.status.bg),
              const SizedBox(height: 2),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 20, color: AppColors.inkFaint),
                onSelected: (v) {
                  if (v == 'edit') _edit(m);
                  if (v == 'active') _setStatus(m, MemberStatus.active);
                  if (v == 'inactive') _setStatus(m, MemberStatus.inactive);
                  if (v == 'delete') _confirmDelete(m);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (m.status != MemberStatus.active)
                    const PopupMenuItem(
                        value: 'active', child: Text('Mark Active')),
                  if (m.status != MemberStatus.inactive)
                    const PopupMenuItem(
                        value: 'inactive', child: Text('Mark Inactive')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setStatus(Member m, MemberStatus status) async {
    await Repo.instance.updateMember(m.copyWith(status: status));
    _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${m.name} marked ${status.label}')));
    }
  }

  Future<void> _confirmDelete(Member m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.rLg)),
        title: const Text('Delete member?'),
        content: Text('${m.name} will be removed permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style: GoogleFonts.lexend(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      await Repo.instance.deleteMember(m.id);
      _reload();
    }
  }
}
