import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/interaction.dart';

class InteractionService {
  InteractionService._();
  static final instance = InteractionService._();

  SupabaseClient get _sb => Supabase.instance.client;
  static const _table = 'interactions';

  /// Basic list (just interaction fields) – unchanged
  Future<List<Interaction>> listByCustomer(String customerId) async {
    final rows = await _sb
        .from(_table)
        .select()
        .eq('customer_id', customerId)
        .order('interaction_date', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Interaction.fromJson)
        .toList();
  }

  /// ✅ List interactions *with* joined staff (so you can display staff name in history).
  /// Note: your staff table uses `full_name`.
  ///
  /// Example row:
  /// {
  ///   "interaction_id": "...",
  ///   "staff_id": "...",
  ///   "staff": { "full_name": "Alice Tan" }
  /// }
  Future<List<Map<String, dynamic>>> listByCustomerWithStaff(
      String customerId,
      ) async {
    final rows = await _sb
        .from(_table)
        .select('''
          interaction_id,
          customer_id,
          staff_id,
          channel,
          description,
          interaction_date,
          created_at,
          staff:staff_id ( staff_id, full_name )
        ''')
        .eq('customer_id', customerId)
        .order('interaction_date', ascending: false);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// ✅ Staff options for dropdown (id + display name).
  /// Filters to active staff and orders by full name.
  Future<List<Map<String, String>>> fetchStaffOptions({String? search}) async {
    final query = _sb
        .from('staff')
        .select('staff_id, full_name')
        .eq('active', true)
        .order('full_name', ascending: true);

    if (search != null && search.trim().isNotEmpty) {
      query.ilike('full_name', '%${search.trim()}%');
    }

    final rows = await query;

    return (rows as List)
        .map((e) => {
      'staff_id': (e['staff_id'] ?? '').toString(),
      'full_name': (e['full_name'] ?? '').toString(),
    })
        .where((e) => e['staff_id']!.isNotEmpty)
        .toList();
  }

  /// Insert and return the created row (basic)
  Future<Interaction> insert(Interaction draft) async {
    final rows = await _sb
        .from(_table)
        .insert(draft.toInsert())
        .select()
        .limit(1);

    return Interaction.fromJson((rows as List).first as Map<String, dynamic>);
  }

  /// Insert and return with joined staff (handy if you want the name immediately)
  Future<Map<String, dynamic>> insertWithStaff(Interaction draft) async {
    final row = await _sb
        .from(_table)
        .insert(draft.toInsert())
        .select('''
          interaction_id, customer_id, staff_id, channel, description, interaction_date, created_at,
          staff:staff_id ( staff_id, full_name )
        ''')
        .single();

    return row as Map<String, dynamic>;
  }

  /// Update and return the updated row (basic)
  Future<Interaction> update(String id, Interaction data) async {
    final rows = await _sb
        .from(_table)
        .update(data.toUpdate())
        .eq('interaction_id', id)
        .select()
        .limit(1);

    return Interaction.fromJson((rows as List).first as Map<String, dynamic>);
  }

  /// Update and return with joined staff (for history refresh with name)
  Future<Map<String, dynamic>> updateWithStaff(String id, Interaction data) async {
    final row = await _sb
        .from(_table)
        .update(data.toUpdate())
        .eq('interaction_id', id)
        .select('''
          interaction_id, customer_id, staff_id, channel, description, interaction_date, created_at,
          staff:staff_id ( staff_id, full_name )
        ''')
        .single();

    return row as Map<String, dynamic>;
  }
}

extension on PostgrestTransformBuilder<PostgrestList> {
  void ilike(String s, String t) {}
}
