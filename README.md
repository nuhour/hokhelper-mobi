# hokhelper-mobi

Flutter Android-first mobile app for HOK Helper.

## Backend

The app calls the existing Django backend from `okhok/hok` through `/hokx/` APIs.

Default local API settings:

```bash
HOK_API_BASE_URL=https://localhost:8000
HOK_API_PREFIX=/hokx
```

For Android emulator access to a local host backend:

```bash
flutter run --dart-define=HOK_API_BASE_URL=https://10.0.2.2:8000
```

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=HOK_API_BASE_URL=https://10.0.2.2:8000
flutter build apk --debug
```

## Product Plan

See `docs/superpowers/specs/2026-07-03-hokhelper-mobile-mvp-design.md`.
