import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sèvis otantifikasyon + verifikasyon admin.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp(
    String email,
    String password, {
    String? fullName,
  }) => _client.auth.signUp(
    email: email,
    password: password,
    emailRedirectTo: redirectUrl,
    data: {if (fullName != null && fullName.isNotEmpty) 'full_name': fullName},
  );

  String get redirectUrl => kIsWeb
      ? Uri.base.replace(fragment: '', query: '').toString()
      : 'redlight://auth/callback';

  Future<bool> signInWithGoogle() => _client.auth.signInWithOAuth(
    OAuthProvider.google, redirectTo: redirectUrl,
  );

  Future<void> resetPassword(String email) => _client.auth.resetPasswordForEmail(
    email.trim(), redirectTo: redirectUrl,
  );

  Future<void> updateProfile({required String name, required String phone, required String address}) async {
    await _client.auth.updateUser(UserAttributes(data: {'full_name': name.trim(), 'phone': phone.trim(), 'address': address.trim()}));
  }

  Future<void> changePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Verifye si itilizatè konekte a se yon admin (fonksyon SQL is_admin()).
  Future<bool> isAdmin() async {
    final result = await _client.rpc('is_admin');
    return result == true;
  }
}
