/// Razorpay checkout configuration.
///
/// Get your keys from: Razorpay Dashboard -> Settings -> API Keys.
/// Use the TEST key (rzp_test_...) while developing; switch to the LIVE key
/// (rzp_live_...) only for production.
///
/// SECURITY: For real money you must verify the payment signature on a server
/// (a Supabase Edge Function) and never ship the key SECRET in the app — only
/// the key ID below is safe on the client.
class RazorpayConfig {
  static const String keyId = 'rzp_test_SytU0WbPqoBdi0';

  static bool get isConfigured => !keyId.contains('rzp_test_SytU0WbPqoBdi0');

  static const String companyName = 'SuperLibrary';
  static const String currency = 'INR';
}
