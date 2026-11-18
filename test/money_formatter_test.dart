import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oria/core/formatters.dart';

void main() {
  test('typing whole numbers does not multiply previously added cents', () {
    const formatter = MoneyInputFormatter();
    var value = TextEditingValue.empty;
    for (final char in '2500'.split('')) {
      value = formatter.formatEditUpdate(
        value,
        TextEditingValue(text: value.text + char),
      );
    }
    expect(value.text, '2500');
    expect(parseMoney(value.text), 2500);
  });
  test('decimals, deletions and invalid characters preserve editing', () {
    const formatter = MoneyInputFormatter();
    const old = TextEditingValue(text: '10,5');
    expect(
      formatter
          .formatEditUpdate(old, const TextEditingValue(text: '10,50'))
          .text,
      '10,50',
    );
    expect(
      formatter.formatEditUpdate(old, const TextEditingValue(text: '10,')).text,
      '10,',
    );
    expect(
      formatter.formatEditUpdate(old, const TextEditingValue(text: '10x5')),
      old,
    );
  });
}
