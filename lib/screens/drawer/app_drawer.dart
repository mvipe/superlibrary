import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common.dart';
import '../auth_gate.dart';
import '../members/members_screen.dart';
import '../books/books_screen.dart';
import '../payments/payments_screen.dart';
import '../attendance/attendance_screen.dart';
import '../issue_return/issue_return_screen.dart';
import '../reports/reports_screen.dart';
import '../reports/collection_report_screen.dart';
import '../settings/theme_screen.dart';
import '../seat/seat_screen.dart';
import '../shift/shift_screen.dart';
import '../enquiry/enquiry_screen.dart';
import '../expenses/expenses_screen.dart';
import '../tax/tax_screen.dart';
import '../sms/sms_screen.dart';
import '../branch/branch_screen.dart';
import '../subscription/subscription_screen.dart';
import '../expiring/expiring_screen.dart';
import '../support/support_screen.dart';
import '../refer/refer_screen.dart';
import '../ai/ai_assistant_screen.dart';
import '../master/master_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.card,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _tile(Icons.auto_awesome_rounded, 'AI Assistant',
                      badge: 'NEW',
                      onTap: () => _go(context, const AiAssistantScreen())),
                  _tile(Icons.groups_rounded, 'Member Management',
                      onTap: () => _go(context, const MembersScreen())),
                  _tile(Icons.menu_book_rounded, 'Books',
                      onTap: () => _go(context, const BooksScreen())),
                  _tile(Icons.swap_horiz_rounded, 'Issue / Return',
                      onTap: () => _go(context, const IssueReturnScreen())),
                  _tile(Icons.currency_rupee_rounded, 'Payments',
                      onTap: () => _go(context, const PaymentsScreen())),
                  _tile(Icons.event_available_rounded, 'Attendance',
                      onTap: () => _go(context, const AttendanceScreen())),
                  _tile(Icons.timelapse_rounded, 'Expiring Memberships',
                      onTap: () => _go(context, const ExpiringScreen())),
                  _tile(Icons.event_seat_rounded, 'Seat Management',
                      onTap: () => _go(context, const SeatScreen())),
                  _tile(Icons.access_time_filled_rounded, 'Plans & Shifts',
                      onTap: () => _go(context, const ShiftScreen())),
                  _tile(Icons.assignment_rounded, 'Enquiry Management',
                      onTap: () => _go(context, const EnquiryScreen())),
                  _tile(Icons.account_balance_wallet_rounded, 'Manage Expenses',
                      onTap: () => _go(context, const ExpensesScreen())),
                  _tile(Icons.receipt_long_rounded, 'Collection Report',
                      onTap: () =>
                          _go(context, const CollectionReportScreen())),
                  _tile(Icons.insert_chart_outlined_rounded, 'Reports',
                      onTap: () => _go(context, const ReportsScreen())),
                  _tile(Icons.percent_rounded, 'Tax Management',
                      onTap: () => _go(context, const TaxScreen())),
                  _tile(Icons.sms_rounded, 'Auto SMS Reminder',
                      onTap: () => _go(context, const SmsScreen())),
                  const _DrawerDivider(),
                  _tile(Icons.dashboard_customize_rounded, 'Master',
                      onTap: () => _go(context, const MasterScreen())),
                  _tile(Icons.account_tree_rounded, 'Branch Management',
                      onTap: () => _go(context, const BranchScreen())),
                  _tile(Icons.palette_rounded, 'App Theme',
                      onTap: () => _go(context, const ThemeScreen())),
                  _tile(Icons.workspace_premium_rounded, 'Subscription',
                      onTap: () => _go(context, const SubscriptionScreen())),
                  _tile(Icons.card_giftcard_rounded, 'Refer & Earn',
                      onTap: () => _go(context, const ReferScreen())),
                  _tile(Icons.help_outline_rounded, 'Need Help?',
                      onTap: () => _go(context, const SupportScreen())),
                  const _DrawerDivider(),
                  _tile(Icons.logout_rounded, 'Logout', danger: true,
                      onTap: () async {
                    await SupabaseService.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthGate()),
                        (_) => false,
                      );
                    }
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('SuperLibrary • v1.0.0',
                  style: GoogleFonts.lexend(
                      color: AppColors.inkFaint, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final lib = SupabaseService.instance.library;
    final count = SupabaseService.instance.libraries.length;
    return GestureDetector(
      onTap: () => _go(context, const BranchScreen()),
      child: Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.heroGradient),
        borderRadius: BorderRadius.circular(AppColors.rLg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Text(
                (lib?.adminName.isNotEmpty ?? false)
                    ? lib!.adminName[0].toUpperCase()
                    : 'A',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text('${lib?.adminName ?? 'Admin'} (Admin)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: Colors.white, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(lib?.name ?? 'Your Library',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
                if ((lib?.adminEmail ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(lib!.adminEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12)),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppColors.rSm)),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(height: 4),
              Text(count > 1 ? '$count branches' : 'Switch',
                  style: GoogleFonts.lexend(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 9.5)),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _tile(IconData icon, String label,
      {bool danger = false, String? badge, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      leading: Icon(icon,
          size: 21, color: danger ? AppColors.danger : AppColors.primary),
      title: Row(
        children: [
          Text(label,
              style: GoogleFonts.lexend(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: danger ? AppColors.danger : AppColors.ink)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            StatusChip(
                label: badge, color: Colors.white, bg: AppColors.primary),
          ],
        ],
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Divider(height: 1),
      );
}
