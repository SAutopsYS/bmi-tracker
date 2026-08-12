# Demo account and seed data

BMI Tracker can show a controlled demo experience for reviews and training. Demo credentials live only in `.env` (never hardcode passwords in Dart UI).

**This repo default:** Firebase options are placeholders (`kFirebaseConfigured = false`). Demo works in **local Hive mode** without a Firebase project. Cloud demo user creation is optional and only needed after FlutterFire configure.

## Demo identity

| Field | Value |
|-------|--------|
| Email | `demo@bmitracker.demo` |
| Password | Set in `.env` as `DEMO_PASSWORD` (leave blank in `.env.example`) |
| Mode flag | `DEMO_MODE=true` |

`DemoCredentials.isConfigured` (`lib/providers/providers.dart`) is true only when:

1. `DEMO_MODE` is `true` or `1`
2. `DEMO_EMAIL` is non-empty
3. `DEMO_PASSWORD` is non-empty

When configured, the login screen prefills fields and offers **Try demo account**. A DEMO banner appears on `BmiTrackerApp` when mode is on.

Notes:

- UI demo button requires `DEMO_PASSWORD` even in local mode.
- `AuthService.signInDemo` without Firebase can create a local demo session without checking password; prefer setting password so the login affordance matches.
- With Firebase on, demo sign-in calls `signInWithEmail` and **requires** `DEMO_PASSWORD`.

## Local `.env` (enough for this repo)

```bash
cp .env.example .env
```

```env
DEMO_EMAIL=demo@bmitracker.demo
DEMO_PASSWORD=your-local-demo-password
DEMO_MODE=true
```

Then:

```bash
flutter pub get
flutter run
```

## Cloud demo path (after Firebase login)

Only after [FIREBASE_SETUP.md](FIREBASE_SETUP.md). Do not invent credentials.

1. Copy `.env.example` → `.env`
2. Set `DEMO_MODE=true`, `DEMO_EMAIL=demo@bmitracker.demo`, `DEMO_PASSWORD=<local only>`
3. Complete Firebase project + Android app + SHA + FlutterFire; set `kFirebaseConfigured = true`
4. Console → Authentication → Users → **Add user** → email `demo@bmitracker.demo`, password = `.env` `DEMO_PASSWORD`
5. Enable Firestore; deploy `firestore.rules`
6. `flutter run`
7. Login with **Try demo account** (or email/password)
8. Seed creates Rahul + Priya (local + best-effort Firestore upsert)
9. Dashboard BMI ≈ 23.51 (Rahul)
10. Update weight → history + BMI update
11. Graph + 7-day statistics
12. Switch Rahul → Priya → back
13. Settings → dark mode
14. Export selected profile CSV
15. Logout → login again → data persists when Firebase mode is on

## Seed profiles (Rahul / Priya)

On demo sign-in, `AuthRepository.signInDemo` → `DemoSeedService.buildSeedData` if the user has no local profiles yet.

| Profile | Role | Height | Weight | History |
|---------|------|--------|--------|---------|
| Rahul Sharma | Primary | 175 cm | 72 kg | Exact 7-day kg: **74.0, 73.6, 73.2, 72.9, 72.6, 72.3, 72.0**; BMI ≈ 23.51 |
| Priya Sharma | Secondary | 162 cm | 58 kg | 7 days: 58.6, 58.5, 58.3, 58.2, 58.1, 58.0, 58.0; BMI ≈ 22.10 |

Source constants: `DemoSeedService.rahulDailyWeightsKg` / `priyaDailyWeightsKg`.

Seed writes Hive first (`saveProfiles` / `saveHistory`), selects Rahul, then best-effort Firestore upsert when Firebase is available. Re-seed skips if any profile already exists for that `userId`.

## Manual verification checklist

1. `flutter run` with `.env` as above.
2. Open login → **Try demo account** (or sign in with demo email/password).
3. Confirm DEMO banner.
4. Dashboard shows Rahul (primary) with BMI near 23.5.
5. Switch to Priya via `ProfileSwitcher`.
6. Open History: multi-day weight entries (7 days).
7. Settings: theme toggle, export CSV for selected profile.
8. Airplane mode: offline banner; local Hive still serves cached data. Cloud flush needs Firebase configured.

## Resetting demo data

**Local demo mode only** (`!isFirebaseReady`): Settings → **Reset local demo data** restores Rahul/Priya seed. Never deletes Firebase Auth or cloud docs.

**When Firebase is ready:** that reset button is hidden. Do not use admin credentials in the app.

- Sign out clears local cache for that session.
- Cloud: delete only your demo user's `users/{uid}` tree in Console if you must re-seed; recreate Auth user if password changes.

## Security

- Demo password is for staging/demo only.
- Prefer a separate Firebase project from production when cloud is enabled.
- Keep `DEMO_MODE=false` for release builds unless the build is explicitly a demo APK.

## Related

- Timed recording script: [DEMO_VIDEO_SCRIPT.md](DEMO_VIDEO_SCRIPT.md)
- Interview talking points: [INTERVIEW_NOTES.md](INTERVIEW_NOTES.md)
