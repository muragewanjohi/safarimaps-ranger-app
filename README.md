# SafariMap GameWarden (Flutter)

Flutter port of the SafariMap GameWarden ranger app, converted from the React Native/Expo app at `apps/safarimaps-ranger`.

## Stack

- **Flutter** with Material 3
- **Bloc/Cubit** for state management
- **go_router** for navigation and auth guards
- **get_it** for dependency injection
- **supabase_flutter** for auth, database, and storage
- **google_maps_flutter** for maps
- **geolocator** / **permission_handler** for location

## Setup

1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.12+)

2. Copy config templates and fill in credentials:

```bash
cp env.json.example env.json
cp android/secrets.properties.example android/secrets.properties
cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig
```

3. Edit **`env.json`** (Flutter / Dart compile-time config):

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key",
  "USE_MOCK_DATA": "false"
}
```

4. Add your **Android Maps** key to `android/secrets.properties`:

```properties
GOOGLE_MAPS_ANDROID_API_KEY=your_android_maps_key
```

5. Edit **`ios/Flutter/Secrets.xcconfig`** for iOS Maps:

```xcconfig
GOOGLE_MAPS_IOS_API_KEY=your_ios_maps_key
```

6. Install dependencies and run:

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

In VS Code / Cursor, use the **SafariMap GameWarden** launch configuration (loads `env.json` automatically).

## Environment variable layout

| Variable | Where it lives | Used by |
|----------|----------------|---------|
| `SUPABASE_URL` | `env.json` | Dart (`--dart-define-from-file`) |
| `SUPABASE_ANON_KEY` | `env.json` | Dart |
| `USE_MOCK_DATA` | `env.json` | Dart |
| `GOOGLE_MAPS_ANDROID_API_KEY` | `android/secrets.properties` | Android manifest (Gradle) |
| `GOOGLE_MAPS_IOS_API_KEY` | `ios/Flutter/Secrets.xcconfig` | iOS `Info.plist` |

**Never commit** `env.json`, `android/secrets.properties`, or `ios/Flutter/Secrets.xcconfig`. Templates (`*.example`) are safe to commit.

### Why this split?

- **Dart config** uses Flutter's `--dart-define-from-file` — compile-time, not bundled as a loose asset.
- **Maps keys** are injected by native build tools (Gradle / Xcode), which is what `google_maps_flutter` expects.
- Secrets stay out of git and out of the Flutter asset bundle.

## Android Maps API Key

1. In [Google Cloud Console](https://console.cloud.google.com/):
   - Enable **Maps SDK for Android**
   - Create an API key restricted to Android apps:
     - Package name: `com.safarimap.gamewarden`
     - SHA-1 (debug): `B3:3D:4C:4D:57:B8:F8:16:82:8D:15:73:94:E0:54:7A:5D:7C:83:A5`

2. Add the key to `android/secrets.properties`

3. Rebuild (manifest changes require a full rebuild):

```bash
flutter clean && flutter run --dart-define-from-file=env.json
```

## iOS Maps API Key

1. Enable **Maps SDK for iOS** in Google Cloud Console
2. Set `GOOGLE_MAPS_IOS_API_KEY` in `ios/Flutter/Secrets.xcconfig`
3. Rebuild the iOS app

## Release signing (Google Play)

The existing React Native app on Play Store was built with **Expo EAS**. Flutter must sign releases with the **same upload keystore** so Google accepts updates to `com.safarimap.gamewarden`.

### Step A — Download the upload keystore from EAS

From the React Native app directory:

```bash
cd apps/safarimaps-ranger
npx eas-cli login
npx eas-cli credentials -p android
```

In the interactive menu:

1. Select **production** (or the profile used for Play Store uploads)
2. Choose **Keystore: Manage everything needed to build your project**
3. Choose **Download existing keystore**

Save the downloaded `.jks` file to:

```
apps/ranger/android/upload-keystore.jks
```

Note the **key alias**, **keystore password**, and **key password** shown in EAS (or set when the keystore was created).

Alternative: [Expo dashboard](https://expo.dev) → your project → **Credentials** → Android → download keystore.

### Step B — Configure Flutter signing

```bash
cd apps/ranger
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=../upload-keystore.jks
```

`storeFile` is relative to `android/app/`. The keystore lives at `android/upload-keystore.jks`.

These files are gitignored: `key.properties`, `upload-keystore.jks`, `*.jks`.

### Step C — Verify release signing

```bash
cd apps/ranger
flutter build appbundle --dart-define-from-file=env.json
```

If signing is configured correctly, Gradle will **not** warn about missing `key.properties`.

Check the certificate on the bundle:

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

### Step D — Add release SHA-1 to Google Maps

Get the upload certificate fingerprint:

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias YOUR_KEY_ALIAS
```

In [Google Cloud Console](https://console.cloud.google.com/) → **Credentials** → your Android Maps key, add:

- Package: `com.safarimap.gamewarden`
- SHA-1: from the upload keystore above
- SHA-1: **App signing key certificate** from Play Console → **Setup** → **App signing** (Google re-signs the app for users)

### Play Store version codes

`pubspec.yaml` uses `version: 1.0.5+6` — the number after `+` is `versionCode`. Each Play upload must increase it (previous RN build was `5`).

## CI / production builds

```bash
flutter build appbundle --dart-define-from-file=env.json
flutter build ios --dart-define-from-file=env.json
```

Pass Maps keys via your CI secret store into `android/secrets.properties` and `ios/Flutter/Secrets.xcconfig` at build time.

## Project Structure

```
lib/
├── core/           # config, theme, router, DI
├── data/           # models, datasources, repositories, services
└── presentation/   # blocs, screens, shared widgets
```

## Screens

| Route | Screen |
|-------|--------|
| `/login` | Login |
| `/signup` | Sign up |
| `/forgot-password` | Password reset |
| `/` | Home dashboard |
| `/map` | Map / explore |
| `/reports` | Incident reports |
| `/profile` | Profile & settings |
| `/add-report` | New incident report |
| `/add-location` | Add location/POI |
| `/park` | Park admin |

## Bundle ID

- Android/iOS: `com.safarimap.gamewarden`
- Deep link scheme: `ranger://`

## Testing

```bash
flutter test
flutter analyze
```

## Notes

- Offline mode, push notifications, and auto-sync toggles are UI placeholders (matching the RN app).
- Park POI map data is consolidated in `assets/data/park_pois.json` for Home and Map screens.
