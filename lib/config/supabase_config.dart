/// Supabase project credentials.
/// Fill these from: Supabase Dashboard -> Project Settings -> API
class SupabaseConfig {
  static const String url = 'https://pdmlflrcwafupfppdvkz.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBkbWxmbHJjd2FmdXBmcHBkdmt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU3NDMyMDcsImV4cCI6MjEwMTMxOTIwN30.y3ZA0gELLhTocpD_B31AlhzYtCsEDSqgpIABqrXpp1I';

  /// Password salt used to bridge the MSG91-verified phone to a real Supabase
  /// email/password session. Change this to any long random string of your own
  /// before shipping so account passwords are not guessable.
  static const String authSalt = 'sl_9f3ac71b_change_me';

  /// Domain used to build the internal login email for a phone
  /// (e.g. u91XXXXXXXXXX@<emailDomain>). Supabase rejects domains that have no
  /// mail (MX) records with `email_address_invalid`, so this MUST be a real
  /// domain that has MX records. `gmail.com` works out of the box. No real
  /// account is created and no mail is sent (email confirmation stays OFF) —
  /// this string only identifies the auth row inside YOUR Supabase project.
  /// You can change it to any domain you own that has MX records.
  static const String emailDomain = 'gmail.com';

  /// True once real credentials are filled in. When false the app runs on a
  /// fully-functional in-memory store (add/edit/delete all work) so you can
  /// preview everything with no backend.
  static bool get isConfigured =>
      !url.contains('YOUR_PROJECT_REF') && !anonKey.contains('YOUR_');

  /// Back-compat flag used by the OTP service (mock OTP = 1234 until live).
  static bool get useMockData => !isConfigured;
}
