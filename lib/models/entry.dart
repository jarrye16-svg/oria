class Entry {
  final String id;
  final String houseId;
  final String? groupId;
  final String title;
  final double amount;
  final String type;
  final String status;
  final DateTime competenceMonth;
  final DateTime? dueDate;
  final String? responsible;
  final String? notes;
  final bool isRecurring;
  final DateTime? paidAt;
  final String? mode;
  final String? cardId;
  final String? goalId;

  const Entry({
    required this.id,
    required this.houseId,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.type,
    required this.status,
    required this.competenceMonth,
    required this.dueDate,
    required this.responsible,
    required this.notes,
    required this.isRecurring,
    required this.paidAt,
    required this.mode,
    required this.cardId,
    required this.goalId,
  });

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      groupId: map['group_id'] as String?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      status: map['status'] as String,
      competenceMonth: DateTime.parse(map['competence_month'] as String),
      dueDate: map['due_date'] == null ? null : DateTime.parse(map['due_date'] as String),
      responsible: map['responsible'] as String?,
      notes: map['notes'] as String?,
      isRecurring: map['is_recurring'] as bool? ?? false,
      paidAt: map['paid_at'] == null ? null : DateTime.parse(map['paid_at'] as String),
      mode: map['mode'] as String?,
      cardId: map['card_id'] as String?,
      goalId: map['goal_id'] as String?,
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isPaid => status == 'paid';
  bool get countsInPlanned => status != 'ignored' && status != 'canceled';
  bool get countsInReal => status == 'paid' || status == 'partial';
}
