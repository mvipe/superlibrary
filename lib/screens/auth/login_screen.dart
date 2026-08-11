import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../config/msg91_config.dart';
import '../../services/msg91_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  bool _loading = false;

  Future<void> _sendOtp() async {
    final digits = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit mobile number')),
      );
      return;
    }
    setState(() => _loading = true);
    final phone = '+91$digits';
    final ok = await Msg91Service.instance.sendOtp(phone);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send OTP. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.heroGradient),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 28),
              Text('SuperLibrary',
                  style: GoogleFonts.lexend(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              Text('Manage your library like a pro.',
                  style: GoogleFonts.lexend(
                      fontSize: 15, color: AppColors.inkSoft)),
              const SizedBox(height: 44),
              Text('Mobile Number',
                  style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w600, color: AppColors.ink)),
              const SizedBox(height: 10),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: GoogleFonts.lexend(
                    fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '98765 43210',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🇮🇳 +91',
                            style: GoogleFonts.lexend(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                            width: 1, height: 24, color: AppColors.border),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _loading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _sendOtp,
                      child: const Text('Send OTP'),
                    ),
              const SizedBox(height: 18),
              Center(
                child: Text('We will send a verification code via SMS',
                    style: GoogleFonts.lexend(
                        fontSize: 12.5, color: AppColors.inkFaint)),
              ),
              if (Msg91Config.enableTestBypass) ...[
                const SizedBox(height: 24),
                InkWell(
                  onTap: () => setState(() => _phone.text = Msg91Config.testPhone),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.18)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.science_rounded,
                            size: 18, color: AppColors.primary),
   const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.lexend(
                                  fontSize: 12.5, color: AppColors.inkSoft),
                              children: [
                                const TextSpan(text: 'Test login  •  '),
                                TextSpan(
                                    text: '${Msg91Config.testPhone}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink)),
                                const TextSpan(text: '   OTP '),
                                TextSpan(
                                    text: Msg91Config.testOtp,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink)),
                              ],
                            ),
                          ),
                        ),
                        Text('Tap to fill',
                            style: GoogleFonts.lexend(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}