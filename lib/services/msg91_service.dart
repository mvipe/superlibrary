import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/msg91_config.dart';

/// Handles sending & verifying OTPs via MSG91.
///
/// MSG91 is ALWAYS ON for real numbers — real SMS OTP is sent and verified.
///
/// The ONLY exception is the configured test-bypass number
/// (Msg91Config.testPhone). For that single number no SMS is sent and the
/// fixed OTP (Msg91Config.testOtp) logs in. Toggle it via
/// Msg91Config.enableTestBypass.
///
/// Two real modes:
///  1. Edge-function mode (recommended): set Msg91Config.edgeFunctionUrl so the
///     authKey stays server-side.
///  2. Direct mode: calls MSG91 API from the app (fine for testing only).
class Msg91Service {
  Msg91Service._();
  static final instance = Msg91Service._();

  bool _isBypass(String phoneE164) {
    if (!Msg91Config.enableTestBypass) return false;
    final digits = phoneE164.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.endsWith(Msg91Config.testPhone);
  }

  Future<bool> sendOtp(String phoneE164) async {
    // Test-bypass number: skip MSG91 entirely, no SMS sent.
    if (_isBypass(phoneE164)) {
      // ignore: avoid_print
      print('[BYPASS] Test number $phoneE164 → OTP ${Msg91Config.testOtp}');
      await Future.delayed(const Duration(milliseconds: 400));
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
    // Test-bypass number: accept the fixed OTP, no MSG91 call.
    if (_isBypass(phoneE164)) {
      await Future.delayed(const Duration(milliseconds: 300));
      return otp.trim() == Msg91Config.testOtp;
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
    // Test-bypass number: nothing to resend.
    if (_isBypass(phoneE164)) {
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }
    final mobile = phoneE164.replaceAll(RegExp(r'[^0-9]'), '');

    if (Msg91Config.edgeFunctionUrl != null) {
      final res = await http.post(
        Uri.parse('${Msg91Config.edgeFunctionUrl}/resend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      );
      return res.statusCode == 200;
    }

    final res = await http.get(
      Uri.parse(
          'https://control.msg91.com/api/v5/otp/retry?mobile=$mobile&retrytype=text'),
      headers: {'authkey': Msg91Config.authKey},
    );
    return res.statusCode == 200;
  }
}