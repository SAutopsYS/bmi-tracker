# IV Innovations assignment requirements map

BMI Tracker (`bmi_tracker` / `com.ivinnovations.bmi_tracker`).  
**Repo Firebase state:** `kFirebaseConfigured = false` in `lib/firebase_options.dart` (placeholders).  
`main.dart` skips `Firebase.initializeApp` when `isFirebaseReady` is false.  
**Phase 4:** Firebase CLI + FlutterFire installed; **interactive `firebase login` still required.** No cloud Auth/Firestore/Google Sign-In verification yet.  
**Never claim production Firebase / Google Sign-In / live Firestore verified in this checkout.**

Status values used below:

| Status | Meaning |
|--------|---------|
| Implemented (local mode verified) | Works with Hive / local auth without Firebase credentials |
| Implemented (Firebase config required) | Code present; needs login + project + `flutterfire configure` + `kFirebaseConfigured = true` (+ SHA / URL schemes) |
| Configured but not manually verified | Credentials installed; device smoke test not completed |
| Manually verified | End-to-end test completed successfully |

---

## Mandatory requirements

| Requirement | Implementation | Screen/File | Status |
|-------------|--------------|-------------|--------|
| Google Sign-In | `AuthService.signInWithGoogle` + login button; throws `operation-not-allowed` when Firebase off | `login_screen.dart`, `auth_service.dart` | Implemented (Firebase config required) |
| Email / password register | Name, email, password, confirm; `AuthRepository.register` → Hive local session when Firebase off | `register_screen.dart`, `auth_service.dart` | Implemented (local mode verified) |
| Email / password login | Email + password; local deterministic `local-{hash}` user when Firebase off | `login_screen.dart`, `auth_service.dart` | Implemented (local mode verified) |
| Password reset | Forgot-password UI; `sendPasswordResetEmail` when Firebase on; local path validates email then no-ops (no mail) | `forgot_password_screen.dart`, `auth_service.dart` | Implemented (Firebase config required) |
| Auth state routing | Splash → home / login / profile-setup via `go_router` redirects | `splash_screen.dart`, `app_router.dart` | Implemented (local mode verified) |
| User details / profile setup form | Name, weight, height, units, gender, DOB | `profile_setup_screen.dart`, `profile_form_screen.dart` | Implemented (local mode verified) |
| Weight units KG / LBS | `WeightUnit` + `UnitSelector` / `UnitConverter` | `unit_selector.dart`, `unit_converter.dart` | Implemented (local mode verified) |
| Height units CM / Inches | `HeightUnit` + converters (`inchToMeter` 0.0254, `lbToKg` 0.45359237) | `unit_converter.dart`, `app_constants.dart` | Implemented (local mode verified) |
| Input validation | Name, email, password, confirm, weight, height, DOB ranges | `input_validators.dart`, form screens | Implemented (local mode verified) |
| BMI calculation | `BMI = kg / m²` in `BMICalculatorService` (72 kg / 175 cm → 23.51) | `bmi_service.dart` | Implemented (local mode verified) |
| BMI categories (adult WHO-style) | Underweight / Normal Weight / Overweight / Obese via `BmiThresholds.adult` | `bmi_thresholds.dart`, `bmi_card.dart` | Implemented (local mode verified) |
| Professional dashboard | Greeting, avatar, BMI card/gauge, stats, chart, recent history, switcher | `dashboard_screen.dart`, dashboard widgets | Implemented (local mode verified) |
| Update weight | Measurement sheet → `HealthRepository.logWeight` → BMI + history | `update_measurement_sheet.dart`, `health_repository.dart` | Implemented (local mode verified) |
| Update height | Same sheet path; recalculates BMI from current weight | `dashboard_screen.dart`, `profile_repository.dart` | Implemented (local mode verified) |
| Settings access | Theme, connection/local mode, export, account, about | `settings_screen.dart` | Implemented (local mode verified) |
| Weight history list | Date, weight, BMI delta, newest first, empty state | `history_screen.dart` | Implemented (local mode verified) |
| Seven-day weight graph | `WeightTrendChart` (fl_chart), last 7 days | `weight_trend_chart.dart`, `history_screen.dart` / dashboard | Implemented (local mode verified) |
| Seven-day statistics | Avg / min / max / weight & BMI change | `bmi_service.dart` (`sevenDayStatistics`), `week_stats_card.dart` | Implemented (local mode verified) |
| Multi-user profiles | Add / edit / delete (confirm) / switch; scoped by `userId` + `profileId` | `profiles_screen.dart`, `profile_switcher.dart`, repositories | Implemented (local mode verified) |
| Profile avatars | `ProfileAvatar` on dashboard / profiles | `profile_avatar.dart` | Implemented (local mode verified) |
| Local storage (Hive) | `profiles_box`, `history_box`, `settings_box`, `sync_queue_box` | `local_storage_service.dart`, `main.dart` | Implemented (local mode verified) |
| Firestore data model + rules | Owner paths `users/{uid}/profiles/{id}/weightHistory/{id}` | `firestore_service.dart`, `firestore.rules` | Implemented (Firebase config required) |
| Splash screen | Logo/name/tagline + auth check | `splash_screen.dart` | Implemented (local mode verified) |

