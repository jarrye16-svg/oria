import '../models/house.dart';
import 'supabase_service.dart';

class HouseService {
  Future<List<House>> getMyHouses() async {
    final data = await supabase.rpc('get_my_houses');
    final rows = (data as List).cast<dynamic>();
    return rows.map((row) => House.fromMap(Map<String, dynamic>.from(row as Map))).toList();
  }

  Future<String> createHouseWithDefaults(String name) async {
    final data = await supabase.rpc(
      'create_house_with_defaults',
      params: {'p_house_name': name.trim()},
    );

    return data as String;
  }

  Future<String> joinHouseWithCode({
    required String houseName,
    required String code,
  }) async {
    final data = await supabase.rpc(
      'join_house_with_code',
      params: {
        'p_house_name': houseName.trim(),
        'p_code': code.trim(),
      },
    );

    return data as String;
  }
}
