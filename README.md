# SuperLibrary 📚

Premium library management app (GoLibrary-style) — Flutter + Supabase + Razorpay.

## Turant chalao (koi backend nahi chahiye)

```bash
flutter pub get
flutter run
```

- Login: koi bhi 10-digit number → OTP `1234`
- Pehli baar: **Onboarding** form (library + admin naam) bharo → app khul jayega
- Bina Supabase ke bhi **poora CRUD chalta hai** (in-memory) — member/book add-edit-delete, fee collect, attendance, issue/return sab. App band karne pe local data reset ho jayega (kyunki backend off hai).

## Sab kuch LIVE + permanent karna (Supabase)

1. **Supabase project** banao → `Project Settings → API` se `URL` aur `anon key` copy karo.
2. `lib/config/supabase_config.dart` mein daalo:
   ```dart
   static const String url = 'https://xxxx.supabase.co';
   static const String anonKey = 'eyJhbGci...';
   static const String authSalt = 'koi-lamba-random-string'; // apna rakho
   ```
   (`useMockData`/`isConfigured` khud switch ho jata hai — keys daalte hi live mode on.)
3. Supabase → **SQL Editor** → `supabase_schema.sql` ka poora content paste karke **Run**.
4. Supabase → **Auth → Providers → Email** → **"Confirm email" OFF** karo.
   (App phone→email/password session bridge karti hai; confirm on ho toh pehla login session nahi banata.)
5. `flutter run`. Ab har cheez database se aati hai aur phone-wise permanently save hoti hai.

> Har admin (phone) ka apna library + apna data — RLS se dusra koi nahi dekh sakta.

## Razorpay (Collect Fee)

- `lib/config/razorpay_config.dart` mein `keyId` daalo (test ke liye `rzp_test_...`).
- Payments → **Collect Fee** → method **Razorpay** choose karo → real checkout khulta hai.
- Success pe payment DB mein `paid` save hota hai.

> ⚠️ Asli paise ke liye order-create + signature-verify **server (Supabase Edge Function)** pe karna zaroori hai. App mein sirf public `keyId` rakho, SECRET kabhi nahi.

## MSG91 OTP (asli SMS)

- `lib/config/msg91_config.dart` mein `authKey` + `templateId` daalo.
- Better: `authKey` ko Edge Function mein rakho aur `edgeFunctionUrl` set karo (APK mein expose na ho).

## Theme colours 🎨

- Drawer → **App Theme** (ya Dashboard → Theme) → 5 presets: Coral, Indigo, Emerald, Violet, Ocean.
- Ek tap mein poora app re-skin, choice save ho jati hai.

## Features

- Phone login → OTP → **onboarding/registration** → dashboard
- **Members** — add / edit / delete, search, filter, live stats
- **Books** — add / edit / delete, cover colour, availability
- **Issue / Return** — member + book scan/enter, copies auto-update
- **Payments** — Collect Fee (Cash / Razorpay), collection summary
- **Attendance** — QR scan (mobile_scanner) ya member ID se present mark
- **Reports** — live stat cards + 7-day issued/returned chart + top books
- **Dashboard** — live aggregates, pull-to-refresh
- **Theme switcher** (5 colours, persisted) + tighter border-radius

## Architecture

- `lib/config/` — Supabase / MSG91 / Razorpay keys
- `lib/theme/` — colours (dynamic brand), theme, ThemeController
- `lib/models/` — data models (fromMap/toMap/copyWith)
- `lib/data/repo.dart` — **single data API**: Supabase jab configured, warna in-memory
- `lib/services/` — Supabase auth+library, MSG91, Razorpay
- `lib/screens/` — saari screens + forms

## Build APK

```bash
flutter build apk
```
`build/app/outputs/flutter-apk/app-release.apk`
