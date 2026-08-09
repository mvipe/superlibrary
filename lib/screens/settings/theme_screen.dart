import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/common.dart';

/// Lets the admin re-skin the whole app with one tap. The choice is persisted.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('App Theme'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
      ),
      body: AnimatedBuilder(
        animation: ThemeController.instance,
        builder: (context, _) {
          final current = ThemeController.instance.brand;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
            children: [
              _preview(),
              const SizedBox(height: 22),
              Text('Choose a colour',
                  style: GoogleFonts.lexend(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 12),
              ...AppColors.presets.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _swatchTile(p, p.id == current.id),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _preview() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppColors.rXl),
        boxShadow: AppTheme.heroShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppColors.rLg),
            ),
            child: const Icon(Icons.palette_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live preview',
                    style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                Text('The whole app updates instantly',
                    style: GoogleFonts.lexend(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatchTile(BrandTheme p, bool selected) {
    return PremiumCard(
      onTap: () => ThemeController.instance.select(p),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: p.heroGradient),
              borderRadius: BorderRadius.circular(AppColors.rMd),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(p.name,
                style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: p.primary, size: 24)
          else
            const Icon(Icons.circle_outlined,
                color: AppColors.inkFaint, size: 24),
        ],
      ),
    );
  }
}
