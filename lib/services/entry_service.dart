import '../core/formatters.dart';
import '../models/entry.dart';
import '../models/entry_group.dart';
import 'supabase_service.dart';

class EntryService {
  Future<List<EntryGroup>> getGroups(String houseId) async {
    final data = await supabase
        .from('entry_groups')
        .select()
        .eq('house_id', houseId)
        .order('sort_order', ascending: true);

    return (data as List)
        .map((row) => EntryGroup.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<EntryGroup> createGroup({
    required String houseId,
    required String name,
    required String kind,
  }) async {
    final data = await supabase
        .from('entry_groups')
        .insert({
          'house_id': houseId,
          'name': name.trim(),
          'kind': kind,
          'color': '#1D4ED8',
          'sort_order': 999,
          'is_default': false,
        })
        .select()
        .single();

    return EntryGroup.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<EntryGroup> updateGroup({
    required String id,
    required String name,
  }) async {
    final data = await supabase
        .from('entry_groups')
        .update({'name': name.trim()})
        .eq('id', id)
        .select()
        .single();

    return EntryGroup.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteGroup(String id) async {
    await supabase.from('entry_groups').delete().eq('id', id);
  }

  Future<List<Entry>> getEntries({required String houseId, required DateTime month}) async {
    final data = await supabase
        .from('entries')
        .select()
        .eq('house_id', houseId)
        .eq('competence_month', isoDate(monthStart(month)))
        .order('type', ascending: false)
        .order('due_date', ascending: true)
        .order('title', ascending: true);

    return (data as List)
        .map((row) => Entry.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<Entry>> getAllEntries({required String houseId}) async {
    final data = await supabase
        .from('entries')
        .select()
        .eq('house_id', houseId)
        .order('competence_month', ascending: false)
        .order('type', ascending: false)
        .order('due_date', ascending: true)
        .order('title', ascending: true);

    return (data as List)
        .map((row) => Entry.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> upsertEntry({
    String? id,
    required String houseId,
    required String? groupId,
    required String title,
    required double amount,
    required String type,
    required String status,
    required DateTime competenceMonth,
    required DateTime? dueDate,
    required String? responsible,
    required String? notes,
    required bool isRecurring,
    String? mode,
    String? cardId,
    String? goalId,
  }) async {
    final payload = <String, dynamic>{
      'house_id': houseId,
      'group_id': groupId,
      'title': title.trim(),
      'amount': amount,
      'type': type,
      'status': status,
      'competence_month': isoDate(monthStart(competenceMonth)),
      'due_date': dueDate == null ? null : isoDate(dueDate),
      'responsible': responsible?.trim().isEmpty ?? true ? null : responsible!.trim(),
      'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      'is_recurring': isRecurring,
      'mode': mode,
      'card_id': cardId,
      'goal_id': goalId,
      'paid_at': status == 'paid' ? DateTime.now().toUtc().toIso8601String() : null,
    };

    if (id == null) {
      await supabase.from('entries').insert(payload);
    } else {
      await supabase.from('entries').update(payload).eq('id', id);
    }
  }

  Future<void> setEntryPaid(Entry entry, bool paid) async {
    await supabase.from('entries').update({
      'status': paid ? 'paid' : 'pending',
      'paid_at': paid ? DateTime.now().toUtc().toIso8601String() : null,
      'paid_by': paid ? supabase.auth.currentUser?.id : null,
    }).eq('id', entry.id);
  }

  DateTime _sameDayNextMonth(DateTime? date, DateTime nextMonth) {
    if (date == null) return nextMonth;

    final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(nextMonth.year, nextMonth.month, day);
  }

  String _recurrenceKey(Entry entry) {
    return [
      entry.title.trim().toLowerCase(),
      entry.mode ?? '',
      entry.cardId ?? '',
      entry.goalId ?? '',
      entry.groupId ?? '',
    ].join('|');
  }

  Future<int> generateNextMonth({
    required String houseId,
    required DateTime currentMonth,
  }) async {
    final sourceMonth = monthStart(currentMonth);
    final targetMonth = nextMonth(sourceMonth);

    final sourceEntries = await getEntries(houseId: houseId, month: sourceMonth);
    final targetEntries = await getEntries(houseId: houseId, month: targetMonth);

    final existing = targetEntries.map(_recurrenceKey).toSet();
    final payloads = <Map<String, dynamic>>[];

    for (final entry in sourceEntries) {
      if (!entry.isRecurring || !entry.countsInPlanned) continue;
      if (existing.contains(_recurrenceKey(entry))) continue;

      payloads.add({
        'house_id': houseId,
        'group_id': entry.groupId,
        'title': entry.title.trim(),
        'amount': entry.amount,
        'type': entry.type,
        'status': entry.isIncome ? 'paid' : 'pending',
        'competence_month': isoDate(targetMonth),
        'due_date': entry.dueDate == null ? null : isoDate(_sameDayNextMonth(entry.dueDate, targetMonth)),
        'responsible': entry.responsible,
        'notes': entry.notes,
        'is_recurring': true,
        'mode': entry.mode,
        'card_id': entry.cardId,
        'goal_id': entry.goalId,
      });
    }

    if (payloads.isEmpty) return 0;

    await supabase.from('entries').insert(payloads);
    return payloads.length;
  }

  Future<void> updateEntryNotes({
    required String id,
    required String? notes,
  }) async {
    await supabase.from('entries').update({
      'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
    }).eq('id', id);
  }

  Future<void> duplicateEntryToNextMonth(Entry entry) async {
    final sourceMonth = monthStart(entry.competenceMonth);
    final targetMonth = nextMonth(sourceMonth);
    final targetDueDate = entry.dueDate == null ? null : _sameDayNextMonth(entry.dueDate, targetMonth);

    await supabase.from('entries').insert({
      'house_id': entry.houseId,
      'group_id': entry.groupId,
      'title': entry.title.trim(),
      'amount': entry.amount,
      'type': entry.type,
      'status': entry.isIncome ? 'paid' : 'pending',
      'competence_month': isoDate(targetMonth),
      'due_date': targetDueDate == null ? null : isoDate(targetDueDate),
      'responsible': entry.responsible,
      'notes': entry.notes,
      'is_recurring': entry.isRecurring,
      'mode': entry.mode,
      'card_id': entry.cardId,
      'goal_id': entry.goalId,
      'paid_at': entry.isIncome ? DateTime.now().toUtc().toIso8601String() : null,
      'paid_by': entry.isIncome ? supabase.auth.currentUser?.id : null,
    });
  }

  Future<void> deleteEntry(String id) async {
    await supabase.from('entries').delete().eq('id', id);
  }
}
