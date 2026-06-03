class OriaCardModel {
  final String id;
  final String houseId;
  final String name;
  final String ownerName;
  final String bankName;
  final int? closingDay;
  final int? dueDay;
  final double? limitAmount;
  final bool isActive;

  const OriaCardModel({
    required this.id,
    required this.houseId,
    required this.name,
    required this.ownerName,
    required this.bankName,
    required this.closingDay,
    required this.dueDay,
    required this.limitAmount,
    required this.isActive,
  });

  factory OriaCardModel.fromMap(Map<String, dynamic> map) {
    return OriaCardModel(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      name: map['name'] as String,
      ownerName: map['owner_name'] as String? ?? 'Casa',
      bankName: map['bank_name'] as String? ?? '',
      closingDay: map['closing_day'] as int?,
      dueDay: map['due_day'] as int?,
      limitAmount: map['limit_amount'] == null ? null : (map['limit_amount'] as num).toDouble(),
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
