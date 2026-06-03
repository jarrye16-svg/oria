class House {
  final String id;
  final String name;
  final String role;

  const House({
    required this.id,
    required this.name,
    required this.role,
  });

  factory House.fromMap(Map<String, dynamic> map) {
    return House(
      id: map['house_id'] as String,
      name: map['house_name'] as String,
      role: map['role'] as String,
    );
  }

  bool get isAdmin => role == 'admin';
}
