import 'package:supabase_flutter/supabase_flutter.dart';

class ProcurementRequestItem {
  final String id;         // request_id
  final String partId;     // part_id
  final String partName;   // parts.part_name
  final int qty;           // quantity
  final DateTime date;     // request_date
  final String priority;   // Low | Normal | Urgent
  final String status;     // Pending | Approved | Ordered

  bool get highPriority => priority.toLowerCase() == 'urgent';

  ProcurementRequestItem({
    required this.id,
    required this.partId,
    required this.partName,
    required this.qty,
    required this.date,
    required this.priority,
    required this.status,
  });

  factory ProcurementRequestItem.fromJson(Map<String, dynamic> json) {
    return ProcurementRequestItem(
      id: json['request_id'] as String,
      partId: json['part_id'] as String,
      partName: (json['parts']?['part_name'] as String?) ?? 'Unknown Part',
      qty: json['quantity'] as int,
      date: DateTime.parse(json['request_date'] as String),
      priority: json['priority'] as String? ?? 'Normal',
      status: json['status'] as String? ?? 'Pending',
    );
  }
}

class ProcurementService {
  final _client = Supabase.instance.client;

  /// Create a new procurement request
  Future<void> createRequest({
    required String partId,
    required int quantity,
    required String priority, // 'Low' | 'Normal' | 'Urgent'
    String? notes,            // only use if you add notes column
  }) async {
    await _client.from('procurement_requests').insert({
      'part_id': partId,
      'quantity': quantity,
      'priority': priority,
      'status': 'Pending',
      // 'notes': notes, // add if column exists
    });
  }

  /// Fetch all parts for dropdowns
  Future<List<Map<String, dynamic>>> fetchParts() async {
    final res = await _client
        .from('parts')
        .select('part_id, part_name')
        .order('part_name');
    return List<Map<String, dynamic>>.from(res);
  }

  /// Fetch all procurement requests with joined part names
  Future<List<ProcurementRequestItem>> fetchRequests() async {
    final res = await _client
        .from('procurement_requests')
        .select('request_id, part_id, quantity, request_date, priority, status, parts(part_name)')
        .order('request_date', ascending: false);

    return (res as List<dynamic>)
        .map((row) => ProcurementRequestItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Update status of a request (e.g. Pending → Approved → Ordered)
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
