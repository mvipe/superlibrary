import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/msg91_config.dart';
import '../config/supabase_config.dart';

/// Handles sending & verifying OTPs via MSG91.
///
/// Two modes:
///  1. Edge-function mode (recommended): set Msg91Config.edgeFunctionUrl so the
///     authKey stays server-side.
///  2. Direct mode: calls MSG91 API from the app (fine for testing only).
///
/// When SupabaseConfig.useMockData == true, OTP is faked as `1234`.
class Msg91Service {
  Msg91Service._();
  static final instance = Msg91Service._();

  Future<bool> sendOtp(String phoneE164) async {
    if (SupabaseConfig.useMockData) {
      // ignore: avoid_print
      print('[MOCK] OTP for $phoneE164 is 1234');
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    }

    final mobile = phoneE164.replaceAll(RegExp(r'[^0-9]'), '');

    if (Msg91Config.edgeFunctionUrl != null) {
      final res = await http.post(
        Uri.parse('${Msg91Config.edgeFunctionUrl}/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      );
      return res.statusCode == 200;
    }

    final res = await http.post(
      Uri.parse('https://control.msg91.com/api/v5/otp'),
      headers: {
        'Content-Type': 'application/json',
        'authkey': Msg91Config.authKey,
      },
      body: jsonEncode({
        'template_id': Msg91Config.templateId,
        'mobile': mobile,
        'otp_length': Msg91Config.otpLength,
        'otp_expiry': (Msg91Config.otpExpirySeconds ~/ 60),
      }),
    );
    return res.statusCode == 200;
  }

  Future<bool> verifyOtp(String phoneE164, String otp) async {
    if (SupabaseConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return otp.trim() == '1234';
    }

    final mobile = phoneE164.replaceAll(RegExp(r'[^0-9]'), '');

    if (Msg91Config.edgeFunctionUrl != null) {
      final res = await http.post(
        Uri.parse('${Msg91Config.edgeFunctionUrl}/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'otp': otp}),
      );
      return res.statusCode == 200;
    }

    final res = await http.get(
      Uri.parse(
          'https://control.msg91.com/api/v5/otp/verify?otp=$otp&mobile=$mobile'),
      headers: {'authkey': Msg91Config.authKey},
    );
    if (res.statusCode != 200) return false;
    final body = jsonDecode(res.body);
    return body['type'] == 'success';
  }

  Future<bool> resendOtp(String phoneE164) async {
    if (SupabaseConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }
    final mobile = phoneE164.replaceAll(RegExp(r'[^0-9]'), '');
    final res = await http.get(
      Uri.parse(
          'https://control.msg91.com/api/v5/otp/retry?mobile=$mobile&retrytype=text'),
      headers: {'authkey': Msg91Config.authKey},
    );
    return res.statusCode == 200;
  }

  /// Sends a custom reminder SMS via an MSG91 Flow. Returns true on success.
  /// If no Flow ID is configured, it is simulated (returns true) so the app is
  /// testable without live SMS credits.
  Future<bool> sendReminder(String phoneE164, Map<String, String> vars) async {
    const flowId = Msg91Config.smsFlowId;
    if (flowId == null || SupabaseConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 120));
      return true; // simulated
    }
    final mobile = phoneE164.replaceAll(RegExp(r'[^0-9]'), '');
    final recipient = <String, String>{'mobiles': mobile, ...vars};
    final res = await http.post(
      Uri.parse('https://control.msg91.com/api/v5/flow/'),
      headers: {
        'Content-Type': 'application/json',
        'authkey': Msg91Config.authKey,
      },
      body: jsonEncode({
        'flow_id': flowId,
        'sender': Msg91Config.senderId,
        'recipients': [recipient],
      }),
    );
    return res.statusCode == 200;
  }
}
