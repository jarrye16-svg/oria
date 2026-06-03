class HouseMemberInfo {
  final String userId;
  final String email;
  final String? fullName;
  final String role;
  final String status;

  const HouseMemberInfo({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
  });

  factory HouseMemberInfo.fromMap(Map<String, dynamic> map) {
    return HouseMemberInfo(
      userId: map['user_id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String?,
      role: map['role'] as String? ?? 'member',
      status: map['status'] as String? ?? 'active',
    );
  }
}

class HouseInviteInfo {
  final String id;
  final String email;
  final String role;
  final String status;
  final String token;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;

  const HouseInviteInfo({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.token,
    required this.expiresAt,
    required this.acceptedAt,
  });

  factory HouseInviteInfo.fromMap(Map<String, dynamic> map) {
    return HouseInviteInfo(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'member',
      status: map['status'] as String? ?? 'active',
      token: map['token'] as String? ?? '',
      expiresAt: map['expires_at'] == null ? null : DateTime.parse(map['expires_at'] as String),
      acceptedAt: map['accepted_at'] == null ? null : DateTime.parse(map['accepted_at'] as String),
    );
  }
}

class CreatedInvite {
  final String token;
  final String email;
  final String role;
  final DateTime expiresAt;

  const CreatedInvite({
    required this.token,
    required this.email,
    required this.role,
    required this.expiresAt,
  });

  factory CreatedInvite.fromMap(Map<String, dynamic> map) {
    return CreatedInvite(
      token: map['token'] as String,
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'member',
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }
}


class InvitePreview {
  final String houseName;
  final String email;
  final String status;
  final DateTime? expiresAt;

  const InvitePreview({
    required this.houseName,
    required this.email,
    required this.status,
    required this.expiresAt,
  });

  factory InvitePreview.fromMap(Map<String, dynamic> map) {
    return InvitePreview(
      houseName: map['house_name'] as String? ?? 'Grupo familiar',
      email: map['email'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      expiresAt: map['expires_at'] == null ? null : DateTime.parse(map['expires_at'] as String),
    );
  }
}


class CreatedJoinCode {
  final String code;
  final String token;
  final String houseName;
  final DateTime expiresAt;

  const CreatedJoinCode({
    required this.code,
    required this.token,
    required this.houseName,
    required this.expiresAt,
  });

  factory CreatedJoinCode.fromMap(Map<String, dynamic> map) {
    return CreatedJoinCode(
      code: map['code'] as String? ?? '',
      token: map['token'] as String? ?? '',
      houseName: map['house_name'] as String? ?? 'Familia',
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }
}

class JoinLinkPreview {
  final String houseName;
  final String status;
  final DateTime? expiresAt;

  const JoinLinkPreview({
    required this.houseName,
    required this.status,
    required this.expiresAt,
  });

  factory JoinLinkPreview.fromMap(Map<String, dynamic> map) {
    return JoinLinkPreview(
      houseName: map['house_name'] as String? ?? 'Familia',
      status: map['status'] as String? ?? 'active',
      expiresAt: map['expires_at'] == null ? null : DateTime.parse(map['expires_at'] as String),
    );
  }
}
