# Interview notes (from this repo)

Answers map to real classes/files in `bmi_tracker`. Skip textbook fluff.

---

### Why Flutter?

Cross-platform UI from one Dart codebase. This app is Material 3 (`AppTheme`), `go_router` navigation, and Android package `com.ivinnovations.bmi_tracker`. SDK constraint in `pubspec.yaml`: `>=3.5.0 <4.0.0`.

### Why Firebase?

Target stack for cloud auth (`firebase_auth`, `google_sign_in`) and owner-scoped data (`cloud_firestore`). In **this checkout**, Firebase is still placeholders: `kFirebaseConfigured = false` in `lib/firebase_options.dart`. `main.dart` skips `Firebase.initializeApp` when `isFirebaseReady` is false. Cloud paths are ready in `FirestoreService`; they are not live until FlutterFire + flag + real options.

### Why Riverpod?

`flutter_riverpod` wires services → repositories → UI. Providers live in `lib/providers/` (`auth_provider`, `profile_provider`, `health_provider`, `theme_provider`, `connectivity_provider`) and DI roots in `providers.dart`. `main.dart` overrides `localStorageServiceProvider` and `connectivityServiceProvider` with real instances.

### Why Hive?

Offline-first cache without a native SQL layer. `LocalStorageService` opens boxes from `AppConstants`: `profiles_box`, `history_box`, `settings_box`, `sync_queue_box`. Local auth session JSON is stored in settings as `local_auth_session`.

### Why repository pattern?

UI never talks to Firebase/Hive directly for domain writes.

| Repository | Role |
|------------|------|
| `AuthRepository` | Sign-in/register/demo, user doc best-effort, demo seed |
| `ProfileRepository` | Profiles CRUD, BMI on create/update, sync enqueue |
| `HealthRepository` | Weight log, history fetch/merge, 7-day stats, CSV export, queue flush |

Services underneath: `AuthService`, `FirestoreService`, `LocalStorageService`, `BMICalculatorService`, `DemoSeedService`, `ExportService`, `ConnectivityService`.

---

### How is BMI calculated?

`BMICalculatorService` in `lib/services/bmi_service.dart`:

```
BMI = weightKg / (heightMeters²)
```

Rounded to 2 decimals. `calculateBMIFromCm` uses `UnitConverter.cmToMeters`. Invalid weight/height ≤ 0 → `0`.

**Interview number:** 72 kg, 175 cm → **23.51** (asserted in `test/services/bmi_service_test.dart`). Category via `BmiThresholds.adult` in `bmi_thresholds.dart`: underweight &lt; 18.5, normal &lt; 25, overweight &lt; 30, else obese. Not clinical diagnosis.

---

### Unit conversion constants

`AppConstants` + `UnitConverter`:

| Constant | Value |
|----------|--------|
| `lbToKg` | `0.45359237` |
| `kgToLb` | `1 / lbToKg` |
| `inchToMeter` | `0.0254` |
| `cmToMeter` | `0.01` |
| `inchToCm` | `2.54` |
| `cmToInch` | `1 / inchToCm` |

Tests: 158.73 lbs ≈ 72 kg; 175 cm ≈ 68.8976 in (`unit_converter_test.dart` / BMI service tests).

---

### Auth persistence: local vs Firebase

Gate: `isFirebaseReady` (`kFirebaseConfigured && hasRealFirebaseOptions` in `firebase_options.dart`). Runtime init in `main.dart` checks **`isFirebaseReady`** (not the flag alone).

| Mode | Behavior |
|------|----------|
| `isFirebaseReady == false` (current: flag false + placeholders) | `AuthService` uses Hive session stream; email/password creates deterministic `local-{emailHash}` user; password ≥ 8 chars |
| `isFirebaseReady == true` | `FirebaseAuth` + optional `GoogleSignIn` |

Google Sign-In throws `operation-not-allowed` when Firebase is off. Forgot-password is a no-op locally (returns after email check). Session restore: `_readLocalSession()` on construct.

---

### Multi-profile isolation

