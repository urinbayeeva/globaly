# Globaly

> Your companion for moving, studying, and living abroad.

Globaly is a Flutter app that guides a user end-to-end through relocating to
another country: it builds a personalised roadmap, lists the documents they
need, estimates visa costs, scans contracts for risky clauses, simulates a
visa interview, and answers questions through an AI assistant — localised in
English, Russian, and Uzbek.

---

## Features

| Area | What it does |
| --- | --- |
| **Auth** | Email/password, email verification via 6-digit OTP, and Google sign-in |
| **Onboarding** | Country + purpose pickers that tailor the rest of the app |
| **Home** | Visa-cost estimate, required documents, and a next-best-action card |
| **Roadmap** | AI-generated, country/purpose-specific relocation plan |
| **Documents** | Required vs. recommended document checklist per destination |
| **Scan** | Camera/gallery contract scanning with AI risk flagging |
| **Chat** | AI assistant scoped to moving abroad |
| **Score** | "Success score" with adjustable factors and matched universities |
| **Translator / Interview** | AI document translation and visa-interview practice |
| **Recommendations** | Travel, work, and business opportunities by country |

---

## Tech stack

| Concern | Choice |
| --- | --- |
| State management | `flutter_bloc` + `equatable` |
| Navigation | `go_router` (tab routes under a `ShellRoute`) |
| Dependency injection | `get_it` (manual registration, no codegen) |
| Networking | `dio` |
| Backend | Firebase Auth + Cloud Firestore |
| AI | Gemini (primary) with a Groq fallback |
| Email (OTP) | Resend HTTP API |
| Local storage | `shared_preferences`, `flutter_secure_storage` |
| Functional types | `dartz` (`Either<Failure, T>`) |
| Localization | In-app key/value bundles (en, ru, uz) |

---

## Architecture

Clean Architecture with a **feature-first** layout. Each feature owns three
layers: the presentation layer talks to a Cubit, the Cubit to a repository
contract, and only the data layer knows about Firebase or the network.

```
lib/
├── core/                      # Cross-cutting concerns
│   ├── config/                # Env / API keys
│   ├── di/                    # get_it container
│   ├── error/                 # Failure + Exception types
│   ├── extensions/            # BuildContext helpers
│   ├── i18n/                  # Localized string bundles
│   ├── network/               # Dio client, connectivity
│   ├── router/                # GoRouter config + route names
│   ├── services/              # Gemini, Groq, Resend, currency, location
│   ├── storage/               # Prefs, secure storage
│   ├── theme/                 # Colors, typography, spacing, radii
│   └── widgets/               # Shared widgets (buttons, cards, glass panel…)
└── features/<feature>/
    ├── data/
    │   ├── datasources/       # Firebase / HTTP sources
    │   ├── models/            # DTOs (map ↔ entity)
    │   └── repositories/      # Repository implementations
    ├── domain/
    │   ├── entities/          # Pure business objects
    │   └── repositories/      # Repository contracts
    └── presentation/
        ├── bloc/              # Cubits + states
        ├── pages/             # Screens
        └── widgets/           # Feature-scoped widgets
```

Conventions: SOLID / DRY / KISS, one widget per concern, shared UI extracted to
`core/widgets`, and the codebase is kept formatted with `dart format`.

### App flow

```
Splash → Sign in / Sign up → Onboarding → Country → Purpose → Shell
                                                               ├─ Home
                                                               ├─ Roadmap
                                                               ├─ Scan
                                                               ├─ Chat
                                                               └─ Profile
```

---

## Getting started

### Prerequisites

- Flutter SDK (Dart `>=3.3`)
- Xcode (iOS) / Android SDK
- A Firebase project with the native config files in place:
  - `ios/Runner/GoogleService-Info.plist`
  - `android/app/google-services.json`

### Run

```bash
flutter pub get
flutter run
```

iOS pulls its pods automatically on the first build. For a release build, pass
the keys explicitly:

```bash
flutter run --dart-define-from-file=.env.json
```

---

## Configuration

API keys live in `.env.json` at the repo root. They are read at build time via
`--dart-define-from-file`, and the file is also bundled as an asset so the app
still finds them when launched without the flag.

```json
{
  "GEMINI_API_KEY": "…",
  "GROQ_API_KEY": "…",
  "RESEND_API_KEY": "…",
  "RESEND_FROM": "Globaly <onboarding@resend.dev>"
}
```

- **Gemini / Groq** — the AI layer degrades to canned offline replies when both keys are absent.
- **Resend** — required for the sign-up OTP email. Without a key the code is logged to the console so the flow stays testable. The default `onboarding@resend.dev` sender only delivers to your own Resend account email; verify a domain for production.

### Firebase

1. Enable **Email/Password** and **Google** providers in Authentication.
2. Create Cloud Firestore and publish the rules: `firebase deploy --only firestore:rules`.
3. Apple sign-in requires a paid Apple Developer account, the "Sign in with Apple" Xcode capability, and the Apple provider enabled in Firebase. The button is gated behind `kAppleSignInEnabled` until then.

### Firestore data model

```
countries/{code}                     { name, flagEmoji, region }
costOfLiving/{code}                  { country, currency, monthlyTotal }
costOfLiving/{code}/items/{id}       { category, label, monthly }
email_verifications/{email}          { hash, attempts, expiresAt }   # transient OTP
users/{uid}                          { email, name, country, purpose, … }
users/{uid}/roadmap/{stepId}         { order, title, subtitle, status }
users/{uid}/score/current            { total, factors[] }
users/{uid}/documents/{docId}        { title, subtitle, createdAt }
users/{uid}/messages/{messageId}     { author, content, sentAt }
```

---

## Localization

Strings live in `lib/core/i18n/` as per-language maps. Resolve them with
`T.of(context, 'key')` in widgets or `T.t('key')` without a context. Missing
keys fall back to English; add every new key to all three bundles.

---

## Tests

```bash
flutter test
```
