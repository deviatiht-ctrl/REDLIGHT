import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Depo lokal: onboarding, panyen, favori, dènye rechèch.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  bool get guestMode => _prefs.getBool('guest_mode') ?? false;
  Future<void> setGuestMode(bool value) => _prefs.setBool('guest_mode', value);
  String get themeMode => _prefs.getString('theme_mode') ?? 'system';
  Future<void> setThemeMode(String value) => _prefs.setString('theme_mode', value);

  static const _kOnboarding = 'onboarding_done';
  static const _kLanguage = 'language_code';
  static const _kCart = 'cart_items';
  static const _kFavorites = 'favorites';
  static const _kRecentSearches = 'recent_searches';

  // --- Onboarding ---
  bool get onboardingDone => _prefs.getBool(_kOnboarding) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_kOnboarding, true);

  // --- Lang (null = poko chwazi → montre ekran lang) ---
  String? get languageCode => _prefs.getString(_kLanguage);
  bool get languageChosen => languageCode != null;
  Future<void> setLanguageCode(String code) =>
      _prefs.setString(_kLanguage, code);

  // --- Panyen (persiste kòm JSON: [{"product_id": "...", "quantity": 2}]) ---
  List<Map<String, dynamic>> get cartItems {
    final raw = _prefs.getString(_kCart);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCart(List<Map<String, dynamic>> items) =>
      _prefs.setString(_kCart, jsonEncode(items));

  // --- Favori (lis id pwodwi) ---
  Set<String> get favorites =>
      (_prefs.getStringList(_kFavorites) ?? const []).toSet();

  Future<void> saveFavorites(Set<String> ids) =>
      _prefs.setStringList(_kFavorites, ids.toList());

  // --- Dènye rechèch ---
  List<String> get recentSearches =>
      _prefs.getStringList(_kRecentSearches) ?? const [];

  Future<void> addRecentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final list = [q, ...recentSearches.where((e) => e != q)];
    await _prefs.setStringList(
      _kRecentSearches,
      list.take(8).toList(),
    );
  }

  Future<void> clearRecentSearches() => _prefs.remove(_kRecentSearches);
}
