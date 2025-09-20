// models/work_order_assignment.dart
DateTime? _ts(dynamic v) => v == null ? null : DateTime.parse(v.toString());

class WorkOrderAssignment {
  final String id;              // uuid
  final String workOrderId;     // uuid
  final String? oldMechanicId;  // uuid
  final String? newMechanicId;  // uuid
  final DateTime? oldTime;      // timestamptz
  final DateTime? newTime;      // timestamptz
  final String? changedBy;      // uuid
  final DateTime? changedAt;    // timestamptz

  WorkOrderAssignment({
    required this.id,
    required this.workOrderId,
    this.oldMechanicId,
    this.newMechanicId,
    this.oldTime,
    this.newTime,
    this.changedBy,
    this.changedAt,
  });

  factory WorkOrderAssignment.fromMap(Map<String, dynamic> m) => WorkOrderAssignment(
    id: (m['id'] ?? m['work_order_assignment_id']).toString(),
    workOrderId: (m['work_order_id'] ?? '').toString(),
    oldMechanicId: m['old_mechanic_id']?.toString(),
    newMechanicId: m['new_mechanic_id']?.toString(),
    oldTime: _ts(m['old_time']),
    newTime: _ts(m['new_time']),
    changedBy: m['changed_by']?.toString(),
    changedAt: _ts(m['changed_at']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'work_order_id': workOrderId,
    'old_mechanic_id': oldMechanicId,
    'new_mechanic_id': newMechanicId,
    'old_time': oldTime?.toIso8601String(),
    'new_time': newTime?.toIso8601String(),
    'changed_by': changedBy,
    'changed_at': changedAt?.toIso8601String(),
  };
}
