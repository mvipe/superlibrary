import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../widgets/common.dart';
import 'book_form.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  int _filter = 0;
  String _query = '';
  late Future<List<Book>> _future;
  static const _tabs = ['All', 'Available', 'Issued'];

  @override
  void initState() {
    super.initState();
    _future = Repo.instance.books();
  }

  void _reload() => setState(() => _future = Repo.instance.books());

  List<Book> _apply(List<Book> list) {
    var l = list;
    if (_filter == 1) l = l.where((b) => b.availableCopies > 0).toList();
    if (_filter == 2) l = l.where((b) => b.availableCopies == 0).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      l = l
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.author.toLowerCase().contains(q) ||
              b.isbn.contains(q))
          .toList();
    }
    return l;
  }

  Future<void> _add() async {
    final saved = await showBookForm(context);
    if (saved == true) _reload();
  }

  Future<void> _edit(Book b) async {
    final saved = await showBookForm(context, existing: b);
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Books'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context))
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: PillButton(
                icon: Icons.add_rounded, label: 'Add Book', onTap: _add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search by title, author or ISBN',
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
            child: FutureBuilder<List<Book>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                final filtered = _apply(snap.data ?? []);
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final f = Repo.instance.books();
                    setState(() => _future = f);
                    await f;
                  },
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            EmptyState(
                                icon: Icons.menu_book_rounded,
                                title: 'No books yet',
                                subtitle:
                                    'Tap Add Book to build your catalogue.'),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) => _bookTile(filtered[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookTile(Book b) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _edit(b),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [b.accent, b.accent.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppColors.rSm),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(b.author,
                    style: GoogleFonts.lexend(
                        fontSize: 12.5, color: AppColors.inkSoft)),
                const SizedBox(height: 3),
                Text('${b.category}  •  ISBN ${b.isbn}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        fontSize: 11, color: AppColors.inkFaint)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: b.availableCopies > 0
                      ? AppColors.successBg
                      : AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(AppColors.rMd),
                ),
                alignment: Alignment.center,
                child: Text('${b.availableCopies}',
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: b.availableCopies > 0
                            ? AppColors.success
                            : AppColors.danger)),
              ),
              const SizedBox(height: 4),
              Text('of ${b.totalCopies}',
                  style: GoogleFonts.lexend(
                      fontSize: 10, color: AppColors.inkFaint)),
            ],
          ),
        ],
      ),
    );
  }
}
