# CFBlog Flutter Admin

This repository now uses Flutter as the primary application codebase.

The current app is a Flutter rebuild of the original CFBlog admin client, with a refreshed UI and responsive admin workflows for dashboard, posts, pages, media, comments, taxonomies, links, moments, users, and settings.

## Project Layout

- `lib/`: Flutter application source
- `test/`: widget and screen tests
- `web/`, `android/`, `ios/`: Flutter platform targets
- `legacy_expo/`: archived Expo/React Native implementation kept for reference

## Requirements

- Flutter SDK 3.38.3+
- Dart SDK 3.10.1+

## Local Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Run on a connected device or emulator:

```bash
flutter run
```

## Build

Web:

```bash
flutter build web --release
```

Android:

```bash
flutter build apk --release
```

iOS:

```bash
flutter build ios --release --no-codesign
```

## Legacy Expo App

The previous Expo/React Native project has been archived under `legacy_expo/`. It is no longer the primary app target, but the code remains available as a migration reference.
