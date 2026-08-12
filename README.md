# BMI Tracker

A Flutter-based BMI tracking application developed as part of the IV Innovations Private Limited assignment.

Professional BMI health tracking by **IV Innovations Private Limited** (Kundli, Sonipat). Track weight, height, BMI category, multi-profile family data, and 7-day trends with offline-first Hive storage and optional Firebase sync.

Package: `bmi_tracker` (`com.ivinnovations.bmi_tracker`)

## Project Links

| Resource | Link |
|----------|------|
| GitHub Repository | https://github.com/SAutopsYS/bmi-tracker.git |
| Demo Video (Google Drive) | https://drive.google.com/file/d/101nK0lAA-RHFVEmx691wGFVH6p9kSKrU/view?usp=sharing |

## Features

### Core

- Email/Password authentication (local Hive session when Firebase is off; Firebase Auth when configured)
- Google Sign-In (requires real Firebase config + Android SHA / iOS URL scheme)
- Multi-profile support (family members, isolated by `profileId`)
- BMI calculation (kg/m²) with WHO-aligned categories: Underweight, Normal, Overweight, Obese
- Weight and height units: kg/lbs and cm/inches (`UnitConverter` / `AppConstants`)
- Dashboard BMI card + gauge, recent history, 7-day statistics
- Weight history and `WeightTrendChart` (fl_chart)
- Input validation for name, email, password, weight, height, date of birth
- Light / Dark / System theme (Hive `settings_box`)
- Offline-first Hive cache with sync queue (`sync_queue_box`) when cloud is available
- Offline banner and pending sync count in Settings
- CSV export and share for selected profile
- Forgot password flow (Firebase Auth when configured)

### Bonus / demo

- Demo mode via `.env` (`DEMO_MODE`, `demo@bmitracker.demo`)
- Seeded profiles: **Rahul Sharma** and **Priya Sharma** (`DemoSeedService`)
- DEMO banner when `DEMO_MODE` is enabled
- Riverpod architecture, go_router, Material 3

## Tech stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter (Dart SDK >=3.5) |
| State | flutter_riverpod |
| Routing | go_router |
| Auth / cloud | firebase_auth, cloud_firestore, google_sign_in |
| Local DB | hive / hive_flutter |
| Charts | fl_chart |
| Env | flutter_dotenv |
| Tests | flutter_test, mocktail |

## Architecture

```
UI (screens / widgets)
    ↓
Providers (Riverpod)
    ↓
Repositories (auth, profile, health)
    ↓
Services (BMI, Auth, Firestore, Hive, Demo seed, Export, Connectivity)
    ↓
Models + core (validators, converters, theme, constants)
```

### Folder structure

```
lib/
  core/           # constants, theme, validators, utils, routing, errors
  models/         # profile, weight history, user, enums
  providers/      # auth, profile, health, theme, connectivity
  repositories/   # auth, profile, health
  screens/        # splash, auth, dashboard, profiles, history, settings, export
  services/       # bmi, auth, firestore, local storage, demo seed, export
  widgets/        # dashboard cards, forms, charts, common UI
  main.dart
  firebase_options.dart   # PLACEHOLDERS; kFirebaseConfigured = false
test/
  core/
  services/
  widget/
  helpers/
docs/
  ASSIGNMENT_REQUIREMENTS.md
  FINAL_QA_REPORT.md
  FIREBASE_SETUP.md
  DEMO_SETUP.md
  DEMO_VIDEO_SCRIPT.md
  INTERVIEW_NOTES.md
```

## Submission Checklist

Use this before packaging for IV Innovations review.

### Mandatory (1–4)

1. **Auth** — Email/password register + login work in local Hive mode; Google Sign-In and real password-reset email need Firebase (`kFirebaseConfigured` still **false** here).
2. **User details + BMI** — Profile setup form, unit conversion, BMI calc/categories, dashboard BMI card/gauge.
3. **Settings / updates / history graph** — Update height & weight, History screen, 7-day `WeightTrendChart` + week stats.
4. **Multi-user profiles** — Add / edit / delete (confirm) / switch (Rahul + Priya in demo seed).

### Bonus (5–7)

5. **Auth persistence + charts + errors** — Hive session restore; fl_chart; mapped failures / `ErrorView`.
6. **Dark mode + CSV export** — Light / Dark / System; export/share from Settings or Export route.
7. **Offline + demo** — Offline banner + Hive cache; demo via `.env` (see below). Cloud sync flush needs Firebase.

### Verification artifacts

