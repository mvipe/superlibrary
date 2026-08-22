/// MSG91 OTP configuration.
///
/// SECURITY NOTE: The authKey should ideally live server-side (a Supabase Edge
/// Function) so it is never shipped inside the APK. For quick testing you can
/// place it here, but move it to `services/msg91_service.dart`'s edge-function
/// path before going to production.
class Msg91Config {
  static const String authKey = '562549AE9aSeIOVq6a86cc5eP1';
  static const String templateId = '6a86cbffbe5f108ef70feb73';

  static const String senderId = 'SUPLIB';
  static const int otpLength = 4;
  static const int otpExpirySeconds = 300;

  /// MSG91 Flow ID for the SMS reminder template (membership expiry / welcome).
  /// Leave null to run SMS reminders in SIMULATE mode (no real SMS sent).
  /// Set your Flow ID here once your template is approved to send real SMS.
  static const String? smsFlowId = null;

  /// ─── TEST BYPASS NUMBER ────────────────────────────────────────────────
  /// MSG91 stays ON for every REAL number (real SMS OTP is sent & verified).
  /// ONLY this one number is a bypass: no SMS is sent, and OTP `1234` logs in.
  /// Use it for demos / Play Store review without spending SMS credits.
  ///
  ///   Test Mobile: 9999999999   →   OTP: 1234
  ///
  /// Set [enableTestBypass] = false before final production release to make
  /// EVERY number (including this one) go through real MSG91.
  static const bool enableTestBypass = true;
  static const String testPhone = '9999999999';
  static const String testOtp = '1234';

  /// If you deploy the send/verify OTP as a Supabase Edge Function, put its URL
  /// here and MSG91Service will call that instead of hitting MSG91 directly.
  static const String? edgeFunctionUrl = null; // e.g. '<supabase-url>/functions/v1/otp'
}
