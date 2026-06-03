class Goal {
  final String id;
  final String houseId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String ownerName;
  final DateTime? targetDate;
  final bool isActive;

  const Goal({
    required this.id,
    required this.houseId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.ownerName,
    required this.targetDate,
    required this.isActive,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0,
      ownerName: map['owner_name'] as String? ?? 'Casa',
      targetDate: map['target_date'] == null ? null : DateTime.parse(map['target_date'] as String),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  double get progress => targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);
  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);
}
