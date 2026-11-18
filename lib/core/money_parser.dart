/// Accepts Brazilian amounts and decimal points, without silently removing data.
double? tryParseMoney(String text) {
  var value = text.trim().replaceFirst(RegExp(r'^R\$\s*'), '');
  value = value.replaceAll('\u00a0', '');
  if (value.isEmpty) return null;
  final brazilian = RegExp(r'^-?(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$');
  final decimal = RegExp(r'^-?\d+(?:\.\d{1,2})?$');
  if (value.contains(',') ||
      RegExp(r'^-?\d{1,3}(?:\.\d{3})+$').hasMatch(value)) {
    if (!brazilian.hasMatch(value)) return null;
    value = value.replaceAll('.', '').replaceAll(',', '.');
  } else if (!decimal.hasMatch(value)) {
    return null;
  }
  final number = double.tryParse(value);
  return number != null && number.isFinite ? number : null;
}

double parseMoney(String value) => tryParseMoney(value) ?? 0;
