import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';

/// Pwen antre sèvis Supabase la.
abstract final class SupabaseService {
  static Future<void> init() => Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  static SupabaseClient get client => Supabase.instance.client;
}
