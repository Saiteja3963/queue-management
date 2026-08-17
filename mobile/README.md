# Q'Me Mobile (Flutter)

Cross-platform **Android** + **iOS** app for Q'Me queue management.
Uses the FastAPI backend in `/backend`.

## Features

- Sign in / register
- Organization & queue management
- Staff console (call next, serve, complete, skip, cancel)
- Live queue insights
- Public customer join + live ticket tracking

## Local run

```bash
# Backend
cd backend
pip3 install -r requirements.txt
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000

# App
cd mobile
flutter pub get
flutter run -d android   # or ios
```

Demo: `admin@demo.com` / `password123`

## Public hosting + Play Store

See **[PLAY_STORE.md](PLAY_STORE.md)** for the full checklist:

1. Host API on public HTTPS
2. Build with `--dart-define=API_BASE_URL=https://...`
3. Create upload keystore
4. Build `.aab` and upload to Play Console

```bash
flutter build appbundle \
  --dart-define=API_BASE_URL=https://api.yourdomain.com
```

## Brand

Display name: **Q'Me**  
Android application id: `com.qme.app`
