# Firebase setup (BMI Tracker)

IV Innovations Private Limited · package `com.ivinnovations.bmi_tracker`

**Phase 4 status (this machine):** Firebase CLI and FlutterFire CLI are installed. **Firebase login is required before any real project can be linked.** Until you complete the steps below, `kFirebaseConfigured` stays **`false`** and the app remains in local Hive demo mode. No fake credentials are used.

---

## Phase 4 blocker (do this first)

### Tools already installed

| Tool | Version / path note |
|------|---------------------|
| Firebase CLI | `15.26.0` (`npm install -g firebase-tools`) |
| FlutterFire CLI | `1.4.1` (add `C:\Users\HP\AppData\Local\Pub\Cache\bin` to PATH if needed) |
| Flutter / Dart | 3.38.5 / 3.10.4 |
| Login state | **No authorized accounts** — `firebase login:list` empty |

### 1. Login (interactive — you must run this)

In PowerShell:

```powershell
$env:PATH = "C:\Windows\System32;C:\Program Files\nodejs;$env:APPDATA\npm;C:\Users\HP\AppData\Local\Pub\Cache\bin;D:\flutter\bin;" + $env:PATH
firebase login
```

Success looks like: browser Google account picker completes, terminal shows you are logged in, then:

```powershell
firebase projects:list
```

lists your projects (or empty if none yet).

### 2. Create Firebase project (Console or CLI)

**Console path**

