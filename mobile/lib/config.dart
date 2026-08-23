/// API base URL for the QueueFlow backend.
///
/// Defaults:
/// - Android emulator: http://10.0.2.2:8000
/// - iOS simulator / desktop / web: http://127.0.0.1:8000
/// Override at build time:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
library;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}
