import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'money_parser.dart';
export 'money_parser.dart';

final _moneyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

final _moneyInputFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: '',
  decimalDigits: 2,
);

final _monthFormat = DateFormat('MMMM yyyy', 'pt_BR');
final _shortDateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

String money(double value) => _moneyFormat.format(value);

String monthLabel(DateTime month) {
  final raw = _monthFormat.format(month);
  return raw.substring(0, 1).toUpperCase() + raw.substring(1);
}

String dateLabel(DateTime? date) {
  if (date == null) return 'Sem vencimento';
  return _shortDateFormat.format(date);
}

DateTime monthStart(DateTime date) => DateTime(date.year, date.month, 1);

DateTime previousMonth(DateTime date) => DateTime(date.year, date.month - 1, 1);

DateTime nextMonth(DateTime date) => DateTime(date.year, date.month + 1, 1);

String isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

String formatMoneyInputValue(double value) {
  return _moneyInputFormat.format(value).trim();
}

String monthYearLabel(DateTime month) => monthLabel(month);

/// Preserva a digitação e o cursor; aceita inteiros e até dois centavos.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.trim();

    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Keep the text and cursor intact: formatting while typing used to
    // reinterpret the cents added by the formatter as whole currency units.
    if (RegExp(r'^\d*(?:[.,]\d{0,2})?$').hasMatch(raw) ||
        (tryParseMoney(raw) ?? -1) >= 0) {
      return newValue;
    }
    return oldValue;
  }
}
