import 'package:flutter_test/flutter_test.dart';
import 'package:redlight_automotive/core/utils/format.dart';

void main() {
  test('formatPrice ajoute monnen HTG', () {
    expect(formatPrice(1250), endsWith('HTG'));
    expect(formatPrice(1250.5), contains('1,250.50'));
  });
}
