import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/supabase_service.dart';

class _Msg {
  final String text;
  final bool fromUser;
  _Msg(this.text, this.fromUser);
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _thinking = false;
  final _rupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static const _suggestions = [
    'How many members?',
    "Today's collection",
    'Who is expiring soon?',
    'Total pending dues',
    'How many books?',
    'Seat occupancy',
  ];

  @override
  void initState() {
    super.initState();
    final lib = SupabaseService.instance.library;
    _messages.add(_Msg(
        'Hi! I\'m your library assistant for ${lib?.name ?? 'your library'}. '
        'Ask me about members, collection, expiring memberships, dues, books, '
        'seats or expenses.',
        false));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _thinking) return;
    setState(() {
      _messages.add(_Msg(q, true));
      _thinking = true;
      _controller.clear();
    });
    _scrollDown();
    final answer = await _answer(q.toLowerCase());
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(answer, false));
      _thinking = false;
    });
    _scrollDown();
  }

  bool _has(String q, List<String> words) => words.any((w) => q.contains(w));

  Future<String> _answer(String q) async {
    // small artificial delay so the typing indicator is visible
    await Future.delayed(const Duration(milliseconds: 350));

    if (_has(q, ['hi', 'hello', 'hey', 'namaste'])) {
      return 'Hello! Ask me things like "how many active members" or "today\'s collection".';
    }

    if (_has(q, ['expir', 'renew'])) {
      final list = await Repo.instance.expiringSoon(days: 7);
      if (list.isEmpty) return 'Good news — no memberships expire within 7 days.';
      final names = list.take(5).map((m) {
        final d = m.expiresAt!.difference(DateTime.now()).inDays;
        return '• ${m.name} (${d < 0 ? 'expired' : 'in ${d}d'})';
      }).join('\n');
      return '${list.length} membership(s) expiring within 7 days:\n$names';
    }

    if (_has(q, ['due', 'pending', 'owe', 'unpaid'])) {
      final dues = await Repo.instance.duesByMember();
      final total = dues.values.fold<double>(0, (s, v) => s + v);
      return dues.isEmpty
          ? 'No pending dues — everyone is paid up! 🎉'
          : '${dues.length} member(s) have pending dues totalling ${_rupee.format(total)}.';
    }

    if (_has(q, ['collection', 'revenue', 'earn', 'income', 'today', 'money'])) {
      final pays = await Repo.instance.payments();
      final paid = pays.where((p) => p.status == PaymentStatus.paid);
      final total = paid.fold<double>(0, (s, p) => s + p.amount);
      final now = DateTime.now();
      final today = paid
          .where((p) =>
              p.date.year == now.year &&
              p.date.month == now.month &&
              p.date.day == now.day)
          .fold<double>(0, (s, p) => s + p.amount);
      return 'Total collection: ${_rupee.format(total)}.\nToday: ${_rupee.format(today)}.';
    }

    if (_has(q, ['member', 'student', 'people'])) {
      final members = await Repo.instance.members();
      final active =
          members.where((m) => m.status == MemberStatus.active).length;
      final expired =
          members.where((m) => m.status == MemberStatus.expired).length;
      return 'You have ${members.length} members — $active active, $expired expired.';
    }

    if (_has(q, ['book'])) {
      final books = await Repo.instance.books();
      final totalCopies = books.fold<int>(0, (s, b) => s + b.totalCopies);
      final issued =
          books.fold<int>(0, (s, b) => s + (b.totalCopies - b.availableCopies));
      return '${books.length} titles, $totalCopies copies. Currently $issued issued.';
    }

    if (_has(q, ['seat', 'occup'])) {
      final total = SupabaseService.instance.library?.totalSeats ?? 0;
      final shifts = await Repo.instance.shifts();
      final buf = StringBuffer('Total seats: $total.');
      for (final s in shifts) {
        final used = (await Repo.instance.allotments(s.name)).length;
        buf.write('\n• ${s.name}: $used/$total booked');
      }
      return buf.toString();
    }

    if (_has(q, ['expense', 'spent', 'cost'])) {
      final ex = await Repo.instance.expenses();
      final total = ex.fold<double>(0, (s, e) => s + e.amount);
      return 'Total expenses recorded: ${_rupee.format(total)} across ${ex.length} entries.';
    }

    if (_has(q, ['plan', 'subscription', 'trial'])) {
      final lib = SupabaseService.instance.library;
      final plan = lib?.plan ?? 'free';
      final exp = lib?.planExpiresAt;
      return 'Current plan: ${plan[0].toUpperCase()}${plan.substring(1)}'
          '${exp != null ? ' (till ${DateFormat('d MMM yyyy').format(exp)})' : ''}.';
    }

    return "I can help with members, collection, expiring memberships, dues, "
        "books, seats, expenses and your plan. Try one of the suggestions below.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.heroGradient),
                  borderRadius: BorderRadius.circular(AppColors.rMd)),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('AI Assistant',
                style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w700, fontSize: 17)),
          ],
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) return _typing();
                return _bubble(_messages[i]);
              },
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _send(_suggestions[i]),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppColors.rMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(_suggestions[i],
                      style: GoogleFonts.lexend(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            color: AppColors.card,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: const InputDecoration(
                        hintText: 'Ask about your library…'),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _send(_controller.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        gradient:
                            LinearGradient(colors: AppColors.heroGradient),
                        borderRadius: BorderRadius.circular(AppColors.rMd)),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_Msg m) {
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: m.fromUser ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppColors.rLg),
            topRight: const Radius.circular(AppColors.rLg),
            bottomLeft: Radius.circular(m.fromUser ? AppColors.rLg : 4),
            bottomRight: Radius.circular(m.fromUser ? 4 : AppColors.rLg),
          ),
          border: m.fromUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(m.text,
            style: GoogleFonts.lexend(
                fontSize: 13.5,
                height: 1.35,
                color: m.fromUser ? Colors.white : AppColors.ink)),
      ),
    );
  }

  Widget _typing() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.rLg),
          border: Border.all(color: AppColors.border),
        ),
        child: SizedBox(
          width: 34,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                3,
                (_) => Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: AppColors.inkFaint,
                          shape: BoxShape.circle),
                    )),
          ),
        ),
      ),
    );
  }
}
