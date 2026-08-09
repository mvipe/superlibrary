import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import '../scan/scan_screen.dart';

class IssueReturnScreen extends StatefulWidget {
  const IssueReturnScreen({super.key});

  @override
  State<IssueReturnScreen> createState() => _IssueReturnScreenState();
}

class _IssueReturnScreenState extends State<IssueReturnScreen> {
  bool _issue = true;
  final _memberCtrl = TextEditingController();
  final _bookCtrl = TextEditingController();
  Member? _member;
  Book? _book;
  bool _busy = false;

  @override
  void dispose() {
    _memberCtrl.dispose();
    _bookCtrl.dispose();
    super.dispose();
  }

  Future<void> _findMember(String code) async {
    final q = code.trim().toLowerCase();
    if (q.isEmpty) return;
    final members = await Repo.instance.members();
    Member? found;
    for (final m in members) {
      if (m.memberCode.toLowerCase() == q ||
          m.id.toLowerCase() == q ||
          m.name.toLowerCase().contains(q)) {
        found = m;
        break;
      }
    }
    setState(() => _member = found);
    if (found == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No member found for "$code"')));
    }
  }

  Future<void> _findBook(String isbn) async {
    final q = isbn.trim().toLowerCase();
    if (q.isEmpty) return;
    final books = await Repo.instance.books();
    Book? found;
    for (final b in books) {
      if (b.isbn.toLowerCase() == q ||
          b.id.toLowerCase() == q ||
          b.title.toLowerCase().contains(q)) {
        found = b;
        break;
      }
    }
    setState(() => _book = found);
    if (found == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No book found for "$isbn"')));
    }
  }

  Future<void> _scanInto(TextEditingController ctrl,
      Future<void> Function(String) onFound) async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (code != null) {
      ctrl.text = code;
      await onFound(code);
    }
  }

  Future<void> _pickMember() async {
    final members = await Repo.instance.members();
    if (!mounted) return;
    final m = await showSearchablePicker<Member>(
      context,
      title: 'Select member',
      items: members,
      label: (m) => m.name,
      subtitle: (m) => '${m.memberCode} • ${m.phone}',
      searchHint: 'Search by name, ID or phone',
    );
    if (m != null) setState(() => _member = m);
  }

  Future<void> _pickBook() async {
    final books = await Repo.instance.books();
    if (!mounted) return;
    final b = await showSearchablePicker<Book>(
      context,
      title: 'Select book',
      items: books,
      label: (b) => b.title,
      subtitle: (b) =>
          '${b.author} • ${b.availableCopies}/${b.totalCopies} available',
      searchHint: 'Search by title, author or ISBN',
    );
    if (b != null) setState(() => _book = b);
  }

  Future<void> _submit() async {
    if (_member == null || _book == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select both a member and a book first')));
      return;
    }
    if (_issue && _book!.availableCopies <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No copies available to issue')));
      return;
    }
    setState(() => _busy = true);
    try {
      if (_issue) {
        await Repo.instance.issueBook(_book!, _member!);
      } else {
        await Repo.instance.returnBook(_book!, _member!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_issue
              ? 'Book issued to ${_member!.name}'
              : 'Book returned by ${_member!.name}'),
          backgroundColor: AppColors.success));
      setState(() {
        _member = null;
        _book = null;
        _memberCtrl.clear();
        _bookCtrl.clear();
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Issue / Return'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
        children: [
          _toggle(),
          const SizedBox(height: 22),
          _pickLabel('Member', () => _scanInto(_memberCtrl, _findMember)),
          const SizedBox(height: 8),
          PickerField(
            hint: 'Select a member',
            value: _member?.name,
            sub: _member == null
                ? null
                : '${_member!.memberCode} • ${_member!.phone}',
            icon: Icons.expand_more_rounded,
            onTap: _pickMember,
          ),
          if (_member != null) ...[
            const SizedBox(height: 12),
            _memberCard(_member!),
          ],
          const SizedBox(height: 20),
          _pickLabel('Book', () => _scanInto(_bookCtrl, _findBook)),
          const SizedBox(height: 8),
          PickerField(
            hint: 'Select a book',
            value: _book?.title,
            sub: _book?.author,
            icon: Icons.expand_more_rounded,
            onTap: _pickBook,
          ),
          if (_book != null) ...[
            const SizedBox(height: 12),
            _bookCard(_book!),
          ],
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white))
                : Text(_issue ? 'Issue Book' : 'Return Book'),
          ),
        ],
      ),
    );
  }

  Widget _toggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.rLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _toggleTab('Issue Book', _issue, () => setState(() => _issue = true)),
          _toggleTab(
              'Return Book', !_issue, () => setState(() => _issue = false)),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.rMd),
          ),
          child: Text(label,
              style: GoogleFonts.lexend(
                  color: active ? Colors.white : AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ),
      ),
    );
  }

  Widget _memberCard(Member m) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Avatar(name: m.name, radius: 22),
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('${m.memberCode}  ',
                        style: GoogleFonts.lexend(
                            fontSize: 12, color: AppColors.inkSoft)),
                    StatusChip(
                        label: m.status.label,
                        color: m.status.color,
                        bg: m.status.bg),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookCard(Book b) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [b.accent, b.accent.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(AppColors.rSm),
            ),
            child:
                const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink)),
                Text(b.author,
                    style: GoogleFonts.lexend(
                        fontSize: 12.5, color: AppColors.inkSoft)),
                const SizedBox(height: 3),
                Text('Available: ${b.availableCopies} of ${b.totalCopies}',
                    style: GoogleFonts.lexend(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: b.availableCopies > 0
                            ? AppColors.success
                            : AppColors.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickLabel(String t, VoidCallback onScan) {
    return Row(
      children: [
        Text(t,
            style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: AppColors.ink)),
        const Spacer(),
        InkWell(
          onTap: onScan,
          borderRadius: BorderRadius.circular(AppColors.rSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('Scan',
                    style: GoogleFonts.lexend(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
