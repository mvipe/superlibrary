import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

/// Holds the selected brand theme and persists it. The root [AnimatedBuilder]
/// listens to this so switching a theme re-skins the entire app instantly.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _prefKey = 'brand_theme_id';
  BrandTheme _brand = AppColors.presets.first;
  BrandTheme get brand => _brand;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKey);
    if (id != null) {
      _brand = AppColors.byId(id);
      AppColors.apply(_brand);
    }
  }

  Future<void> select(BrandTheme t) async {
    _brand = t;
    AppColors.apply(t);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, t.id);
  }
}
