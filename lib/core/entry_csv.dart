import '../models/entry.dart';
import 'money_parser.dart';

const entryCsvFields = [
  'id',
  'house_id',
  'group_id',
  'title',
  'amount',
  'type',
  'status',
  'competence_month',
  'due_date',
  'responsible',
  'notes',
  'is_recurring',
  'mode',
  'card_id',
  'goal_id',
  'paid_at',
];

String exportEntryCsv(List<Entry> entries) {
  String quote(Object? value) =>
      '"${(value ?? '').toString().replaceAll('"', '""')}"';
  String date(DateTime value) => value.toIso8601String().substring(0, 10);
  final rows = <List<Object?>>[entryCsvFields];
  for (final e in entries) {
    rows.add([
      e.id,
      e.houseId,
      e.groupId,
      e.title,
      e.amount.toStringAsFixed(2),
      e.type,
      e.status,
      date(e.competenceMonth),
      e.dueDate == null ? null : date(e.dueDate!),
      e.responsible,
      e.notes,
      e.isRecurring,
      e.mode,
      e.cardId,
      e.goalId,
      e.paidAt?.toUtc().toIso8601String(),
    ]);
  }
  return rows.map((row) => row.map(quote).join(',')).join('\r\n');
}

List<List<String>> _csvRows(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  var closed = false;
  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
          closed = true;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"' && field.isEmpty && !closed) {
      quoted = true;
    } else if (c == ',') {
      row.add(field.toString());
      field = StringBuffer();
      closed = false;
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
      row.add(field.toString());
      rows.add(row);
      row = [];
      field = StringBuffer();
      closed = false;
    } else {
      if (closed || c == '"')
        throw const FormatException('CSV com aspas inválidas.');
      field.write(c);
    }
  }
  if (quoted) throw const FormatException('CSV com aspas não fechadas.');
  if (row.isNotEmpty || field.isNotEmpty || closed) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

List<Map<String, dynamic>> importEntryCsv(String input, String houseId) {
  if (input.length > 5000000)
    throw const FormatException('Arquivo muito grande.');
  final rows = _csvRows(input.replaceFirst('\ufeff', ''));
  if (rows.isEmpty || rows.first.join('|') != entryCsvFields.join('|')) {
    throw const FormatException('Use um CSV exportado pelo Oria nesta versão.');
  }
  final result = <Map<String, dynamic>>[];
  final ids = <String>{};
  final uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  bool validDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final date = DateTime.tryParse(value);
    return date != null && date.toIso8601String().substring(0, 10) == value;
  }

  for (var index = 1; index < rows.length; index++) {
    final values = rows[index];
    if (values.every((value) => value.isEmpty)) continue;
    if (values.length != entryCsvFields.length)
      throw FormatException('Linha ${index + 1}: número de colunas inválido.');
    final row = Map<String, dynamic>.fromIterables(entryCsvFields, values);
    void check(bool valid) {
      if (!valid)
        throw FormatException(
          'Linha ${index + 1}: dados inválidos ou de outra casa.',
        );
    }

    check(
      row['house_id'] == houseId &&
          uuid.hasMatch(row['id']) &&
          ids.add(row['id']),
    );
    for (final field in ['group_id', 'card_id', 'goal_id']) {
      check(row[field] == '' || uuid.hasMatch(row[field]));
      if (row[field] == '') row[field] = null;
    }
    final amount = tryParseMoney(row['amount']);
    check(amount != null && amount >= 0 && amount <= 9999999999.99);
    row['amount'] = amount;
    check((row['title'] as String).trim().isNotEmpty);
    check(['income', 'expense'].contains(row['type']));
    check(
      [
        'paid',
        'pending',
        'partial',
        'ignored',
        'canceled',
      ].contains(row['status']),
    );
    check(
      validDate(row['competence_month']) &&
          (row['competence_month'] as String).endsWith('-01'),
    );
    check(row['due_date'] == '' || validDate(row['due_date']));
    check(['true', 'false'].contains(row['is_recurring']));
    row['is_recurring'] = row['is_recurring'] == 'true';
    check(row['paid_at'] == '' || DateTime.tryParse(row['paid_at']) != null);
    check(
      [
        '',
        'income',
        'fixed_expense',
        'card_invoice',
        'goal_contribution',
        'financing',
        'third_party',
      ].contains(row['mode']),
    );
    for (final field in [
      'due_date',
      'responsible',
      'notes',
      'mode',
      'paid_at',
    ]) {
      if (row[field] == '') row[field] = null;
    }
    result.add(row);
    if (result.length > 5000)
      throw const FormatException('Importe até 5.000 lançamentos por vez.');
  }
  return result;
}
