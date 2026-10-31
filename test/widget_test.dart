import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redlight_autoparts/core/utils/format.dart';

void main() {
  test('formatPrice ajoute monnen HTG', () {
    expect(formatPrice(1250), endsWith('HTG'));
    expect(formatPrice(1250.5), contains('1,250.50'));
  });

  testWidgets('TextField monte san okenn erè lè lang lan se Kreyòl (ht)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ht'),
        supportedLocales: [Locale('ht'), Locale('fr')],
        localizationsDelegates: [
          _TestHtMaterialLocalizationsDelegate(),
          _TestHtCupertinoLocalizationsDelegate(),
          _TestHtWidgetsLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: TextField(
            decoration: InputDecoration(hintText: 'Antre imèl ou'),
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Antre imèl ou'), findsOneWidget);
  });
}

class _TestHtMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _TestHtMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ht';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('fr'));

  @override
  bool shouldReload(_TestHtMaterialLocalizationsDelegate old) => false;
}

class _TestHtCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _TestHtCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ht';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('fr'));

  @override
  bool shouldReload(_TestHtCupertinoLocalizationsDelegate old) => false;
}

class _TestHtWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _TestHtWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ht';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('fr'));

  @override
  bool shouldReload(_TestHtWidgetsLocalizationsDelegate old) => false;
}
