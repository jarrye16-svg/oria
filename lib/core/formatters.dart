import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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

double parseMoney(String value) {
  var cleaned = value.trim();
  if (cleaned.isEmpty) return 0;

  cleaned = cleaned.replaceAll('R\$', '').replaceAll(' ', '');

  // Valor ja formatado no padrao BR: 2.500,00
  if (cleaned.contains(',')) {
    cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  // Valor simples digitado no Android: 2500 vira 2500.00
  cleaned = cleaned.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(cleaned) ?? 0;
}

String formatMoneyInputValue(double value) {
  return _moneyInputFormat.format(value).trim();
}

String monthYearLabel(DateTime month) => monthLabel(month);

/// Formata dinheiro enquanto digita, pensando no Android:
/// - 2500 vira 2.500,00
/// - 10 vira 10,00
/// - remove caracteres quebrados automaticamente
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.trim();

    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final value = double.tryParse(digits) ?? 0;
    final formatted = formatMoneyInputValue(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
