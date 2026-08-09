import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/supabase_service.dart';
import 'auth/login_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'main_shell.dart';

/// Decides the first screen: login -> onboarding -> app, based on the
/// persisted session and whether a library has been created yet.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthStage>(
      future: SupabaseService.instance.bootstrap(),
      builder: (context, snap) {
        if (!snap.hasData) return const _Splash();
        return switch (snap.data!) {
          AuthStage.login => const LoginScreen(),
          AuthStage.onboarding => const OnboardingScreen(),
          AuthStage.ready => const MainShell(),
        };
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: AppColors.heroGradient),
                borderRadius: BorderRadius.circular(AppColors.rXl),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text('SuperLibrary',
                style: GoogleFonts.lexend(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 16),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
