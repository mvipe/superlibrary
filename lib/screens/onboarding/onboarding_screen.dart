import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../data/repo.dart';
import '../main_shell.dart';

/// Shown once, right after the first successful login: the admin sets up their
/// library. Saved to the database (or local preview store) and never shown
/// again for this account.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _lib = TextEditingController();
  final _admin = TextEditingController();
  final _email = TextEditingController();
  final _referral = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (_lib.text.trim().isEmpty || _admin.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter library and admin name')));
      return;
    }
    setState(() => _loading = true);
    try {
      final lib = await SupabaseService.instance.createLibrary(
        name: _lib.text.trim(),
        adminName: _admin.text.trim(),
        adminEmail: _email.text.trim(),
      );
      // If they were referred, record it against the referrer's code.
      if (_referral.text.trim().isNotEmpty) {
        await Repo.instance.addReferral(
            referrerCode: _referral.text.trim(), referredLib: lib);
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  void dispose() {
    _lib.dispose();
    _admin.dispose();
    _email.dispose();
    _referral.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.heroGradient),
                  borderRadius: BorderRadius.circular(AppColors.rXl),
                ),
                child: const Icon(Icons.store_mall_directory_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 24),
              Text('Set up your library',
                  style: GoogleFonts.lexend(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              Text('A few details to get you started. You can change these later.',
                  style: GoogleFonts.lexend(
                      fontSize: 14.5, color: AppColors.inkSoft)),
              const SizedBox(height: 32),
              _label('Library Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _lib,
                decoration: const InputDecoration(
                    hintText: 'e.g. Krish Study Library',
                    prefixIcon: Icon(Icons.menu_book_rounded, size: 20)),
              ),
              const SizedBox(height: 18),
              _label('Admin Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _admin,
                decoration: const InputDecoration(
                    hintText: 'Your full name',
                    prefixIcon: Icon(Icons.person_rounded, size: 20)),
              ),
              const SizedBox(height: 18),
              _label('Admin Email (optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    hintText: 'you@email.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20)),
              ),
              const SizedBox(height: 18),
              _label('Referral Code (optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _referral,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: const InputDecoration(
                    hintText: 'e.g. SLAB12CD',
                    prefixIcon: Icon(Icons.card_giftcard_rounded, size: 20)),
              ),
              const SizedBox(height: 6),
              Text('Have a friend\'s code? You both earn ₹200.',
                  style: GoogleFonts.lexend(
                      fontSize: 12, color: AppColors.inkFaint)),
              const SizedBox(height: 32),
              _loading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Create & Continue')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.lexend(
          fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.ink));
}

/// Forces typed text to uppercase (used for the referral code field).
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
