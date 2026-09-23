import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import 'core_providers.dart';

/// Lang app la — default 'fr', persiste nan SharedPreferences.
/// Depi ou `setLocale`, tout widget ki `watch(stringsProvider)`
/// rebati otomatikman.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final code = ref.watch(localStoreProvider).languageCode;
    return Locale(supportedLocales.any((l) => l.languageCode == code)
        ? code!
        : 'fr');
  }

  Future<void> setLocale(String code) async {
    await ref.read(localStoreProvider).setLanguageCode(code);
    state = Locale(code);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

/// Aksè tout tèks tradui yo pou lang aktif la.
final stringsProvider = Provider<S>(
  (ref) => S.of(ref.watch(localeProvider)),
);
