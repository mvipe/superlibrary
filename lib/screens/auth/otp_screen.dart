import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../services/msg91_service.dart';
import '../../services/supabase_service.dart';
import '../main_shell.dart';
import '../onboarding/onboarding_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _c =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _f = List.generate(4, (_) => FocusNode());
  bool _loading = false;
  int _seconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _seconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  String get _otp => _c.map((e) => e.text).join();

  Future<void> _verify() async {
    if (_otp.length != 4) return;
    setState(() => _loading = true);
    final ok = await Msg91Service.instance.verifyOtp(widget.phone, _otp);
    if (!mounted) return;
    if (ok) {
      try {
        await SupabaseService.instance.signInWithVerifiedPhone(widget.phone);
        await SupabaseService.instance.loadLibraries();
        final lib = SupabaseService.instance.library;
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  lib == null ? const OnboardingScreen() : const MainShell()),
          (_) => false,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _c) {
      c.dispose();
    }
    for (final f in _f) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text('Verify OTP',
                  style: GoogleFonts.lexend(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.lexend(
                      fontSize: 15, color: AppColors.inkSoft),
                  children: [
                    const TextSpan(text: 'Enter the 4-digit code sent to\n'),
                    TextSpan(
                        text: widget.phone,
                        style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              AutofillGroup(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (i) => _otpBox(i)),
                ),
              ),
              const SizedBox(height: 36),
              _loading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(
                      onPressed: _verify, child: const Text('Verify & Continue')),
              const SizedBox(height: 22),
              Center(
                child: _seconds > 0
                    ? Text('Resend code in 0:${_seconds.toString().padLeft(2, '0')}',
                        style: GoogleFonts.lexend(
                            color: AppColors.inkFaint, fontSize: 13))
                    : TextButton(
                        onPressed: () async {
                          await Msg91Service.instance.resendOtp(widget.phone);
                          _startTimer();
                        },
                        child: Text('Resend OTP',
                            style: GoogleFonts.lexend(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Spreads an SMS-autofilled code (e.g. "1234") across all four boxes.
  void _distribute(String code) {
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
    for (var j = 0; j < 4; j++) {
      _c[j].text = j < digits.length ? digits[j] : '';
    }
    FocusScope.of(context).unfocus();
    setState(() {});
    if (_otp.length == 4) _verify();
  }

  Widget _otpBox(int i) {
    return SizedBox(
      width: 62,
      height: 64,
      child: TextField(
        controller: _c[i],
        focusNode: _f[i],
        autofocus: i == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        // Only the first box advertises the OTP hint; autofill drops the whole
        // code here and _distribute() spreads it across the boxes.
        autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
        style: GoogleFonts.lexend(
            fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(i == 0 ? 4 : 1),
        ],
        decoration: const InputDecoration(counterText: ''),
        onChanged: (v) {
          if (v.length > 1) {
            _distribute(v);
            return;
          }
          if (v.isNotEmpty && i < 3) _f[i + 1].requestFocus();
          if (v.isEmpty && i > 0) _f[i - 1].requestFocus();
          if (i == 3 && v.isNotEmpty && _otp.length == 4) _verify();
          setState(() {});
        },
      ),
    );
  }
}
