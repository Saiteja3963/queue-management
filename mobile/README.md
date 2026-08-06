# QueueFlow Mobile (Flutter)

Cross-platform mobile app for **Android** and **iOS**, mirroring the QueueFlow web experience against the same FastAPI backend.

## Features

- Sign in / register
- Organization & queue management
- Staff console (call next, serve, complete, skip, cancel)
- Live queue insights
- Public customer join + live ticket tracking

## Prerequisites

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.32+)
2. Backend running (from repo root):

```bash
cd backend
pip3 install -r requirements.txt
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Use `--host 0.0.0.0` so physical devices on the same network can reach the API.

## Run

```bash
cd mobile
flutter pub get

# iOS Simulator (defaults to http://127.0.0.1:8000)
flutter run -d ios

# Android Emulator (defaults to http://10.0.2.2:8000)
flutter run -d android

# Physical device — point at your machine LAN IP
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

## Demo credentials

- Email: `admin@demo.com`
- Password: `password123`
- Demo public queue: City Care → General Practice (home screen shortcut)

## Project layout

```
mobile/lib/
  config.dart           # API base URL resolution
  theme.dart            # Shared teal/slate theme
  models/               # DTOs
  services/api_service.dart
  providers/auth_provider.dart
  screens/              # Home, auth, dashboard, org, admin, insights, public, ticket
  widgets/              # Status badges, stat cards
```

## Notes

- Android cleartext HTTP is enabled for local development (`usesCleartextTraffic`).
- iOS ATS allows local networking for the same reason.
- For production, serve the API over HTTPS and remove cleartext / ATS exceptions.
