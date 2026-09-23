import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/local_store.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/supabase_service.dart';

/// SharedPreferences — override nan main() apre `getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider pa override'),
);

final localStoreProvider = Provider<LocalStore>(
  (ref) => LocalStore(ref.watch(sharedPreferencesProvider)),
);

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseService.client,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(supabaseClientProvider)),
);

final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(ref.watch(supabaseClientProvider)),
);

final orderServiceProvider = Provider<OrderService>(
  (ref) => OrderService(ref.watch(supabaseClientProvider)),
);

/// Stream sou chanjman auth (login/logout) — router la koute li tou.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authServiceProvider).authChanges,
);

/// Itilizatè konekte a (null si envite).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).currentUser;
});

/// True si itilizatè konekte a nan tab `admin_users`.
final isAdminProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(currentUserProvider) == null) return false;
  try {
    return await ref.watch(authServiceProvider).isAdmin();
  } catch (_) {
    return false;
  }
});
