class Msg91Config {
  static const String authKey = '404117AQvUYpgj64e33a96P1';
  static const String templateId = '64e3441ad6fc05126946fb23';

  static const String senderId = 'SUPLIB';
  static const int otpLength = 4;
  static const int otpExpirySeconds = 300;

  /// MSG91 Flow ID used to send custom reminder SMS (membership expiry, etc.).
  /// Create a Flow in the MSG91 dashboard with a `##name##` and `##days##`
  /// variable, then paste its Flow ID here. While null, reminder sending is
  /// simulated (no real SMS is dispatched) so the UI stays fully testable.
  static const String? smsFlowId = null;

  /// If you deploy the send/verify OTP as a Supabase Edge Function, put its URL
  /// here and MSG91Service will call that instead of hitting MSG91 directly.
  static const String? edgeFunctionUrl = null; // e.g. '<supabase-url>/functions/v1/otp'
}
