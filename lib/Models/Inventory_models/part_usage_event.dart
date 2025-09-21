// models/part_usage_event.dart
class PartUsageEvent {
  // The timestamp when the part usage happened
  final DateTime dateTime;
  final int deltaUnits;
  final String workOrder;
  final String mechanic;
  final String department;

  //Constructor - all fields required
  const PartUsageEvent({
    required this.dateTime,
    required this.deltaUnits,
    required this.workOrder,
    required this.mechanic,
    required this.department,
  });


  /// Build from Supabase row (including joined tables)
  factory PartUsageEvent.fromSupabase(Map<String, dynamic> json) {
    // Be defensive on types/nulls coming from PostgREST
    final usageDate = json['usage_date'];
    final quantity = json['quantity'];

    return PartUsageEvent(
      dateTime: usageDate is String
          ? DateTime.parse(usageDate)
          : (usageDate is DateTime ? usageDate : DateTime.fromMillisecondsSinceEpoch(0)),
      // Ensure quantity is always an integer (fallback 0 if invalid)
      deltaUnits: quantity is int ? quantity : int.tryParse('$quantity') ?? 0,


      workOrder: (json['work_orders'] as Map?)?['code']?.toString() ?? 'N/A',
      mechanic: (json['staff'] as Map?)?['full_name']?.toString() ?? 'Unknown',
      department: json['department']?.toString() ?? '-',
    );
  }

  // Convert the partusage object
  Map<String, dynamic> toJson() => {
    'usage_date': dateTime.toIso8601String(),
    'quantity': deltaUnits,
    'work_order': workOrder,
    'mechanic': mechanic,
    'department': department,
  };
}