---

## Bonus / enhancement requirements

| Requirement | Implementation | Screen/File | Status |
|-------------|--------------|-------------|--------|
| Auth persistence (device) | Hive `local_auth_session` restore when Firebase off; Firebase Auth when configured | `auth_service.dart`, `local_storage_service.dart` | Implemented (local mode verified) |
| Auth persistence (cloud / cross-device) | Firebase Auth session | `auth_service.dart`, `firebase_options.dart` | Implemented (Firebase config required) |
| Charts (fl_chart) | 7-day weight trend line chart | `weight_trend_chart.dart` | Implemented (local mode verified) |
| Error handling | `AppFailure` / `FailureMapper`, `ErrorView`, snackbars; no raw Firebase strings to users | `app_failure.dart`, `error_view.dart` | Implemented (local mode verified) |
| Dark mode | Light / Dark / System in Hive `settings_box` | `theme_provider.dart`, `settings_screen.dart`, `app_theme.dart` | Implemented (local mode verified) |
| CSV export + share | `ExportService` from Settings / Export route / dashboard action | `export_service.dart`, `export_screen.dart`, `settings_screen.dart` | Implemented (local mode verified) |
| Offline viewing | Hive cache + `OfflineBanner` / status banner | `connectivity_service.dart`, `offline_banner.dart`, `status_banner.dart` | Implemented (local mode verified) |
| Sync when online | `sync_queue_box` flush via `HealthRepository` when Firebase ready + online | `health_repository.dart`, `firestore_service.dart` | Implemented (Firebase config required) |
| Demo account + seed | `.env` `DEMO_*`; Rahul / Priya seed; **Try demo account** | `demo_seed_service.dart`, `DEMO_SETUP.md`, login | Implemented (local mode verified) |
| Accessibility | `Semantics` on key controls/cards; 48dp touch targets on theme control | widgets under `lib/widgets/`, forms, settings | Implemented (local mode verified) |
| Unit + widget tests | BMI, stats, converters, validators, login/register/profile, dashboard, dark mode, export, demo seed | `test/` | Implemented (local mode verified) |

---

## Demo seed (assignment numbers)

| Profile | Height | Weight | BMI (approx) | 7-day weights (kg) |
|---------|--------|--------|--------------|--------------------|
| Rahul Sharma (primary) | 175 cm | 72.0 kg | 23.51 | 74.0, 73.6, 73.2, 72.9, 72.6, 72.3, 72.0 |
| Priya Sharma | 162 cm | 58.0 kg | 22.10 | 58.6 → 58.0 (see `DemoSeedService`) |

Source: `lib/services/demo_seed_service.dart`.

---

## Related docs

- Setup: [FIREBASE_SETUP.md](FIREBASE_SETUP.md), [DEMO_SETUP.md](DEMO_SETUP.md)
- QA: [FINAL_QA_REPORT.md](FINAL_QA_REPORT.md)
- Demo / interview: [DEMO_VIDEO_SCRIPT.md](DEMO_VIDEO_SCRIPT.md), [INTERVIEW_NOTES.md](INTERVIEW_NOTES.md)