1. Open [Firebase Console](https://console.firebase.google.com/)
2. **Add project**
3. Project name: `BMI Tracker` (Firebase may generate a project ID like `bmi-tracker-xxxxx` — **copy the real ID**; do not invent one)
4. Analytics optional
5. Finish → note **Project settings → General → Project ID**

**Or CLI (after login):**

```powershell
firebase projects:create
```

Use the project ID Firebase prints. Never guess it.

### 3. Register Android app

1. Project settings (gear) → **Your apps** → **Add app** → Android
2. **Android package name (exact):** `com.ivinnovations.bmi_tracker`
   - Source: `android/app/build.gradle.kts` → `applicationId`
3. App nickname optional: `BMI Tracker Android`
4. **Do not skip SHA** if you want Google Sign-In (see next section)
5. Download **`google-services.json`**
6. Place file at: `android/app/google-services.json`  
   (gitignored in this repo — keep local only if you prefer)

### 4. Add SHA-1 and SHA-256 (required for Google Sign-In)

**Signing today:** release APK uses **debug** signing (`signingConfig = signingConfigs.getByName("debug")` in `android/app/build.gradle.kts`). Demo/release APKs share the debug keystore fingerprints below.

**Measured on this machine** (`%USERPROFILE%\.android\debug.keystore`, alias `androiddebugkey`):

| Fingerprint | Value |
|-------------|--------|
| SHA-1 | `45:4E:E2:F7:49:B8:EB:FF:43:A4:A5:18:6E:79:A0:94:1E:43:EA:D8` |
| SHA-256 | `00:D8:09:A1:7C:73:0A:B1:F2:31:C3:47:97:21:48:18:8C:2C:45:F3:C4:F8:96:B9:75:49:60:69:A0:A9:A4:70` |

**Where to paste in Console**

1. Firebase Console → Project settings → Your apps → Android app `com.ivinnovations.bmi_tracker`
2. **Add fingerprint** → paste SHA-1 → Save
3. **Add fingerprint** → paste SHA-256 → Save
4. Re-download `google-services.json` after adding fingerprints (recommended)

**Later production keystore:** generate a release keystore, run `keytool -list -v` on it, add those SHA values too. Never commit the keystore or passwords.

Re-measure anytime:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### 5. Enable Authentication providers

Firebase Console → **Build** → **Authentication** → **Get started** → **Sign-in method**

1. Enable **Email/Password** → Save
2. Enable **Google** → choose support email → Save

Success: both providers show **Enabled**.

### 6. Create demo Auth user

Firebase Console → Authentication → **Users** → **Add user**

| Field | Value |
|-------|--------|
| Email | `demo@bmitracker.demo` |
| Password | Same value as local `.env` → `DEMO_PASSWORD` (never put the real password in git or docs) |

Also set local `.env`:

```env
DEMO_EMAIL=demo@bmitracker.demo
DEMO_PASSWORD=
DEMO_MODE=true
```

(`.env.example` keeps password empty.)

### 7. Enable Cloud Firestore

1. Console → **Build** → **Firestore Database** → **Create database**
2. Prefer **production mode** (rules will be deployed from repo)
3. Choose a region and enable

### 8. FlutterFire configure (from project root)

After login + Android app registered:

```powershell
cd C:\Users\HP\Downloads\app
$env:PATH = "C:\Windows\System32;C:\Program Files\nodejs;$env:APPDATA\npm;C:\Users\HP\AppData\Local\Pub\Cache\bin;D:\flutter\bin;" + $env:PATH
flutterfire configure --project=PASTE_REAL_PROJECT_ID_HERE
```

Select Android (and iOS only if you have a Mac + real bundle setup).

This regenerates `lib/firebase_options.dart` with real values (no `YOUR_*`).

Then set:

```dart
const bool kFirebaseConfigured = true;
```

in `lib/firebase_options.dart`.

Uncomment Google Services plugin lines:

- `android/settings.gradle.kts` → `id("com.google.gms.google-services") version "4.4.2" apply false`
- `android/app/build.gradle.kts` → `id("com.google.gms.google-services")`

### 9. Deploy security rules

Repo already has owner-only `firestore.rules` and `firebase.json`.

```powershell
cd C:\Users\HP\Downloads\app
firebase use PASTE_REAL_PROJECT_ID_HERE
firebase deploy --only firestore:rules
```

Success: CLI reports rules deployed. Confirm in Console → Firestore → Rules.

### 10. Seed demo data (safe client path)

After demo user exists and Firebase mode is on:

1. Set `.env` `DEMO_MODE=true` + password matching Firebase Auth user
2. `flutter run`
3. Tap **Try demo account** (or email login)
4. App seeds Rahul / Priya locally and best-effort upserts to Firestore via `AuthRepository._seedDemoIfNeeded`

Never use a service account inside the mobile app. Never weaken rules for seeding.

### 11. Verify cloud sync

1. Login as demo user
2. Confirm Firestore Console shows `users/{uid}/profiles/...` and `weightHistory/...`
3. Update weight → new history doc
4. Kill app → relaunch → data still there
5. Switch Rahul ↔ Priya → no data leak
6. Logout → login → session restored

### 12. Google Sign-In verify

1. Logout
2. **Continue with Google**
3. Account picker → success → Firebase user created
4. Logout → login again

If SHA missing, Android Google Sign-In fails — fix fingerprints and re-download `google-services.json`.

---

## iOS (no macOS on this host)

Do **not** claim iOS Firebase configured here.

When a Mac is available:

1. Register iOS app with bundle ID matching Xcode (`com.ivinnovations.bmitracker` in placeholders — confirm in `ios/Runner`)
2. Download `GoogleService-Info.plist` → `ios/Runner/`
3. Add URL scheme = `REVERSED_CLIENT_ID` from that plist
4. Re-run `flutterfire configure` including iOS
5. `flutter build ios`

---

## Architecture reminder (do not replace)

- `isFirebaseReady = kFirebaseConfigured && hasRealFirebaseOptions`
- `main.dart` skips `Firebase.initializeApp` when not ready → local Hive mode
- Auth: `AuthService` / `AuthRepository`
- Cloud: `FirestoreService` paths `users/{uid}/profiles/{id}/weightHistory/{id}`
- Status UI: `StatusBanner` shows **Local demo mode** until Firebase ready; offline/syncing when ready
- Never set `kFirebaseConfigured = true` with placeholder options

---

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| `No authorized accounts` | `firebase login` |
| Placeholders in `firebase_options.dart` | `flutterfire configure` then set `kFirebaseConfigured = true` |
| Google Sign-In fails on Android | Add SHA-1/256; re-download `google-services.json` |
| Permission denied Firestore | Deploy `firestore.rules`; confirm signed in |
| Demo button missing | `DEMO_MODE=true` + non-empty `DEMO_PASSWORD` in `.env` |
| Google Services plugin missing | Uncomment plugin in `settings.gradle.kts` + `app/build.gradle.kts` |

## Security

- Never invent API keys, OAuth IDs, or SHA values
- Never commit `.env`, keystores, or service accounts
- `google-services.json` / `GoogleService-Info.plist` are gitignored in this repo
- Keep Firestore rules deny-by-default + owner-only (current `firestore.rules`)
