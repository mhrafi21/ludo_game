# Offline Ludo

A Flutter Ludo game designed to run entirely on-device. Game rules and AI are
plain Dart, and preferences, match history, achievements, and an unfinished
match are stored locally with `shared_preferences`. No network, account,
backend, analytics, or ads are used.
Sound effects and the optional music loop are synthesized locally as PCM audio;
the app downloads no media files and includes no external game assets.

## Requirements

- Flutter 3.27 or later (Dart 3.6 or later)
- Android SDK for Android builds; Xcode on macOS for iOS builds

## Run on Android

```sh
flutter pub get
flutter run
```

The Android and iOS runners are already included. For a local multiplayer
match, open **Local multiplayer**; for a computer opponent, open **Play vs AI**.
Custom names and avatars are available in **New game** and **Local multiplayer**.
Settings, unfinished matches, and results persist on the device.

## Verify

```sh
dart format lib test
flutter analyze
flutter test
```

## Build an Android APK

Install the Android SDK and a supported JDK (17–25), then connect an Android
device or use an emulator and run:

```sh
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.
To sideload it with Android platform tools, run:

```sh
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

The release APK is signed with Flutter's local debug key so it can be installed
for testing; create a private release key before publishing to an app store.
To build for iOS, use macOS with Xcode and run `flutter build ios --release`.

## Game play

- Play two, three, or four players, with any mix of at least one human and AI.
- Choose Easy (random legal move), Medium (captures and progress), or Hard
  (weighted progress, captures, safe squares, and opponent-threat avoidance).
- A six leaves base. Exact rolls are required for home; safe cells cannot be
  captured. Rolling six, capturing, or reaching home grants another turn.
- The optional three-sixes rule forfeits the third six and ends that turn.
- The board saves after rolls and moves. Statistics and preferences are local.
# ludo_game
