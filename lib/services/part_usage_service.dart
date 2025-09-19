// services/part_usage_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/part_usage_event.dart';

class PartUsageService {
  final SupabaseClient _client;

  PartUsageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<PartUsageEvent>> fetchUsageHistory(String partId) async {
    final res = await _client
        .from('part_usage')
        .select('usage_date, quantity, department, work_orders(code), staff(full_name)')
        .eq('part_id', partId)
        .order('usage_date', ascending: false);

    final list = (res as List)
        .map((e) => PartUsageEvent.fromSupabase(e as Map<String, dynamic>))
        .toList();

    return list;
  }

  Future<Map<String, int>> fetchUsageSummary(String partId) async {
    final res = await _client
        .from('part_usage')
        .select('quantity')
        .eq('part_id', partId);

    int totalIn = 0;
    int totalOut = 0;

    for (final row in (res as List)) {
      final raw = row['quantity'];
      final qty = raw is int ? raw : int.tryParse('$raw') ?? 0;
      if (qty >= 0) {
        totalIn += qty;
      } else {
        totalOut += -qty;
      }
    }

    return {'in': totalIn, 'out': totalOut};
  }
}
