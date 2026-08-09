import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/supabase_service.dart';
import '../../services/razorpay_service.dart';
import '../../config/razorpay_config.dart';
import '../../widgets/common.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  BillingCycle _cycle = BillingCycle.all[3]; // default 1 Year
  bool _busy = false;
  final _rupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  Library? get _lib => SupabaseService.instance.library;
  String get _currentPlan => _lib?.plan ?? 'free';
  bool get _isTrial => _currentPlan == 'trial';

  int get _trialDaysLeft {
    final e = _lib?.planExpiresAt;
    if (e == null) return 0;
    return e.difference(DateTime.now()).inDays.clamp(0, 99);
  }

  Future<void> _choose(SubPlan plan) async {
    if (_lib == null) return;
    final total = plan.totalFor(_cycle);

    if (!RazorpayConfig.isConfigured) {
      final ok = await confirmDialog(context,
          title: 'Activate ${plan.name} (demo)?',
          message:
              'Razorpay key is not set, so this activates ${plan.name} (${_cycle.label}) in demo mode without a real charge.',
          confirmLabel: 'Activate',
          danger: false);
      if (ok == true) await _apply(plan);
      return;
    }

    setState(() => _busy = true);
    final res = await RazorpayService.instance.checkout(
      amount: total,
      memberName: _lib!.adminName,
      description: 'SuperLibrary ${plan.name} • ${_cycle.label}',
      contact: _lib!.adminPhone,
      email: _lib!.adminEmail,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.success) {
      await _apply(plan);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Payment cancelled')));
    }
  }

  Future<void> _apply(SubPlan plan) async {
    setState(() => _busy = true);
    final now = DateTime.now();
    final expires = DateTime(now.year, now.month + _cycle.months, now.day);
    final updated = _lib!.copyWith(plan: plan.id, planExpiresAt: expires);
    await SupabaseService.instance.updateLibrary(updated);
    // If this library was referred by someone, credit their referral now.
    await Repo.instance.creditReferralFor(_lib!.id);
    Repo.revision.value++;
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text('${plan.name} (${_cycle.label}) activated 🎉')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Subscription'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
            children: [
              _currentCard(),
              const SizedBox(height: 22),
              Text('Billing cycle',
                  style: GoogleFonts.lexend(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _cycleSelector(),
              const SizedBox(height: 20),
              Text('Choose a plan',
                  style: GoogleFonts.lexend(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Prices shown for ${_cycle.label.toLowerCase()} billing',
                  style: GoogleFonts.lexend(
                      fontSize: 12.5, color: AppColors.inkSoft)),
              const SizedBox(height: 16),
              ...SubPlan.catalog.map(_planCard),
              const SizedBox(height: 8),
              Center(
                child: Text('Cancel anytime • GST may apply',
                    style: GoogleFonts.lexend(
                        fontSize: 11.5, color: AppColors.inkFaint)),
              ),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _currentCard() {
    final expiry = _lib?.planExpiresAt;
    String title;
    String? subtitle;
    if (_isTrial) {
      title = 'Free Trial';
      subtitle = _trialDaysLeft > 0
          ? '$_trialDaysLeft days left — upgrade to keep all features'
          : 'Trial ended — choose a plan to continue';
    } else if (_currentPlan == 'free') {
      title = 'Free';
      subtitle = 'Upgrade to unlock premium features';
    } else {
      final p = SubPlan.byId(_currentPlan);
      title = p.name;
      subtitle = expiry != null
          ? 'Renews on ${DateFormat('d MMM yyyy').format(expiry)}'
          : null;
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: AppColors.heroGradient),
        borderRadius: BorderRadius.circular(AppColors.rXl),
        boxShadow: AppTheme.heroShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppColors.rMd)),
            child: Icon(
                _isTrial
                    ? Icons.timelapse_rounded
                    : Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Plan',
                    style: GoogleFonts.lexend(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5)),
                Text(title,
                    style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.lexend(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cycleSelector() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: BillingCycle.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = BillingCycle.all[i];
          final active = c.id == _cycle.id;
          return GestureDetector(
            onTap: () => setState(() => _cycle = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(AppColors.rMd),
                border: Border.all(
                    color: active ? AppColors.primary : AppColors.border),
              ),
              child: Row(
                children: [
                  Text(c.label,
                      style: GoogleFonts.lexend(
                          color: active ? Colors.white : AppColors.inkSoft,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  if (c.discount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withValues(alpha: 0.25)
                              : AppColors.successBg,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('-${(c.discount * 100).toInt()}%',
                          style: GoogleFonts.lexend(
                              color:
                                  active ? Colors.white : AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 10)),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _planCard(SubPlan plan) {
    final isCurrent = plan.id == _currentPlan;
    final total = plan.totalFor(_cycle);
    final perMonth = plan.effectiveMonthly(_cycle);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.rLg),
        border: Border.all(
            color: plan.highlight ? AppColors.primary : AppColors.border,
            width: plan.highlight ? 1.5 : 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(plan.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lexend(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: plan.highlight
                                      ? AppColors.primary
                                      : AppColors.ink)),
                        ),
                        if (plan.highlight) ...[
                          const SizedBox(width: 8),
                          StatusChip(
                              label: 'POPULAR',
                              color: Colors.white,
                              bg: AppColors.primary),
                        ],
                      ],
                    ),
                    Text(plan.tagline,
                        style: GoogleFonts.lexend(
                            fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_rupee.format(total),
                      style: GoogleFonts.lexend(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  Text('≈ ${_rupee.format(perMonth)}/mo',
                      style: GoogleFonts.lexend(
                          fontSize: 11, color: AppColors.inkSoft)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 17,
                        color: plan.highlight
                            ? AppColors.primary
                            : AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f,
                          style: GoogleFonts.lexend(
                              fontSize: 13, color: AppColors.inkSoft)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppColors.rMd))),
                    child: Text('Current Plan',
                        style: GoogleFonts.lexend(
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w700)),
                  )
                : ElevatedButton(
                    onPressed: () => _choose(plan),
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            plan.highlight ? AppColors.primary : AppColors.ink,
                        minimumSize: const Size.fromHeight(46)),
                    child: Text('Choose ${plan.name}'),
                  ),
          ),
        ],
      ),
    );
  }
}
