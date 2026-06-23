# Globaly — Global Helper

Your companion for moving, studying, and living abroad.

## Architecture

This project follows **Clean Architecture** with a **feature-first** folder layout and is driven by **SOLID, DRY, and KISS** principles.

```
lib/
├── core/                       # Cross-cutting concerns
│   ├── constants/              # App-wide constants (strings, sizes, durations)
│   ├── di/                     # Dependency injection (get_it)
│   ├── errors/                 # Failure + Exception types
│   ├── extensions/             # Dart/Flutter extensions
│   ├── network/                # Dio client, interceptors, network info
│   ├── router/                 # GoRouter config + route names
│   ├── theme/                  # ThemeData, AppColors, AppTypography
│   ├── utils/                  # Helpers
│   └── widgets/                # Reusable widgets
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── datasources/    # Remote/local data sources
│       │   ├── models/         # DTOs (JSON ↔ entity)
│       │   └── repositories/   # Repository implementations
│       ├── domain/
│       │   ├── entities/       # Pure business objects
│       │   ├── repositories/   # Repository contracts (interfaces)
│       │   └── usecases/       # Single-purpose business rules
│       └── presentation/
│           ├── bloc/           # Bloc / Cubit
│           ├── pages/          # Screens
│           └── widgets/        # Feature-scoped widgets
├── app.dart                    # MaterialApp setup
└── main.dart                   # Entry point + bootstrap
```

## Stack

| Concern              | Choice                               |
| -------------------- | ------------------------------------ |
| State management     | `flutter_bloc` + `equatable`         |
| Navigation           | `go_router`                          |
| Dependency injection | `get_it` (manual registration)       |
| Networking           | `dio` (+ logger, retry, auth)        |
| Backend              | Firebase (Auth, Firestore, Storage)  |
| Local storage        | `shared_preferences`, `secure_storage` |
| Functional types     | `dartz` (`Either<Failure, T>`)       |

## Principles

- **SOLID** — every class has a single reason to change. Repositories depend on abstractions, not Firebase directly.
- **DRY** — shared widgets in `core/widgets`, shared types in `core/`. No duplicated theme/strings/sizes.
- **KISS** — small files (most ≤ 100 lines), one widget per file, no magic.
- **Testable** — usecases and repos are pure functions of their dependencies; UI talks only to Blocs.

## Getting Started

```bash
flutter pub get
flutter run
```

### Firebase setup

Batafsil yo'riqnoma: [`FIREBASE_SETUP.md`](./FIREBASE_SETUP.md).

Qisqacha:

1. [console.firebase.google.com](https://console.firebase.google.com) — loyiha yarating.
2. Auth → Email/Password yoqing. Firestore'ni yarating. (Storage hozircha kerak emas — Blaze plan talab qiladi.)
3. Loyihaga Android + iOS ilovalarini qo'shing (`google-services.json`, `GoogleService-Info.plist`).
4. `flutterfire configure` — `firebase_options.dart` avtomatik hosil bo'ladi.
5. `firebase deploy --only firestore:rules` — security rules'ni joylashtiring.
6. Seed Firestore: `flutter run -t tool/seed_firestore.dart` — bir marta ishga tushiring va "Seed" tugmasini bosing.

### Firestore data model

```
countries/{code}                          { name, flagEmoji, region }
costOfLiving/{code}                       { country, currency, monthlyTotal }
costOfLiving/{code}/items/{itemId}        { category, label, monthly }

users/{uid}                               { email, displayName, country, purpose, ... }
users/{uid}/roadmap/{stepId}              { order, title, subtitle, status }
users/{uid}/score/current                 { total, factors[] }
users/{uid}/documents/{docId}             { title, subtitle, createdAt }
users/{uid}/messages/{messageId}          { author, content, sentAt }
```

## App Flow

```
Splash → Auth → Onboarding (3) → Country Picker → Purpose Picker → Main
                                                                    ├─ Home   (+ Score, Cost-of-Living, Doc preview)
                                                                    ├─ Roadmap
                                                                    ├─ Scan
                                                                    ├─ Chat
                                                                    └─ Profile
```