- Models: `ProfileModel.userId`, `WeightHistoryModel.profileId` + `userId`.
- Hive reads filter: `getProfiles(userId:)`, `getHistory(userId:, profileId:)`.
- Selected profile id in settings: `selected_profile_id`.
- UI: `ProfileSwitcher` + `profilesProvider` / `selectedProfileProvider`.
- Demo: Rahul (`isPrimary: true`) and Priya, different ids, separate 7-day histories (`DemoSeedService`).

---

### Offline / Hive + sync queue (honest)

**Implemented:**

- Offline-first writes: local upsert first (`HealthRepository`, `ProfileRepository`).
- `SyncQueueItem` in `sync_queue_box` (`collection`: `profiles` \| `weightHistory`, `action`: `upsert` \| `delete`).
- `ConnectivityService` + `OfflineBanner`; Settings shows `pendingSyncCountProvider`.
- When online and Firebase available, `HealthRepository._flushHistoryQueue` pushes queued weight history and removes items.

**Limits today:**

- With `kFirebaseConfigured == false`, `FirestoreService.isAvailable` is false; remote calls throw `StorageException` (`firebase-not-configured`). Queue can grow; cloud flush cannot succeed until Firebase is configured.
- Profile queue enqueue exists; history flush is the explicit flush path in `HealthRepository`. Sync is best-effort, not a full conflict-resolution engine.
- Sign-out calls `clearUserData()` (profiles, history, sync queue, selected profile, local session).

---

### Firestore security rules path

`firestore.rules`:

```
users/{userId}
  profiles/{profileId}
    weightHistory/{entryId}
```

`allow read, write` only if `request.auth.uid == userId` (`isOwner`). Matches `FirestoreService` collection helpers. Indexes file ships empty; add composites when console asks.

---

### Charts

`WeightTrendChart` (`lib/widgets/charts/weight_trend_chart.dart`) uses **fl_chart** (`LineChart` / `FlSpot`). Last 7 days via `AppDateUtils.lastNDays(7)`, one point per day (latest entry that day), display unit from profile `WeightUnit`.

---

### Testing approach

`flutter_test` + `mocktail`. No Firebase/Hive required for most tests (`test/helpers/test_app.dart` + `ProviderScope`).

| Area | File |
|------|------|
| BMI 23.51, categories, changes | `test/services/bmi_service_test.dart` |
| 7-day stats | `test/services/statistics_test.dart` |
| Conversions | `test/core/unit_converter_test.dart` |
| Validators | `test/core/input_validators_test.dart` |
| Login/register/profile forms | `test/widget/*` |
| `BmiCard` render | `test/widget/dashboard_render_test.dart` |
| Dark theme | `test/widget/dark_mode_test.dart` |

---

### Demo mode

- `.env`: `DEMO_MODE`, `DEMO_EMAIL`, `DEMO_PASSWORD` (see `.env.example`).
- `DemoCredentials.isConfigured` requires mode + non-empty email **and** password (login prefills / **Try demo account**).
- `AuthService.signInDemo`: local path works **without** password; Firebase path requires `DEMO_PASSWORD`.
- `AuthRepository.signInDemo` → `_seedDemoIfNeeded` if no local profiles.
- `DemoSeedService`: **Rahul Sharma** 175 cm / 72 kg (weights 74.0, 73.6, 73.2, 72.9, 72.6, 72.3, 72.0); **Priya Sharma** 162 cm / 58 kg.
- `BmiTrackerApp` shows DEMO corner banner when `DEMO_MODE` is true/1.

---

### How architecture scales

1. Keep screens thin; add methods on repositories, not Firestore calls in widgets.
2. Swap `FirestoreService` / `AuthService` behind the same interfaces when adding backends.
3. Multi-profile already keyed by `userId`/`profileId`; new metrics attach under the same tree.
4. Sync queue can grow action types without changing UI providers.
5. Turn on cloud by regenerating `firebase_options.dart`, setting `kFirebaseConfigured = true`, deploying `firestore.rules`. Local Hive path remains the cache layer.
