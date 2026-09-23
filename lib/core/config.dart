import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigirasyon app la.
///
/// Li kle Supabase nan lòd sa a:
/// 1. `--dart-define` (rekomande pou pwodiksyon / web)
///    ex: flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// 2. Fichye `.env` nan rasin pwojè a (flutter_dotenv)
class AppConfig {
  static String get supabaseUrl =>
      _pick(const String.fromEnvironment('SUPABASE_URL'), _env('SUPABASE_URL'));

  static String get supabaseAnonKey => _pick(
    const String.fromEnvironment('SUPABASE_ANON_KEY'),
    _env('SUPABASE_ANON_KEY'),
  );

  static bool get isConfigured =>
      supabaseUrl.startsWith('http') && supabaseAnonKey.isNotEmpty;

  static String _pick(String dartDefine, String? env) =>
      dartDefine.isNotEmpty ? dartDefine : (env ?? '');

  static String? _env(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }
}
