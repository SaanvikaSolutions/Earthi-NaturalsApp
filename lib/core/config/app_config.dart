import 'package:flutter/foundation.dart';

/// Central place for environment configuration (API base URL, etc.).
class AppConfig {
  /// Override at build/run time, e.g.
  ///   flutter run --dart-define=API_BASE_URL=https://api.earthi.example.com
  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Base URL of the backend API.
  ///
  /// Defaults are chosen so the app talks to a backend running on the dev
  /// machine: Android emulators reach the host via 10.0.2.2, everything else
  /// (iOS simulator, desktop, web) uses localhost.
  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api';
    }
    return 'http://localhost:4000/api';
  }
}

/// Customer-support contact details surfaced on the Help & Support screen.
///
/// TODO: replace these placeholders with the real Earthi Naturals support
/// number and inbox before release — they are the only copies in the app.
class SupportContact {
  static const String phone = '+910000000000';
  static const String email = 'support@earthinaturals.com';
}
