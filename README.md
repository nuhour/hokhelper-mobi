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
# From the okhok backend repository:
cd hok/www
python manage.py runserver 0.0.0.0:8000

# From this mobile repository:
flutter run --dart-define=HOK_API_BASE_URL=http://10.0.2.2:8000
```

Debug Android builds allow cleartext traffic to `10.0.2.2`, `localhost`, and
`127.0.0.1`. Release builds should use an HTTPS production backend.

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=HOK_API_BASE_URL=http://10.0.2.2:8000
flutter build apk --debug
```

## Product Plan

See `docs/superpowers/specs/2026-07-03-hokhelper-mobile-mvp-design.md`.
