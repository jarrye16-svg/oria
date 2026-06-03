import '../models/house_member_info.dart';
import 'supabase_service.dart';

String _friendlySupabaseError(Object error) {
  try {
    final dynamic dynamicError = error;
    final message = dynamicError.message?.toString() ?? '';
    final details = dynamicError.details?.toString() ?? '';
    final hint = dynamicError.hint?.toString() ?? '';
    final code = dynamicError.code?.toString() ?? '';

    final parts = <String>[];
    if (message.isNotEmpty) parts.add(message);
    if (details.isNotEmpty) parts.add(details);
    if (hint.isNotEmpty) parts.add('Dica: $hint');
    if (code.isNotEmpty) parts.add('Codigo: $code');

    if (parts.isNotEmpty) return parts.join(' | ');
  } catch (_) {
    // Usa mensagem generica abaixo.
  }

  return error.toString().replaceFirst('Exception: ', '');
}

class MemberService {
  Future<List<HouseMemberInfo>> getMembers(String houseId) async {
    final data = await supabase.rpc(
      'get_house_members',
      params: {'p_house_id': houseId},
    );

    return (data as List)
        .map((row) => HouseMemberInfo.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<HouseInviteInfo>> getInvites(String houseId) async {
    final data = await supabase
        .from('house_invites')
        .select('id, email, role, status, token, expires_at, accepted_at')
        .eq('house_id', houseId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => HouseInviteInfo.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<CreatedInvite> createInvite({
    required String houseId,
    required String email,
    String role = 'member',
  }) async {
    try {
      final data = await supabase.rpc(
        'create_house_invite',
        params: {
          'p_house_id': houseId,
          'p_email': email.trim().toLowerCase(),
          'p_role': role,
        },
      );

      final row = data is List ? data.first : data;
      return CreatedInvite.fromMap(Map<String, dynamic>.from(row as Map));
    } catch (error) {
      throw Exception(_friendlySupabaseError(error));
    }
  }

  Future<void> cancelInvite(String inviteId) async {
    await supabase
        .from('house_invites')
        .update({'status': 'canceled'})
        .eq('id', inviteId);
  }

  Future<void> updateMemberRole({
    required String houseId,
    required String userId,
    required String role,
  }) async {
    try {
      await supabase.rpc(
        'update_house_member_role',
        params: {
          'p_house_id': houseId,
          'p_user_id': userId,
          'p_role': role,
        },
      );
    } catch (error) {
      throw Exception(_friendlySupabaseError(error));
    }
  }

  Future<void> removeMember({
    required String houseId,
    required String userId,
  }) async {
    try {
      await supabase.rpc(
        'remove_house_member',
        params: {
          'p_house_id': houseId,
          'p_user_id': userId,
        },
      );
    } catch (error) {
      throw Exception(_friendlySupabaseError(error));
    }
  }

  Future<InvitePreview> getInvitePreview(String token) async {
    final data = await supabase.rpc(
      'get_house_invite_preview',
      params: {'p_token': token.trim()},
    );

    final row = data is List ? data.first : data;
    return InvitePreview.fromMap(Map<String, dynamic>.from(row as Map));
  }

  Future<String> acceptInvite(String token) async {
    final data = await supabase.rpc(
      'accept_house_invite',
      params: {'p_token': token.trim()},
    );

    return data as String;
  }

  Future<CreatedJoinCode> createJoinCode(String houseId) async {
    try {
      final data = await supabase.rpc(
        'create_house_join_code',
        params: {'p_house_id': houseId},
      );

      final row = data is List ? data.first : data;
      return CreatedJoinCode.fromMap(Map<String, dynamic>.from(row as Map));
    } catch (error) {
      throw Exception(_friendlySupabaseError(error));
    }
  }

  Future<JoinLinkPreview> getJoinLinkPreview(String token) async {
    try {
      final data = await supabase.rpc(
        'get_house_join_link_preview',
        params: {'p_token': token.trim()},
      );

      final row = data is List ? data.first : data;
      return JoinLinkPreview.fromMap(Map<String, dynamic>.from(row as Map));
    } catch (error) {
      throw Exception(_friendlySupabaseError(error));
    }
  }

  Future<String> acceptJoinLink(String token) async {
    try {
      final data = await supabase.rpc(
        'accept_house_join_link',
        params: {'p_token': token.trim()},
      );

      return data as String;
    } catch (error) {
      throw Exception(_friendlySupabaseError(error));
    }
  }

  String buildJoinLink(String token) {
    final base = Uri.base;
    var path = base.path;

    if (path.isEmpty) path = '/';
    if (!path.endsWith('/')) path = '$path/';

    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
      queryParameters: {'join': token.trim()},
    ).toString();
  }

  String buildInviteLink(String token) {
    final base = Uri.base;
    var path = base.path;

    if (path.isEmpty) path = '/';
    if (!path.endsWith('/')) path = '$path/';

    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
      queryParameters: {'invite': token.trim()},
    ).toString();
  }
}
