import '../core/formatters.dart';
import '../models/goal.dart';
import 'supabase_service.dart';

class GoalService {
  Future<List<Goal>> getGoals(String houseId) async {
    final data = await supabase
        .from('goals')
        .select()
        .eq('house_id', houseId)
        .order('is_active', ascending: false)
        .order('name');

    return (data as List)
        .map((row) => Goal.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> upsertGoal({
    String? id,
    required String houseId,
    required String name,
    required double targetAmount,
    required double currentAmount,
    required String ownerName,
    DateTime? targetDate,
    bool isActive = true,
  }) async {
    final payload = {
      'house_id': houseId,
      'name': name.trim(),
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'owner_name': ownerName.trim().isEmpty ? 'Casa' : ownerName.trim(),
      'target_date': targetDate == null ? null : isoDate(targetDate),
      'is_active': isActive,
    };

    if (id == null) {
      await supabase.from('goals').insert(payload);
    } else {
      await supabase.from('goals').update(payload).eq('id', id);
    }
  }

  Future<void> addMovement({
    required String houseId,
    required String goalId,
    required double amount,
    required String kind,
    required String note,
  }) async {
    await supabase.from('goal_movements').insert({
      'house_id': houseId,
      'goal_id': goalId,
      'amount': amount,
      'kind': kind,
      'note': note.trim().isEmpty ? null : note.trim(),
    });
  }

  Future<void> deleteGoal(String id) async {
    await supabase.from('goals').delete().eq('id', id);
  }

  Future<double> getMonthContributions({required String houseId, required DateTime month}) async {
    final start = monthStart(month);
    final end = DateTime(start.year, start.month + 1, 1);
    final data = await supabase
        .from('goal_movements')
        .select('amount, kind')
        .eq('house_id', houseId)
        .gte('created_at', start.toUtc().toIso8601String())
        .lt('created_at', end.toUtc().toIso8601String());

    double total = 0;
    for (final row in data as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final amount = (map['amount'] as num).toDouble();
      total += map['kind'] == 'withdraw' ? -amount : amount;
    }
    return total;
  }
}
