# Q'Me — Google Play publishing checklist

This guide covers what you need to **host the API publicly** and ship the Android app to the Play Store. UI flows stay the same; the app just talks to your public HTTPS backend.

## 1. Host the backend publicly (required)

Play Store installs cannot reach `localhost`. Deploy the FastAPI API to any HTTPS host.

### Option A — Docker (recommended)

```bash
# from repo root
docker build -t qme-api -f backend/Dockerfile backend
docker run -d -p 8000:8000 --name qme-api qme-api
```

Put HTTPS in front (Caddy, Nginx, Cloudflare Tunnel, Render, Fly.io, Railway, etc.).

Example public URL shape: `https://api.yourdomain.com`

### Option B — bare metal / VPS

```bash
cd backend
pip3 install -r requirements.txt
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Terminate TLS with a reverse proxy.

### Verify

- `https://api.yourdomain.com/api/health` → `{"status":"ok"}`
- CORS is already open (`allow_origins=["*"]`) for mobile clients

## 2. Point the Android app at that public API

Release / Play builds **require** a public API URL:

```bash
cd mobile
flutter build appbundle \
  --dart-define=API_BASE_URL=https://api.yourdomain.com
```

Equivalent:

```bash
flutter build appbundle \
  --dart-define=PRODUCTION_API_BASE_URL=https://api.yourdomain.com
```

Without one of these, release mode throws on startup (by design — avoids shipping a localhost build).

## 3. Create a Play Console developer account

1. Go to [Google Play Console](https://play.google.com/console)
2. Pay the one-time registration fee
3. Complete identity / organization verification if prompted

## 4. Create an upload keystore (keep this safe)

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias qme
```

Copy the example properties file:

```bash
cd mobile/android
cp key.properties.example key.properties
# edit passwords + path to upload-keystore.jks
```

`key.properties` and `*.jks` must **never** be committed to git.

## 5. Build the release App Bundle (.aab)

```bash
cd mobile
flutter pub get
flutter build appbundle \
  --dart-define=API_BASE_URL=https://api.yourdomain.com
```

Output:

`mobile/build/app/outputs/bundle/release/app-release.aab`

App ID: `com.qme.app`  
Display name: **Q'Me**

## 6. Play Console store listing assets (you provide)

| Asset | Typical requirement |
|-------|---------------------|
| App name | Q'Me |
| Short description | ≤ 80 characters |
| Full description | Feature overview |
| App icon | 512×512 PNG |
| Feature graphic | 1024×500 |
| Phone screenshots | ≥ 2 |
| Privacy policy URL | **Required** (hosted page) |
| Category | e.g. Business / Productivity |
| Contact email | Required |

## 7. Privacy / Data safety

Even with email/password auth you must complete the Data safety form:

- Collects: email, name (account), optional phone on tickets
- Purpose: app functionality
- Encrypted in transit: yes (use HTTPS)
- Account deletion: document how users can request it (email is fine for v1)

## 8. Content rating & target audience

Complete the IARC questionnaire in Play Console. Q'Me is generally suitable for all ages (business utility).

## 9. Create the app + upload

1. Create app → name **Q'Me** → free/paid → declarations
2. Production (or closed testing first — recommended)
3. Upload `app-release.aab`
4. Complete **Dashboard** checklist until “Ready to send for review”
5. Roll out to testing track → then production

## 10. Recommended release path

1. **Internal testing** track (fast)
2. **Closed testing** with a few testers
3. **Open testing** (optional)
4. **Production**

## Common blockers

| Issue | Fix |
|-------|-----|
| App can’t reach API | Confirm HTTPS URL + `--dart-define=API_BASE_URL=...` |
| Cleartext blocked | Production must be HTTPS (debug still allows emulator localhost) |
| Unsigned / wrong key | Use `key.properties` + upload keystore |
| Missing privacy policy | Host a simple policy page and paste URL |
| Package name | Already set to `com.qme.app` |

## Version bumps

In `mobile/pubspec.yaml`:

```yaml
version: 1.0.1+2   # name+code  (code must increase every Play upload)
```

Or:

```bash
flutter build appbundle --build-name=1.0.1 --build-number=2 \
  --dart-define=API_BASE_URL=https://api.yourdomain.com
```
