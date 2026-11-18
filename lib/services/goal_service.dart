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
    if (!targetAmount.isFinite ||
        targetAmount <= 0 ||
        !currentAmount.isFinite ||
        currentAmount < 0) {
      throw ArgumentError('Informe valores válidos para o porquinho.');
    }
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
    if (!amount.isFinite ||
        amount <= 0 ||
        !['deposit', 'withdraw'].contains(kind)) {
      throw ArgumentError('Movimentação inválida.');
    }
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

  Future<double> getMonthContributions({
    required String houseId,
    required DateTime month,
  }) async {
    final start = monthStart(month);
    final end = DateTime(start.year, start.month + 1, 1);
    double total = 0;
    var offset = 0;
    while (true) {
      final data = await supabase
          .from('goal_movements')
          .select('amount, kind, id')
          .eq('house_id', houseId)
          .gte('created_at', start.toUtc().toIso8601String())
          .lt('created_at', end.toUtc().toIso8601String())
          .order('id')
          .range(offset, offset + 199);
      if (data.isEmpty) break;
      for (final map in data) {
        final amount = (map['amount'] as num).toDouble();
        total += map['kind'] == 'withdraw' ? -amount : amount;
      }
      offset += data.length;
    }
    return total;
  }
}
