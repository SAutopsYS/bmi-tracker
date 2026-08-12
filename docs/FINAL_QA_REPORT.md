# Final QA report — BMI Tracker

IV Innovations Private Limited · package `bmi_tracker`  
**Phase 5 checkpoint:** 2026-08-13 — Flutter Web + **Try Demo** login ready (Firebase still intentionally off).

---

## Environment

| Item | Value |
|------|--------|
| Flutter | 3.38.5 |
| Dart | 3.10.4 |
| Platforms | Android + Web (`web/` present) |
| applicationId | `com.ivinnovations.bmi_tracker` |
| App label / web title | BMI Tracker |
| `kFirebaseConfigured` | **false** (unchanged) |

---

## Analyzer / Tests

| Check | Result |
|-------|--------|
| `flutter analyze` | **No issues found** |
| `flutter test` | **47 passed** |

---

## Builds

| Artifact | Status | Notes |
|----------|--------|-------|
| Web | **Success** | `flutter build web` → `build/web` |
| Chrome run | **Success** | `flutter run -d chrome`; Hive boxes opened; local mode log confirmed |
| Android debug APK | **Verified** | `build/app/outputs/flutter-apk/app-debug.apk` |
| Android release APK | Verified in Phase 3 | ~58.42 MB; debug-signed for demo |

---

## Demo / Firebase

| Area | Status |
|------|--------|
| Local Hive demo | Working |
| Demo seed Rahul / Priya | Working |
| Web env | Loads `.env.example` (`DEMO_MODE=true`) |
| Firebase / Google Sign-In / cloud sync | **Intentionally disabled** — not configured, not claimed |

---

## Web-specific notes

- Export uses `XFile.fromData` (no `dart:io`) so CSV download works in browser.
- Profile avatars use conditional local-file helpers (initials on Web).
- Wide desktop view centers a ~480px mobile column (recording-friendly).
- Share/download UX depends on browser share/download support.

---

## Submission readiness

| Mode | Ready? |
|------|--------|
| Android submission (local demo) | **Yes** |
| Browser demo recording | **Yes** |
| Firebase cloud mode | **Intentionally pending** |

Recording script: [DEMO_VIDEO_SCRIPT.md](DEMO_VIDEO_SCRIPT.md).
