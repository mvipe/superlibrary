import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'members/members_screen.dart';
import 'books/books_screen.dart';
import 'reports/reports_screen.dart';
import 'attendance/attendance_screen.dart';
import 'drawer/app_drawer.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _pages = [
    DashboardScreen(onMenu: () => _scaffoldKey.currentState?.openDrawer()),
    const MembersScreen(),
    const BooksScreen(),
    const ReportsScreen(),
  ];

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AttendanceScreen(startOnScan: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppTheme.heroShadow,
        ),
        child: FloatingActionButton(
          onPressed: _openScanner,
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.index, required this.onTap});

  static const _items = [
    (Icons.home_rounded, 'Dashboard'),
    (Icons.groups_rounded, 'Members'),
    (Icons.menu_book_rounded, 'Books'),
    (Icons.bar_chart_rounded, 'Reports'),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.card,
      elevation: 0,
      height: 74,
      padding: EdgeInsets.zero,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            _tab(0),
            _tab(1),
            const SizedBox(width: 62), // notch gap
            _tab(2),
            _tab(3),
          ],
        ),
      ),
    );
  }

  Widget _tab(int i) {
    final active = i == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_items[i].$1,
                size: 22,
                color: active ? AppColors.primary : AppColors.inkFaint),
            const SizedBox(height: 4),
            Text(_items[i].$2,
                style: GoogleFonts.lexend(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? AppColors.primary : AppColors.inkFaint)),
          ],
        ),
      ),
    );
  }
}
