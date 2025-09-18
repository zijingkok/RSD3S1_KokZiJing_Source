// services/part_usage_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PartUsageEvent {
  final DateTime dateTime;
  final int deltaUnits;
  final String workOrder;
  final String mechanic;
  final String department;

  PartUsageEvent({
    required this.dateTime,
    required this.deltaUnits,
    required this.workOrder,
    required this.mechanic,
    required this.department,
  });

  factory PartUsageEvent.fromJson(Map<String, dynamic> json) {
    return PartUsageEvent(
      dateTime: DateTime.parse(json['usage_date']),
      deltaUnits: (json['quantity'] as int?) ?? 0,
      workOrder: json['work_orders']?['code'] ?? 'N/A',
      mechanic: json['staff']?['full_name'] ?? 'Unknown',
      department: json['department'] ?? '-',
    );
  }
}

class PartUsageService {
  final _client = Supabase.instance.client;

  Future<List<PartUsageEvent>> fetchUsageHistory(String partId) async {
    final res = await _client
        .from('part_usage')
        .select('usage_date, quantity, department, '
        'work_orders(code), staff(full_name)')
        .eq('part_id', partId)
        .order('usage_date', ascending: false);

    return (res as List<dynamic>)
        .map((e) => PartUsageEvent.fromJson(e))
        .toList();
  }

  Future<Map<String, int>> fetchUsageSummary(String partId) async {
    final res = await _client
        .from('part_usage')
        .select('quantity')
        .eq('part_id', partId);

    int totalIn = 0;
    int totalOut = 0;

    for (final row in res) {
      final qty = row['quantity'] as int? ?? 0;
      if (qty >= 0) {
        totalIn += qty;
      } else {
        totalOut += qty.abs();
      }
    }

    return {
      'in': totalIn,
      'out': totalOut,
    };
  }
}
