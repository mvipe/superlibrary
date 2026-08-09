import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../scan/scan_screen.dart';

Future<bool?> showBookForm(BuildContext context, {Book? existing}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BookForm(existing: existing),
  );
}

const _accents = [
  Color(0xFFE8622A),
  Color(0xFF2FB6A6),
  Color(0xFF7C3AED),
  Color(0xFFEF4444),
  Color(0xFFF59E0B),
  Color(0xFF3B82F6),
];

class _BookForm extends StatefulWidget {
  final Book? existing;
  const _BookForm({this.existing});

  @override
  State<_BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<_BookForm> {
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _isbn;
  late final TextEditingController _category;
  late final TextEditingController _copies;
  late Color _accent;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _author = TextEditingController(text: e?.author ?? '');
    _isbn = TextEditingController(text: e?.isbn ?? '');
    _category = TextEditingController(text: e?.category ?? 'General');
    _copies = TextEditingController(text: (e?.totalCopies ?? 1).toString());
    _accent = e?.accent ?? _accents.first;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _isbn.dispose();
    _category.dispose();
    _copies.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title')));
      return;
    }
    final copies = int.tryParse(_copies.text.trim()) ?? 1;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final old = widget.existing!;
        final delta = copies - old.totalCopies;
        final updated = old.copyWith(
          title: _title.text.trim(),
          author: _author.text.trim(),
          isbn: _isbn.text.trim(),
          category: _category.text.trim(),
          totalCopies: copies,
          availableCopies: (old.availableCopies + delta).clamp(0, copies),
          accent: _accent,
        );
        await Repo.instance.updateBook(updated);
      } else {
        final b = Repo.instance.newBook(
          title: _title.text.trim(),
          author: _author.text.trim(),
          isbn: _isbn.text.trim(),
          category: _category.text.trim(),
          copies: copies,
          accent: _accent,
        );
        await Repo.instance.addBook(b);
      }
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Text(_isEdit ? 'Edit Book' : 'Add Book',
                  style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 18),
              _field('Title', _title, icon: Icons.menu_book_rounded),
              const SizedBox(height: 12),
              _field('Author', _author, icon: Icons.person_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _isbnField()),
                  const SizedBox(width: 12),
                  SizedBox(
                      width: 84,
                      child: _field('Copies', _copies,
                          keyboard: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ])),
                ],
              ),
              const SizedBox(height: 12),
              _field('Category', _category, icon: Icons.category_rounded),
              const SizedBox(height: 16),
              Text('Cover colour',
                  style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppColors.ink)),
              const SizedBox(height: 10),
              Row(
                children: _accents.map((c) {
                  final sel = c.toARGB32() == _accent.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _accent = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(AppColors.rMd),
                        border: Border.all(
                            color: sel ? AppColors.ink : Colors.transparent,
                            width: 2),
                      ),
                      child: sel
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white))
                    : Text(_isEdit ? 'Save Changes' : 'Add Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanIsbn() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen(title: 'Scan ISBN')),
    );
    if (code != null) setState(() => _isbn.text = code);
  }

  Widget _isbnField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ISBN',
            style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: AppColors.inkSoft)),
        const SizedBox(height: 6),
        TextField(
          controller: _isbn,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
            suffixIcon: GestureDetector(
              onTap: _scanIsbn,
              child: Container(
                margin: const EdgeInsets.all(6),
                width: 40,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppColors.rSm)),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController c,
      {IconData? icon,
      TextInputType? keyboard,
      List<TextInputFormatter>? formatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.lexend(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: AppColors.inkSoft)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: keyboard,
          inputFormatters: formatters,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          ),
        ),
      ],
    );
  }
}
