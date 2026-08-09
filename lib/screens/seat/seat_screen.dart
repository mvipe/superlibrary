import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common.dart';

class SeatScreen extends StatefulWidget {
  const SeatScreen({super.key});

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  List<Shift> _shifts = [];
  String _shift = 'Morning';
  bool _loading = true;
  List<SeatAllotment> _allot = [];

  int get _totalSeats => SupabaseService.instance.library?.totalSeats ?? 30;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final shifts = await Repo.instance.shifts();
    _shifts = shifts;
    if (shifts.isNotEmpty && !shifts.any((s) => s.name == _shift)) {
      _shift = shifts.first.name;
    }
    await _loadAllot();
  }

  Future<void> _loadAllot() async {
    setState(() => _loading = true);
    // Load ALL allotments (every shift) so we can honour Full-Day conflicts.
    final a = await Repo.instance.allSeatAllotments();
    if (!mounted) return;
    setState(() {
      _allot = a;
      _loading = false;
    });
  }

  /// The booking that blocks [seatNo] for the currently selected shift — the
  /// exact same-shift booking if present, otherwise a conflicting one (e.g. a
  /// Full-Day booking, or — when viewing Full Day — any timed booking).
  SeatAllotment? _forSeat(int seatNo) {
    SeatAllotment? exact;
    SeatAllotment? conflicting;
    for (final a in _allot) {
      if (a.seatNo != seatNo) continue;
      if (a.shift == _shift) {
        exact = a;
      } else if (seatShiftsConflict(a.shift, _shift)) {
        conflicting = a;
      }
    }
    return exact ?? conflicting;
  }

  int get _blockedCount {
    var n = 0;
    for (var i = 1; i <= _totalSeats; i++) {
      if (_forSeat(i) != null) n++;
    }
    return n;
  }

  Future<void> _tapSeat(int seatNo) async {
    final existing = _forSeat(seatNo);
    if (existing != null) {
      _showAllottedSheet(seatNo, existing);
    } else {
      final member = await _pickMember();
      if (member == null) return;
      try {
        await Repo.instance.allotSeat(seatNo, _shift, member);
        await _loadAllot();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Seat S-$seatNo allotted to ${member.name}')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Seat S-$seatNo is not available for $_shift (already booked).')));
        }
      }
    }
  }

  void _showAllottedSheet(int seatNo, SeatAllotment a) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppColors.rXl))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(AppColors.rMd)),
                  child: const Icon(Icons.event_seat_rounded,
                      color: AppColors.danger),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seat S-$seatNo',
                        style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    Text(
                        a.shift == _shift
                            ? '${a.shift} shift'
                            : 'Booked for ${a.shift} (blocks $_shift)',
                        style: GoogleFonts.lexend(
                            color: AppColors.inkSoft, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Avatar(name: a.memberName, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(a.memberName,
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger),
                onPressed: () async {
                  Navigator.pop(context);
                  await Repo.instance.freeSeat(a.id);
                  await _loadAllot();
                },
                icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
                label: const Text('Free this seat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Member?> _pickMember() async {
    final members = await Repo.instance.members();
    if (!mounted) return null;
    return showModalBottomSheet<Member>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppColors.rXl))),
      builder: (_) => _MemberPicker(members: members),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allotted = _blockedCount;
    final free = (_totalSeats - allotted).clamp(0, _totalSeats);
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Seat Management'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(18, 4, 18, 0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.heroGradient),
              borderRadius: BorderRadius.circular(AppColors.rLg),
              boxShadow: AppTheme.heroShadow,
            ),
            child: Row(
              children: [
                _statCol('All Seats', '$_totalSeats'),
                _divider(),
                _statCol('Allotted', '$allotted'),
                _divider(),
                _statCol('Un-Allotted', '$free'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: _shifts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = _shifts[i];
                final active = s.name == _shift;
                return GestureDetector(
                  onTap: () {
                    setState(() => _shift = s.name);
                    _loadAllot();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(AppColors.rMd),
                      border: Border.all(
                          color:
                              active ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(s.name,
                        style: GoogleFonts.lexend(
                            color: active ? Colors.white : AppColors.inkSoft,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Row(
              children: [
                _legend(AppColors.success, 'Available'),
                const SizedBox(width: 16),
                _legend(AppColors.danger, 'Allotted'),
                const Spacer(),
                Text('Tap a seat to allot',
                    style: GoogleFonts.lexend(
                        fontSize: 11.5, color: AppColors.inkFaint)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                    itemCount: _totalSeats,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, i) => _seatTile(i + 1),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _seatTile(int seatNo) {
    final a = _forSeat(seatNo);
    final taken = a != null;
    final color = taken ? AppColors.danger : AppColors.success;
    final bg = taken ? AppColors.dangerBg : AppColors.successBg;
    return GestureDetector(
      onTap: () => _tapSeat(seatNo),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.rMd),
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: const EdgeInsets.all(5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppColors.rSm)),
                child: Text('S-$seatNo',
                    style: GoogleFonts.lexend(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5)),
              ),
            ),
            Icon(Icons.chair_alt_rounded, color: color, size: 30),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(taken ? a.memberName.split(' ').first : 'Free',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lexend(
                      fontSize: 10.5,
                      fontWeight: taken ? FontWeight.w600 : FontWeight.w400,
                      color: taken ? AppColors.inkSoft : AppColors.inkFaint)),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.lexend(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11.5)),
          ],
        ),
      );

  Widget _divider() =>
      Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.25));

  Widget _legend(Color c, String label) => Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.lexend(
                  fontSize: 11.5, color: AppColors.inkSoft)),
        ],
      );
}

class _MemberPicker extends StatefulWidget {
  final List<Member> members;
  const _MemberPicker({required this.members});

  @override
  State<_MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends State<_MemberPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = _q.isEmpty
        ? widget.members
        : widget.members
            .where((m) =>
                m.name.toLowerCase().contains(_q.toLowerCase()) ||
                m.memberCode.toLowerCase().contains(_q.toLowerCase()) ||
                m.phone.contains(_q))
            .toList();
    return Padding(
      padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Allot seat to',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _q = v),
            decoration: const InputDecoration(
              hintText: 'Search member by name / ID / phone',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.person_off_rounded,
                    title: 'No members found')
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = list[i];
                      return PremiumCard(
                        padding: const EdgeInsets.all(10),
                        onTap: () => Navigator.pop(context, m),
                        child: Row(
                          children: [
                            Avatar(name: m.name, radius: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name,
                                      style: GoogleFonts.lexend(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                  Text(m.memberCode,
                                      style: GoogleFonts.lexend(
                                          fontSize: 12,
                                          color: AppColors.inkSoft)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.inkFaint),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
