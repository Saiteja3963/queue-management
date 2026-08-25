/// API base URL for the Q'Me backend.
///
/// For Play Store / production builds, pass your publicly hosted HTTPS API:
///   flutter build appbundle --dart-define=API_BASE_URL=https://api.yourdomain.com
///
/// Local defaults (dev only):
/// - Android emulator: http://10.0.2.2:8000
/// - iOS simulator / desktop / web: http://127.0.0.1:8000
library;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, kReleaseMode, TargetPlatform;

/// Optional compile-time production host.
/// Prefer setting this (or API_BASE_URL) when shipping to Google Play.
const String kProductionApiBaseUrl = String.fromEnvironment(
  'PRODUCTION_API_BASE_URL',
);

String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kProductionApiBaseUrl.isNotEmpty) return kProductionApiBaseUrl;

  // Release builds must not silently fall back to localhost.
  if (kReleaseMode) {
    throw StateError(
      "Missing public API URL. Build with "
      "--dart-define=API_BASE_URL=https://your-public-api.example.com",
    );
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}