| Item | Status in this repo |
|------|---------------------|
| Firebase / Google Sign-In / live Firestore | **Not configured** — CLI installed; run `firebase login` then [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md). Do not claim cloud verified |
| Debug SHA for Google Sign-In | SHA-1 / SHA-256 measured; paste in Firebase Android app settings (see FIREBASE_SETUP) |
| `flutter analyze` | **No issues found** (Phase 3; re-run after Firebase enable) |
| `flutter test` | **47 passed** (Phase 3; re-run after Firebase enable) |
| Debug APK | **Verified** → `build/app/outputs/flutter-apk/app-debug.apk` (154.11 MB) |
| Release APK | **Verified** → `build/app/outputs/flutter-apk/app-release.apk` (58.42 MB); **debug-signed for demo**; use `GRADLE_USER_HOME=D:\gradle-home` if C: is low on space |
| Launcher icon / label | Custom icons from `assets/images/app_icon.png`; label **BMI Tracker** |
| Demo video | Script: [docs/DEMO_VIDEO_SCRIPT.md](docs/DEMO_VIDEO_SCRIPT.md) |
| Requirements map / QA / interview | [docs/ASSIGNMENT_REQUIREMENTS.md](docs/ASSIGNMENT_REQUIREMENTS.md), [docs/FINAL_QA_REPORT.md](docs/FINAL_QA_REPORT.md), [docs/INTERVIEW_NOTES.md](docs/INTERVIEW_NOTES.md) |

### Demo `.env` (required for Try demo account)

```bash
cp .env.example .env
```

```env
DEMO_EMAIL=demo@bmitracker.demo
DEMO_PASSWORD=your-local-demo-password
DEMO_MODE=true
```

`DEMO_PASSWORD` must be non-empty for **Try demo account** (`DemoCredentials.isConfigured`). Never commit `.env`. Full steps: [docs/DEMO_SETUP.md](docs/DEMO_SETUP.md).

## Firebase status (important)

**Firebase is not production-configured in this repo.**

- `lib/firebase_options.dart` contains `YOUR_*` placeholders.
- `kFirebaseConfigured` is **`false`**. `main.dart` skips `Firebase.initializeApp`.
- Do **not** claim live cloud auth/sync until you run `flutterfire configure` and set `kFirebaseConfigured = true`.

**What still works without Firebase**

- Local Hive auth (`AuthService` email/password → `local_auth_session`)
- Profiles, weight history, BMI, charts, theme, CSV export
- Demo seed (Rahul / Priya) after demo sign-in

**What needs real Firebase**

- Google Sign-In
- Cloud Auth persistence across devices
- Firestore sync / queue flush to the cloud

Full setup: [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)

## Firestore and security rules

Owner-scoped paths (ready for when Firebase is configured):

```
users/{userId}
  profiles/{profileId}
    weightHistory/{entryId}
```

`firestore.rules` allows read/write only when `request.auth.uid == userId`.

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

## Local storage (Hive)

Boxes (`AppConstants`):

- `profiles_box`
- `history_box`
- `settings_box` (theme, selected profile, local auth session)
- `sync_queue_box` (pending uploads while offline or when remote fails)

Initialized in `main.dart` before `runApp`. Cloud sync uses Firestore only when `kFirebaseConfigured` is true and the device is online.

## Environment

```bash
cp .env.example .env
```

`.env.example` keys:

```env
DEMO_EMAIL=demo@bmitracker.demo
DEMO_PASSWORD=
DEMO_MODE=false
FIREBASE_PROJECT_ID=
FIREBASE_ANDROID_API_KEY=
FIREBASE_IOS_API_KEY=
FIREBASE_ANDROID_APP_ID=
FIREBASE_IOS_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_STORAGE_BUCKET=
```

Leave `DEMO_PASSWORD` blank in the example file. Set a local password only in `.env` (gitignored).

## Demo account

Details: [docs/DEMO_SETUP.md](docs/DEMO_SETUP.md)

1. Copy `.env.example` → `.env`.
2. Set `DEMO_MODE=true`, `DEMO_EMAIL=demo@bmitracker.demo`, `DEMO_PASSWORD=<local password>` (password required for **Try demo account** via `DemoCredentials.isConfigured`).
3. `flutter run` (Firebase optional; local mode is the default in this repo).
4. Sign in or use **Try demo account**.
5. Seed loads **Rahul Sharma** (primary, 175 cm / 72 kg, BMI ≈ 23.51) and **Priya Sharma** (162 cm / 58 kg) with 7-day sample history.

If you later enable Firebase, also create the same Auth user in the console (see DEMO_SETUP).

## Install, run, test, build

