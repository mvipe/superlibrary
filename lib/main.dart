import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'services/supabase_service.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await ThemeController.instance.load();
  await SupabaseService.init();
  runApp(const SuperLibraryApp());
}

class SuperLibraryApp extends StatelessWidget {
  const SuperLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds (with a fresh ThemeData) whenever the brand theme changes.
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) => MaterialApp(
        // The ValueKey forces the whole widget tree to rebuild when the brand
        // theme changes, so every screen (not just the drawer) re-skins.
        key: ValueKey('theme-${ThemeController.instance.brand.id}'),
        title: 'SuperLibrary',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
