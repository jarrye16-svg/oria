class EntryGroup {
  final String id;
  final String houseId;
  final String name;
  final String kind;
  final String color;
  final int sortOrder;

  const EntryGroup({
    required this.id,
    required this.houseId,
    required this.name,
    required this.kind,
    required this.color,
    required this.sortOrder,
  });

  factory EntryGroup.fromMap(Map<String, dynamic> map) {
    return EntryGroup(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      name: map['name'] as String,
      kind: map['kind'] as String,
      color: map['color'] as String? ?? '#1D4ED8',
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