```bash
# Dependencies
flutter pub get

# Static analysis
flutter analyze

# All tests
flutter test

# Run (device or emulator)
flutter run

# Browser demo (local Hive mode; Firebase stays off)
flutter run -d chrome

# Prefer Gradle cache on D: if C: disk is tight
# $env:GRADLE_USER_HOME = 'D:\gradle-home'

# Android debug APK (verified)
flutter build apk --debug

# Android release APK (verified on this host)
flutter build apk --release

# Web build (browser recording / static host)
flutter build web
```

Verified APK outputs:

```
build/app/outputs/flutter-apk/app-debug.apk    # ~154 MB
build/app/outputs/flutter-apk/app-release.apk  # ~58 MB (debug-signed for demo)
```

Verified web output:

```
build/web/
```

Web notes: uses bundled `.env.example` (`DEMO_MODE=true`). Export uses browser download via `share_plus`. Firebase remains intentionally disabled (`kFirebaseConfigured = false`).

Brand asset + generated launcher icons:

```
assets/images/app_icon.png
# dart run flutter_launcher_icons
```

iOS (macOS + Xcode):

```bash
flutter build ios --release
```

Ensure `.env` exists for demo mode. Cloud features need a real `firebase_options.dart` from FlutterFire and `kFirebaseConfigured = true`.

## Testing overview

| Area | File |
|------|------|
| BMI + categories + changes | `test/services/bmi_service_test.dart` |
| 7-day stats | `test/services/statistics_test.dart` |
| Demo seed consistency | `test/services/demo_seed_test.dart` |
| CSV export columns / filename | `test/services/export_service_test.dart` |
| Unit conversion | `test/core/unit_converter_test.dart` |
| Form validators | `test/core/input_validators_test.dart` |
| Login / register / profile UI validation | `test/widget/*` |
| BMI card render | `test/widget/dashboard_render_test.dart` |
| Dark theme | `test/widget/dark_mode_test.dart` |

Key unit expectations:

- 72 kg + 175 cm → BMI **23.51**
- 158.73 lbs ≈ 72 kg
- 175 cm ≈ 68.8976 in
- Zero / negative height rejected by validators; service returns BMI `0` for invalid inputs

## Demo video and interview prep

- [docs/ASSIGNMENT_REQUIREMENTS.md](docs/ASSIGNMENT_REQUIREMENTS.md) — requirement → implementation map
- [docs/FINAL_QA_REPORT.md](docs/FINAL_QA_REPORT.md) — environment, APK, Firebase, limitations
- [docs/DEMO_VIDEO_SCRIPT.md](docs/DEMO_VIDEO_SCRIPT.md) — 2–3 minute timed demo script
- [docs/INTERVIEW_NOTES.md](docs/INTERVIEW_NOTES.md) — Q&A tied to this codebase

## Troubleshooting

| Issue | Action |
|-------|--------|
| Firebase init skipped | Expected while placeholders remain; run FlutterFire then set `kFirebaseConfigured = true` |
| Google Sign-In fails / disabled | Needs Firebase + Android SHA / iOS URL scheme |
| Demo button missing | Set `DEMO_MODE=true` and non-empty `DEMO_EMAIL` + `DEMO_PASSWORD` in `.env` |
| Permission-denied Firestore | Only after Firebase is live; deploy `firestore.rules` |
| Tests fail on fonts | Widget tests use plain `ThemeData` where possible; `AppTheme` uses Google Fonts |
| Hive errors on reinstall | Clear app data or reinstall |

## Known limitations

- Google Sign-In and cloud sync need real Firebase config (`flutterfire configure`, `kFirebaseConfigured = true`). This repo ships with placeholders only.
- Local Hive auth and demo mode work without Firebase; they are not a substitute for production Auth.
- Composite Firestore indexes are not pre-declared (empty `firestore.indexes.json`); add when the console requests them.
- Sync queue is best-effort; without Firebase, pending items cannot flush to the cloud.
- BMI categories use adult WHO-style thresholds; not a medical diagnosis tool.
- Release builds can fail if **C:** is nearly full (Gradle JVM crash). Set `GRADLE_USER_HOME` to a drive with free space (e.g. `D:\gradle-home`). Both debug and release APKs were verified on the Phase 3 host.
- Release APK currently uses the debug signing config for local demos; replace with a production keystore before store upload.

## Privacy note

BMI Tracker stores health-related profile and weight history. On device, data lives in Hive. When Firebase is configured, data is scoped to the signed-in user under `users/{uid}/...` (see `firestore.rules`). Do not share demo passwords publicly. This app is for personal tracking and education, not clinical diagnosis. Review Google and Firebase privacy policies when enabling cloud services.

## License

Proprietary. © IV Innovations Private Limited. All rights reserved.
