# Muzee

Muzee 2.x is built on the NeoTuber codebase (Musify-based, GPL-3.0, see
LICENSE) with Muzee's own identity: app ID `up.nexstudio.muzee`, name, icons,
Firebase project, AdMob units and the `remove_ad` purchase. The games of 1.x
are gone.

Playback lives in `packages/tuber_playback`, shared with NeoTuber.

## Muzee-only features

- **Firebase** (`lib/services/firebase/`): Remote Config, push notifications
  and Analytics.
  - Remote Config keys, as in 1.x: `android_version`, `force_update`,
    `update_url_android` (update prompt) and `login_google` (shows the
    Account section).
  - A push whose data has a `songId` plays that song when tapped.
  - Analytics events: `openApp`, screen views, `search_input`.
- **Google sign-in and cloud backup**
  (`google_account_service.dart`, `cloud_backup_service.dart`).
  - Uses the same OAuth client and stored tokens as 1.x, so people stay
    signed in.
  - The library backs up to Firestore at `users/{email}/backup_v2/{key}`.
- **Intro**: the "Muzee" wordmark on first launch (`screens/intro_page.dart`).

## Upgrading from 1.x

On the first launch after the update, `migrateMuzee1IfNeeded()`
(`lib/services/legacy/`) moves the 1.x data into 2.x:

- **From the Isar database:** liked songs, the user's playlists, imported
  YouTube playlists, recently played (with play counts) and search history.
- **From SharedPreferences:** the "ads removed" purchase (it becomes
  lifetime Premium), language and country.

Followed artists have no 2.x equivalent. The old database is left in place.
`test/services/legacy_migration_test.dart` covers the conversion against a
real 1.x database.

## Build

```sh
fvm flutter pub get
fvm flutter test
fvm flutter build appbundle --release --dart-define=USE_TEST_ADS=false
```

- **Version:** `version` in pubspec.yaml (the app reads it at runtime, see
  `AppInfo`). The versionCode must stay above 1.x's last one, 20250804.
- **Update prompt:** Remote Config `android_version` (latest versionName),
  `force_update`, `update_url_android`; see `RemoteConfigService`.
- **Release signing:** `android/key.properties` (`storeFile`, `keyAlias`,
  `keyPassword`, `storePassword`), with `storeFile` defaulting to
  `android/app/muzee_keystore`. Without it, release builds are signed with
  the debug key, as 1.x's build did.
- **Ads:** debug builds use Google's test ads. Muzee has no rewarded unit
  yet, so the "watch an ad for ad-free time" offer is hidden in release
  (`AdUnitIds._rewardedProd`).
- **Firestore rules:** cloud backup needs read and write on
  `users/{email}/backup_v2/*`.
