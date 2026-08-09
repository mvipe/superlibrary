import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../shift/shift_screen.dart';
import '../tax/tax_screen.dart';
import '../seat/seat_screen.dart';
import '../branch/branch_screen.dart';
import '../settings/theme_screen.dart';
import '../sms/sms_screen.dart';
import '../invoice/invoice_screen.dart';

/// "Master" — the configuration hub. Everything the library owner sets up once
/// (plans, taxes, seats, branches, theme, SMS) lives here.
class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, Color, Color, String, String, Widget)>[
      (
        Icons.access_time_filled_rounded,
        AppColors.primary,
        AppColors.dangerBg,
        'Plans & Shifts',
        'Create the plans members can buy',
        const ShiftScreen()
      ),
      (
        Icons.percent_rounded,
        AppColors.info,
        AppColors.infoBg,
        'Tax Management',
        'GST / service charges on fees',
        const TaxScreen()
      ),
      (
        Icons.event_seat_rounded,
        const Color(0xFF0EA5A0),
        AppColors.tintMint,
        'Seat Management',
        'Allot seats per shift',
        const SeatScreen()
      ),
      (
        Icons.account_tree_rounded,
        const Color(0xFF7C3AED),
        AppColors.tintPurple,
        'Branch Management',
        'Add and switch libraries',
        const BranchScreen()
      ),
      (
        Icons.receipt_long_rounded,
        AppColors.success,
        AppColors.successBg,
        'Invoice Management',
        'Generate & share invoices',
        const InvoiceScreen()
      ),
      (
        Icons.sms_rounded,
        AppColors.warning,
        AppColors.warningBg,
        'Auto SMS Reminder',
        'Expiry & welcome messages',
        const SmsScreen()
      ),
      (
        Icons.palette_rounded,
        const Color(0xFFEC4899),
        AppColors.tintPink,
        'App Theme',
        'Change the app colour',
        const ThemeScreen()
      ),
    ];
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Master'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final it = items[i];
          return PremiumCard(
            padding: const EdgeInsets.all(14),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => it.$6)),
            child: Row(
              children: [
                TintedIcon(icon: it.$1, color: it.$2, bg: it.$3, box: 48, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.$4,
                          style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w700, fontSize: 15.5)),
                      const SizedBox(height: 2),
                      Text(it.$5,
                          style: GoogleFonts.lexend(
                              fontSize: 12.5, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.inkFaint),
              ],
            ),
          );
        },
      ),
    );
  }
}
