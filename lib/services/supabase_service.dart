import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

enum AuthStage { login, onboarding, ready }

/// Auth + tenant (library) management.
///
/// Real mode: an MSG91-verified phone is bridged to a real Supabase
/// email/password session (deterministic credentials) so RLS works and data
/// persists per phone. Preview mode: state is kept in SharedPreferences so the
/// full login -> onboarding -> app flow is demonstrable with no backend.
class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  final List<Library> _libraries = [];
  List<Library> get libraries => List.unmodifiable(_libraries);
  Library? _library;
  Library? get library => _library;
  String? get libraryId => _library?.id;
  String _phone = '';

  static const _curLibKey = 'current_library_id';

  bool get _live => SupabaseConfig.isConfigured;
  SupabaseClient get _c => Supabase.instance.client;

  static Future<void> init() async {
    if (!SupabaseConfig.isConfigured) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // ---- deterministic credentials from phone ------------------------------
  String _emailFor(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return 'u$digits@${SupabaseConfig.emailDomain}';
  }

  String _passwordFor(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return 'SL_${SupabaseConfig.authSalt}_$digits!7';
  }

  String _genReferralCode() {
    final base =
        DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase();
    return 'SL${base.substring(base.length - 6)}';
  }

  // ---- startup routing ---------------------------------------------------
  Future<AuthStage> bootstrap() async {
    if (_live) {
      if (_c.auth.currentSession == null) return AuthStage.login;
      await loadLibraries();
      return _library == null ? AuthStage.onboarding : AuthStage.ready;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('local_signed_in') ?? false)) return AuthStage.login;
    _phone = prefs.getString('local_phone') ?? '';
    await loadLibraries();
    return _library == null ? AuthStage.onboarding : AuthStage.ready;
  }

  // ---- sign in (after MSG91 OTP verified) --------------------------------
  Future<void> signInWithVerifiedPhone(String phone) async {
    _phone = phone;
    if (!_live) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('local_signed_in', true);
      await prefs.setString('local_phone', phone);
      return;
    }
    final email = _emailFor(phone);
    final password = _passwordFor(phone);
    try {
      await _c.auth.signInWithPassword(email: email, password: password);
    } on AuthException {
      // First time for this phone -> create the account, then it is signed in.
      await _c.auth.signUp(email: email, password: password);
      if (_c.auth.currentSession == null) {
        await _c.auth.signInWithPassword(email: email, password: password);
      }
    }
    // A valid session is REQUIRED for RLS (owner_id = auth.uid()). If it is
    // still null, email confirmation is almost certainly ON in Supabase.
    if (_c.auth.currentSession == null) {
      throw Exception(
          'No Supabase session was created. In Supabase go to '
          'Authentication → Providers → Email and turn OFF "Confirm email", '
          'then try again.');
    }
  }

  // ---- libraries (multi-branch tenants) ----------------------------------
  Future<List<Library>> loadLibraries() async {
    _libraries.clear();
    if (_live) {
      final rows = await _c
          .from('libraries')
          .select()
          .order('created_at', ascending: true);
      _libraries.addAll((rows as List).map((e) => Library.fromMap(e)));
    } else {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_libraries');
      if (raw != null) {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        _libraries.addAll(list.map(Library.fromMap));
      }
    }
    await _selectCurrent();
    return _libraries;
  }

  Future<void> _selectCurrent() async {
    if (_libraries.isEmpty) {
      _library = null;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_curLibKey);
    _library = _libraries.firstWhere(
      (l) => l.id == savedId,
      orElse: () => _libraries.first,
    );
  }

  Future<void> switchLibrary(String id) async {
    final match = _libraries.where((l) => l.id == id);
    if (match.isEmpty) return;
    _library = match.first;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_curLibKey, id);
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'local_libraries', jsonEncode(_libraries.map((l) => {
              'id': l.id,
              'name': l.name,
              'admin_name': l.adminName,
              'admin_phone': l.adminPhone,
              'admin_email': l.adminEmail,
              'total_seats': l.totalSeats,
            }).toList()));
  }

  Future<Library> createLibrary({
    required String name,
    required String adminName,
    required String adminEmail,
    int totalSeats = 30,
  }) async {
    // New libraries start on a 14-day free trial with a unique referral code.
    final trialEnds = DateTime.now().add(const Duration(days: 14));
    final refCode = _genReferralCode();
    late Library lib;
    if (_live) {
      final row = await _c
          .from('libraries')
          .insert({
            'owner_id': _c.auth.currentUser?.id,
            'name': name,
            'admin_name': adminName,
            'admin_phone': _phone,
            'admin_email': adminEmail,
            'total_seats': totalSeats,
            'plan': 'trial',
            'plan_expires_at': trialEnds.toIso8601String(),
            'referral_code': refCode,
          })
          .select()
          .single();
      lib = Library.fromMap(row);
    } else {
      lib = Library(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        adminName: adminName,
        adminPhone: _phone,
        adminEmail: adminEmail,
        totalSeats: totalSeats,
        plan: 'trial',
        planExpiresAt: trialEnds,
        referralCode: refCode,
      );
      _libraries.add(lib);
      await _persistLocal();
    }
    _libraries.removeWhere((l) => l.id == lib.id);
    _libraries.add(lib);
    await switchLibrary(lib.id);
    return lib;
  }

  Future<void> updateLibrary(Library lib) async {
    if (_live) {
      await _c.from('libraries').update(lib.toMap()).eq('id', lib.id);
    }
    final i = _libraries.indexWhere((l) => l.id == lib.id);
    if (i != -1) _libraries[i] = lib;
    if (_library?.id == lib.id) _library = lib;
    if (!_live) await _persistLocal();
  }

  Future<void> deleteLibrary(String id) async {
    if (_live) {
      await _c.from('libraries').delete().eq('id', id);
    }
    _libraries.removeWhere((l) => l.id == id);
    if (!_live) await _persistLocal();
    if (_library?.id == id) {
      _library = _libraries.isEmpty ? null : _libraries.first;
      if (_library != null) await switchLibrary(_library!.id);
    }
  }

  Future<void> signOut() async {
    _library = null;
    _libraries.clear();
    if (!_live) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_signed_in');
      return;
    }
    await _c.auth.signOut();
  }
}
