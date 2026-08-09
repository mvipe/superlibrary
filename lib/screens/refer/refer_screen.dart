import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  late Future<List<Referral>> _future;
  final _rupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  String get _code {
    final lib = SupabaseService.instance.library;
    if (lib?.referralCode != null && lib!.referralCode!.isNotEmpty) {
      return lib.referralCode!;
    }
    // Fallback for libraries created before referral codes existed.
    final seed = (lib?.adminPhone ?? lib?.id ?? 'SUPERLIB')
        .replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    final tail = seed.length >= 5
        ? seed.substring(seed.length - 5)
        : seed.padLeft(5, '0');
    return 'SL${tail.toUpperCase()}';
  }

  @override
  void initState() {
    super.initState();
    _future = Repo.instance.myReferrals(_code);
  }

  @override
  Widget build(BuildContext context) {
    final shareText =
        'Manage your library the smart way with SuperLibrary! Use my code $_code when you sign up. https://superlibrary.app';
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: FutureBuilder<List<Referral>>(
        future: _future,
        builder: (context, snap) {
          final refs = snap.data ?? [];
          final credited =
              refs.where((r) => r.isCredited).fold<double>(0, (s, r) => s + r.reward);
          final pending = refs.where((r) => !r.isCredited).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.heroGradient),
                  borderRadius: BorderRadius.circular(AppColors.rXl),
                  boxShadow: AppTheme.heroShadow,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.card_giftcard_rounded,
                        color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text('Refer a friend, earn ₹200',
                        style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 19)),
                    const SizedBox(height: 4),
                    Text(
                        'You and your friend each get ₹200 when they subscribe.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 12.5)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _heroStat('${refs.length}', 'Referrals'),
                        _hDivider(),
                        _heroStat(_rupee.format(credited), 'Earned'),
                        _hDivider(),
                        _heroStat('$pending', 'Pending'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Your referral code',
                  style: GoogleFonts.lexend(
                      fontSize: 13, color: AppColors.inkSoft)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppColors.rLg),
                  border: Border.all(color: AppColors.primary, width: 1.4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_code,
                          style: GoogleFonts.lexend(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: AppColors.primary)),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _code));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Referral code copied')));
                      },
                      borderRadius: BorderRadius.circular(AppColors.rSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(AppColors.rSm)),
                        child: Row(
                          children: [
                            const Icon(Icons.copy_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text('Copy',
                                style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shareText));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Invite message copied — paste it anywhere')));
                  },
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: const Text('Share invite'),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'How it works'),
              const SizedBox(height: 12),
              _step(1, 'Share your code',
                  'Send your code to another library owner.'),
              _step(2, 'They subscribe',
                  'They enter your code while signing up, then pick a plan.'),
              _step(3, 'You both earn',
                  'When they subscribe, ₹200 is credited to you.'),
              const SizedBox(height: 12),
              const SectionHeader(title: 'Your referrals'),
              const SizedBox(height: 12),
              if (refs.isEmpty)
                const EmptyState(
                    icon: Icons.group_add_rounded,
                    title: 'No referrals yet',
                    subtitle: 'Share your code to start earning.')
              else
                ...refs.map(_refTile),
            ],
          );
        },
      ),
    );
  }

  Widget _refTile(Referral r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Avatar(name: r.referredName, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.referredName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(DateFormat('d MMM yyyy').format(r.createdAt),
                      style: GoogleFonts.lexend(
                          fontSize: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_rupee.format(r.reward),
                    style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: r.isCredited
                            ? AppColors.success
                            : AppColors.inkSoft)),
                const SizedBox(height: 4),
                StatusChip(
                    label: r.isCredited ? 'Credited' : 'Pending',
                    color: r.isCredited ? AppColors.success : AppColors.warning,
                    bg: r.isCredited
                        ? AppColors.successBg
                        : AppColors.warningBg),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String value, String label) => Expanded(
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
            ),
            Text(label,
                style: GoogleFonts.lexend(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11)),
          ],
        ),
      );

  Widget _hDivider() => Container(
      width: 1, height: 30, color: Colors.white.withValues(alpha: 0.25));

  Widget _step(int n, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Text('$n',
                  style: GoogleFonts.lexend(
                      color: AppColors.primary, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700, fontSize: 14.5)),
                  Text(sub,
                      style: GoogleFonts.lexend(
                          fontSize: 12.5, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
