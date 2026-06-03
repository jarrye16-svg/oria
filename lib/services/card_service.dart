import '../models/oria_card.dart';
import 'supabase_service.dart';

class CardService {
  Future<List<OriaCardModel>> getCards(String houseId) async {
    final data = await supabase
        .from('financial_cards')
        .select()
        .eq('house_id', houseId)
        .order('is_active', ascending: false)
        .order('name');

    return (data as List)
        .map((row) => OriaCardModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> deleteCard(String id) async {
    await supabase.from('financial_cards').delete().eq('id', id);
  }

  Future<void> upsertCard({
    String? id,
    required String houseId,
    required String name,
    required String ownerName,
    required String bankName,
    int? closingDay,
    int? dueDay,
    double? limitAmount,
    bool isActive = true,
  }) async {
    // name = bandeira/cartao exibido no app. Mantemos o nome da coluna para nao quebrar a base.
    final payload = {
      'house_id': houseId,
      'name': name.trim(),
      'owner_name': ownerName.trim().isEmpty ? 'Casa' : ownerName.trim(),
      'bank_name': bankName.trim(),
      'closing_day': closingDay,
      'due_day': dueDay,
      'limit_amount': limitAmount,
      'is_active': isActive,
    };

    if (id == null) {
      await supabase.from('financial_cards').insert(payload);
    } else {
      await supabase.from('financial_cards').update(payload).eq('id', id);
    }
  }
}
