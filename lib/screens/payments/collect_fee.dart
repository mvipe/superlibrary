import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../data/repo.dart';
import '../../services/razorpay_service.dart';
import '../../config/razorpay_config.dart';
import '../../widgets/common.dart';

Future<bool?> showCollectFee(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CollectFee(),
  );
}

class _CollectFee extends StatefulWidget {
  const _CollectFee();

  @override
  State<_CollectFee> createState() => _CollectFeeState();
}

class _CollectFeeState extends State<_CollectFee> {
  final _amount = TextEditingController(text: '500');
  Member? _member;
  PaymentType _type = PaymentType.membership;
  String _method = 'cash';
  bool _saving = false;
  List<Shift> _plans = [];

  @override
  void initState() {
    super.initState();
    Repo.instance.shifts().then((p) {
      if (mounted) setState(() => _plans = p);
    });
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
    if (m == null) return;
    setState(() {
      _member = m;
      // Auto-fill the amount from the member's plan fee when available.
      if (m.plan != null && _type == PaymentType.membership) {
        final match = _plans.where((p) => p.name == m.plan);
        if (match.isNotEmpty) _amount.text = match.first.fee.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _collect() async {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (_member == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select a member and enter a valid amount')));
      return;
    }
    setState(() => _saving = true);

    if (_method == 'razorpay') {
      final result = await RazorpayService.instance.checkout(
        amount: amount,
        memberName: _member!.name,
        description: _type == PaymentType.membership
            ? 'Membership Fee'
            : 'Library Fine',
        contact: _member!.phone,
        email: _member!.email,
      );
      if (!result.success) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.message ?? 'Payment cancelled')));
        return;
      }
    }

    try {
      final p = Repo.instance.newPayment(
        member: _member!,
        type: _type,
        amount: amount,
        status: PaymentStatus.paid,
        method: _method,
      );
      await Repo.instance.addPayment(p);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment collected successfully')));
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
              Text('Collect Fee',
                  style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 18),
              _label('Member'),
              const SizedBox(height: 6),
              PickerField(
                hint: 'Select member',
                value: _member?.name,
                sub: _member == null
                    ? null
                    : '${_member!.memberCode}'
                        '${_member!.plan != null ? ' • ${_member!.plan} plan' : ''}',
                icon: Icons.expand_more_rounded,
                onTap: _pickMember,
              ),
              const SizedBox(height: 16),
              _label('Type'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _choice('Membership', _type == PaymentType.membership,
                      () => setState(() => _type = PaymentType.membership)),
                  const SizedBox(width: 8),
                  _choice('Fine', _type == PaymentType.fine,
                      () => setState(() => _type = PaymentType.fine)),
                ],
              ),
              const SizedBox(height: 16),
              _label('Amount (₹)'),
              const SizedBox(height: 6),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18)),
              ),
              const SizedBox(height: 16),
              _label('Payment Method'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _choice('Cash', _method == 'cash',
                      () => setState(() => _method = 'cash'),
                      icon: Icons.payments_rounded),
                  const SizedBox(width: 8),
                  _choice('Razorpay', _method == 'razorpay',
                      () => setState(() => _method = 'razorpay'),
                      icon: Icons.account_balance_wallet_rounded),
                ],
              ),
              if (_method == 'razorpay' && !RazorpayConfig.isConfigured) ...[
                const SizedBox(height: 8),
                Text('Add your Razorpay key in razorpay_config.dart to enable.',
                    style: GoogleFonts.lexend(
                        fontSize: 11.5, color: AppColors.warning)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _collect,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white))
                    : Text(_method == 'razorpay'
                        ? 'Pay with Razorpay'
                        : 'Collect Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.lexend(
          fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.ink));

  Widget _choice(String label, bool sel, VoidCallback onTap, {IconData? icon}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(AppColors.rMd),
            border: Border.all(color: sel ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16,
                    color: sel ? Colors.white : AppColors.inkSoft),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: GoogleFonts.lexend(
                      color: sel ? Colors.white : AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}
