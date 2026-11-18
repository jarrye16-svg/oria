import '../lib/core/money_parser.dart';
import '../lib/core/input_validation.dart';
import '../lib/core/request_id.dart';
import '../lib/core/entry_csv.dart';
import '../lib/models/entry.dart';

int checks = 0;
void check(bool value, String description) {
  checks++;
  if (!value) throw StateError(description);
}

void rejects(void Function() action, String description) {
  try {
    action();
  } on FormatException {
    check(true, description);
    return;
  }
  check(false, description);
}

void main() {
  final amounts = <String, double>{
    '2.500,00': 2500,
    '2500': 2500,
    '10,50': 10.5,
    '10.50': 10.5,
    '1.000': 1000,
    '-10': -10,
    '-10,00': -10,
    'R\$ 1.234,56': 1234.56,
    '0': 0,
    '0,01': 0.01,
    '1.234.567': 1234567,
    ' 10 ': 10,
  };
  for (final item in amounts.entries)
    check(tryParseMoney(item.key) == item.value, 'parse ${item.key}');
  for (final invalid in [
    '1e3',
    'abc',
    'NaN',
    'Infinity',
    '1,2,3',
    '1.23,45',
    '1,234',
    '--10',
    '1 000',
    '',
  ]) {
    check(tryParseMoney(invalid) == null, 'reject $invalid');
  }
  for (final email in [
    'teste@teste.com',
    'a+b@example.com',
    'nome.sobrenome@empresa.com.br',
  ]) {
    check(validEmail(email), 'email $email');
  }
  for (final email in ['abc@', '@abc.com', 'abc', 'a b@c.com', 'a@@c.com']) {
    check(!validEmail(email), 'invalid email $email');
  }
  final ids = List.generate(100, (_) => newRequestId());
  check(ids.toSet().length == 100, 'unique request ids');
  check(
    ids.every(
      (id) => RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(id),
    ),
    'valid UUIDs',
  );
  const house = '10000000-0000-4000-8000-000000000001';
  final entry = Entry(
    id: '20000000-0000-4000-8000-000000000001',
    houseId: house,
    groupId: null,
    title: 'Mercado, "bairro"',
    amount: 1234.56,
    type: 'expense',
    status: 'paid',
    competenceMonth: DateTime(2026, 11),
    dueDate: DateTime(2026, 11, 30),
    responsible: 'Casa',
    notes: 'linha 1\nlinha 2, "ok"',
    isRecurring: true,
    paidAt: DateTime.utc(2026, 11, 18),
    mode: 'fixed_expense',
    cardId: null,
    goalId: null,
  );
  final csv = exportEntryCsv([entry]);
  final rows = importEntryCsv(csv, house);
  check(rows.length == 1, 'csv row count');
  final restored = Entry.fromMap(rows.single);
  check(restored.title == entry.title, 'quoted title round trip');
  check(restored.notes == entry.notes, 'multiline notes round trip');
  check(restored.amount == entry.amount, 'money round trip');
  check(restored.paidAt == entry.paidAt, 'payment date round trip');
  check(restored.isRecurring, 'recurrence round trip');
  check(restored.dueDate == entry.dueDate, 'due date round trip');
  check(
    importEntryCsv('\ufeff$csv\r\n', house).length == 1,
    'BOM and trailing newline',
  );
  check(importEntryCsv(exportEntryCsv([]), house).isEmpty, 'empty export');
  rejects(() => importEntryCsv(csv, 'other-house'), 'different house');
  rejects(
    () => importEntryCsv(exportEntryCsv([entry, entry]), house),
    'duplicate ids',
  );
  rejects(
    () => importEntryCsv(csv.replaceFirst('1234.56', '-1234.56'), house),
    'negative amount',
  );
  rejects(
    () => importEntryCsv(csv.replaceFirst('2026-11-30', '2026-11-99'), house),
    'invalid date',
  );
  rejects(
    () => importEntryCsv(csv.replaceFirst('"expense"', '"unknown"'), house),
    'invalid type',
  );
  rejects(() => importEntryCsv('id,title\n1,abc', house), 'unexpected header');
  rejects(() => importEntryCsv('"unclosed', house), 'broken quoting');
  print(
    'PASS: $checks verificações de valores, e-mail, identificadores e CSV.',
  );
}
