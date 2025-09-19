// services/procurement_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/procurement_request_item.dart';

class ProcurementService {
  final SupabaseClient _client;
  ProcurementService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Create a new procurement request
  Future<void> createRequest({
    required String partId,
    required int quantity,
    required String priority, // 'Low' | 'Normal' | 'Urgent'
    String? notes,            // only use if you add `notes` column
  }) async {
    await _client.from('procurement_requests').insert({
      'part_id': partId,
      'quantity': quantity,
      'priority': priority,
      'status': 'Pending',
      // 'notes': notes,
    });
  }

  /// Fetch parts for dropdowns
  Future<List<Map<String, dynamic>>> fetchParts() async {
    final res = await _client
        .from('parts')
        .select('part_id, part_name')
        .order('part_name');

    return List<Map<String, dynamic>>.from(res as List);
  }

  /// Optional: map {part_id: part_name} (used for realtime stream join workaround)
  Future<Map<String, String>> _partsNameMap() async {
    final parts = await fetchParts();
    return {
      for (final p in parts)
        (p['part_id'] as String): (p['part_name'] as String)
    };
  }

  /// Fetch requests with server-side join for part name (good for normal reads)
  Future<List<ProcurementRequest>> fetchRequests() async {
    final res = await _client
        .from('procurement_requests')
        .select(
      'request_id, part_id, quantity, request_date, priority, status, parts(part_name)',
    )
        .order('request_date', ascending: false);

    return (res as List)
        .map((row) =>
        ProcurementRequest.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Stream requests. Realtime doesn't support joins → enrich client-side.
  Stream<List<ProcurementRequest>> streamRequests() {
    return _client
        .from('procurement_requests')
        .stream(primaryKey: ['request_id'])
        .order('request_date', ascending: false)
        .asyncMap((rows) async {
      final nameMap = await _partsNameMap();
      return rows.map((row) {
        final map = Map<String, dynamic>.from(row);
        map['parts'] = {
          'part_name': nameMap[map['part_id'] as String] ?? 'Unknown Part'
        };
        return ProcurementRequest.fromJson(map);
      }).toList();
    });
  }

  /// Fetch raw rows (no join) if you ever need the base model
  Future<List<ProcurementRequest>> fetchRawRequests() async {
    final res = await _client
        .from('procurement_requests')
        .select('request_id, part_id, quantity, request_date, priority, status')
        .order('request_date', ascending: false);

    return (res as List)
        .map((row) =>
        ProcurementRequest.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Update status (e.g., Pending → Approved → Ordered)
  Future<void> updateStatus({
    required String requestId,
    required String status, // 'Pending' | 'Approved' | 'Ordered'
  }) async {
    await _client
        .from('procurement_requests')
        .update({'status': status})
        .eq('request_id', requestId);
  }
}
