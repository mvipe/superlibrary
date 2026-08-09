import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common.dart';
import '../scan/scan_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final bool startOnScan;
  const AttendanceScreen({super.key, this.startOnScan = false});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _memberId = TextEditingController();
  late Future<List<AttendanceEntry>> _future;
  bool _marking = false;

  @override
  void initState() {
    super.initState();
    _future = Repo.instance.attendance();
    if (widget.startOnScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    }
  }

  @override
  void dispose() {
    _memberId.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = Repo.instance.attendance());

  Future<void> _markByCode(String code) async {
    final query = code.trim().toLowerCase();
    if (query.isEmpty) return;
    setState(() => _marking = true);
    final members = await Repo.instance.members();
    Member? match;
    for (final m in members) {
      if (m.memberCode.toLowerCase() == query ||
          m.id.toLowerCase() == query ||
          m.phone.replaceAll(RegExp(r'[^0-9]'), '').contains(query)) {
        match = m;
        break;
      }
    }
    if (match == null) {
      if (!mounted) return;
      setState(() => _marking = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No member found for "$code"')));
      return;
    }
    await Repo.instance.markAttendance(match, AttendanceState.present);
    _memberId.clear();
    if (!mounted) return;
    setState(() => _marking = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${match.name} marked present'),
        backgroundColor: AppColors.success));
    _reload();
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
          builder: (_) => const ScanScreen(title: 'Scan Member QR')),
    );
    if (code != null) _markByCode(code);
  }

  Future<void> _export() async {
    final list = await Repo.instance.attendance();
    final lib = SupabaseService.instance.library?.name ?? 'Library';
    final today = DateFormat('d MMM yyyy').format(DateTime.now());
    final buf = StringBuffer()
      ..writeln('$lib — Attendance Report ($today)')
      ..writeln('')
      ..writeln('Name,Time,Status');
    for (final a in list) {
      buf.writeln('${a.memberName},${a.time},${a.state.label}');
    }
    buf.writeln('');
    buf.writeln('Present: ${list.where((a) => a.state == AttendanceState.present).length}');
    buf.writeln('Absent: ${list.where((a) => a.state == AttendanceState.absent).length}');
    await Share.share(buf.toString(),
        subject: '$lib Attendance — $today');
  }

  Future<void> _pickMember() async {
    final members = await Repo.instance.members();
    if (!mounted) return;
    final m = await showSearchablePicker<Member>(
      context,
      title: 'Mark attendance for',
      items: members,
      label: (m) => m.name,
      subtitle: (m) => '${m.memberCode} • ${m.phone}',
      searchHint: 'Search by name, ID or phone',
    );
    if (m == null) return;
    setState(() => _marking = true);
    await Repo.instance.markAttendance(m, AttendanceState.present);
    if (!mounted) return;
    setState(() => _marking = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${m.name} marked present'),
        backgroundColor: AppColors.success));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Attendance'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context))
            : null,
        actions: [
          IconButton(
            tooltip: 'Export report',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _export,
          ),
        ],
      ),
      body: FutureBuilder<List<AttendanceEntry>>(
        future: _future,
        builder: (context, snap) {
          final list = snap.data ?? [];
          final present =
              list.where((a) => a.state == AttendanceState.present).length;
          final absent =
              list.where((a) => a.state == AttendanceState.absent).length;
          final pending =
              list.where((a) => a.state == AttendanceState.pending).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
            children: [
              Row(
                children: [
                  _summaryTile('Present', '$present', AppColors.success,
                      AppColors.successBg, Icons.check_rounded),
                  const SizedBox(width: 10),
                  _summaryTile('Absent', '$absent', AppColors.danger,
                      AppColors.dangerBg, Icons.close_rounded),
                  const SizedBox(width: 10),
                  _summaryTile('Pending', '$pending', AppColors.warning,
                      AppColors.warningBg, Icons.schedule_rounded),
                ],
              ),
              const SizedBox(height: 20),
              _scanCard(),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Recent Attendance'),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const EmptyState(
                    icon: Icons.event_available_rounded,
                    title: 'No attendance yet',
                    subtitle: 'Scan or enter a member ID to mark present.')
              else
                ...list.map(_attendanceTile),
            ],
          );
        },
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
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: GoogleFonts.lexend(
                    fontSize: 22,
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

  Widget _scanCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              TintedIcon(
                  icon: Icons.qr_code_2_rounded,
                  color: AppColors.primary,
                  bg: AppColors.primary.withValues(alpha: 0.10),
                  box: 40,
                  size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mark Attendance',
                        style: GoogleFonts.lexend(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    Text('Scan a member QR or enter their ID',
                        style: GoogleFonts.lexend(
                            fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.white),
              label: const Text('Scan QR Code'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('or select a member',
                    style: GoogleFonts.lexend(
                        fontSize: 12, color: AppColors.inkFaint)),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 14),
          _marking
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : PickerField(
                  hint: 'Search & select member',
                  icon: Icons.search_rounded,
                  onTap: _pickMember,
                ),
        ],
      ),
    );
  }

  Widget _attendanceTile(AttendanceEntry a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Avatar(name: a.memberName, url: a.photoUrl, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.memberName,
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 12, color: AppColors.inkFaint),
                      const SizedBox(width: 4),
                      Text(a.time,
                          style: GoogleFonts.lexend(
                              fontSize: 12, color: AppColors.inkSoft)),
                    ],
                  ),
                ],
              ),
            ),
            if (a.state == AttendanceState.present)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const StatusChip(
                      label: 'Present',
                      color: AppColors.success,
                      bg: AppColors.successBg),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _checkOut(a),
                    borderRadius: BorderRadius.circular(AppColors.rSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(AppColors.rSm)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout_rounded,
                              size: 13, color: AppColors.danger),
                          const SizedBox(width: 4),
                          Text('Check out',
                              style: GoogleFonts.lexend(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              StatusChip(
                  label: a.state == AttendanceState.absent
                      ? 'Checked out'
                      : a.state.label,
                  color: a.state.color,
                  bg: a.state.bg),
          ],
        ),
      ),
    );
  }

  Future<void> _checkOut(AttendanceEntry a) async {
    await Repo.instance.updateAttendanceState(a.id, AttendanceState.absent);
    _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${a.memberName} checked out')));
    }
  }
}
