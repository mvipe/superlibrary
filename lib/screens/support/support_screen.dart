import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _faqs = [
    (
      'How do I add a membership plan?',
      'Open the menu → Plans & Shifts → Add. Give it a name (e.g. Morning), timing and a monthly fee. It then appears when adding a member and on the seat screen.'
    ),
    (
      'How does seat booking work?',
      'While adding a member, enter a seat number and pick a plan. The seat is automatically booked for that plan/shift. You can also allot seats manually from Seat Management.'
    ),
    (
      'A member did not pay yet — what do I do?',
      'While registering, turn OFF "Payment received". The fee is saved as Pending and shows under the member\'s dues in Payments and the Expiring screen. Collect it later from Payments → Collect Fee.'
    ),
    (
      'How do I see who is expiring soon?',
      'The dashboard shows a "Memberships Expiring" section, and the menu has a full "Expiring Memberships" page with days left and pending dues.'
    ),
    (
      'Can I run more than one library?',
      'Yes — menu → Branch Management → New. Switch between branches any time; each branch keeps its own members, seats and payments.'
    ),
    (
      'Is my data safe?',
      'All data is stored in your own secure Supabase database and synced across your devices when you sign in with the same number.'
    ),
  ];

  void _copy(BuildContext context, String value, String what) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$what copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Need Help?'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.heroGradient),
              borderRadius: BorderRadius.circular(AppColors.rXl),
              boxShadow: AppTheme.heroShadow,
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('We\'re here to help',
                          style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17)),
                      Text('Reach us or browse common questions below.',
                          style: GoogleFonts.lexend(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Contact us'),
          const SizedBox(height: 12),
          _contactTile(context, Icons.email_rounded, 'Email',
              'support@superlibrary.app', AppColors.info, AppColors.infoBg),
          const SizedBox(height: 10),
          _contactTile(context, Icons.call_rounded, 'Phone',
              '+91 90000 00000', AppColors.success, AppColors.successBg),
          const SizedBox(height: 10),
          _contactTile(context, Icons.chat_rounded, 'WhatsApp',
              '+91 90000 00000', const Color(0xFF25D366),
              const Color(0xFFE7F8EE)),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Frequently asked'),
          const SizedBox(height: 12),
          ..._faqs.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PremiumCard(
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      iconColor: AppColors.primary,
                      collapsedIconColor: AppColors.inkFaint,
                      title: Text(f.$1,
                          style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(f.$2,
                              style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.inkSoft)),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 10),
          Center(
            child: Text('SuperLibrary • v1.0.0',
                style: GoogleFonts.lexend(
                    color: AppColors.inkFaint, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _contactTile(BuildContext context, IconData icon, String label,
      String value, Color color, Color bg) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _copy(context, value, label),
      child: Row(
        children: [
          TintedIcon(icon: icon, color: color, bg: bg, box: 44, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.lexend(
                        fontSize: 12.5, color: AppColors.inkSoft)),
                Text(value,
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w700, fontSize: 14.5)),
              ],
            ),
          ),
          const Icon(Icons.copy_rounded, size: 18, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}
