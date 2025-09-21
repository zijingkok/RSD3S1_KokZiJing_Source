// models/work_order.dart
import 'mechanic.dart';

enum WorkOrderStatus { unassigned, scheduled, inProgress, onHold, completed }
enum WorkOrderPriority { low, normal, high, urgent }

WorkOrderStatus _statusFromString(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'scheduled': return WorkOrderStatus.scheduled;
    case 'in_progress':
    case 'inprogress': return WorkOrderStatus.inProgress;
    case 'on_hold':
    case 'onhold': return WorkOrderStatus.onHold;
    case 'completed': return WorkOrderStatus.completed;
    default: return WorkOrderStatus.unassigned;
  }
}

String statusToString(WorkOrderStatus s) {
  switch (s) {
    case WorkOrderStatus.scheduled: return 'scheduled';
    case WorkOrderStatus.inProgress: return 'in_progress';
    case WorkOrderStatus.onHold: return 'on_hold';
    case WorkOrderStatus.completed: return 'completed';
    case WorkOrderStatus.unassigned: return 'unassigned';
  }
}

WorkOrderPriority _priorityFromString(String? s) {
  switch ((s ?? 'normal').toLowerCase()) {
    case 'low': return WorkOrderPriority.low;
    case 'high': return WorkOrderPriority.high;
    case 'urgent': return WorkOrderPriority.urgent;
    default: return WorkOrderPriority.normal;
  }
}

String _priorityToString(WorkOrderPriority p) {
  switch (p) {
    case WorkOrderPriority.low: return 'low';
    case WorkOrderPriority.normal: return 'normal';
    case WorkOrderPriority.high: return 'high';
    case WorkOrderPriority.urgent: return 'urgent';
  }
}

/// Utility: Supabase `time` (e.g. "10:30:00") -> Duration from midnight.
Duration? _parsePgTime(String? hhmmss) {
  if (hhmmss == null || hhmmss.isEmpty) return null;
  final parts = hhmmss.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  final s = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
  return Duration(hours: h, minutes: m, seconds: s);
}

DateTime? _parseTs(dynamic v) => v == null ? null : DateTime.parse(v.toString());
DateTime? _parseDate(dynamic v) => v == null ? null : DateTime.parse(v.toString());

class WorkOrder {
  final String workOrderId;         // uuid
  final String code;                // text
  final String? vehicleId;          // uuid
  final String? customerId;         // uuid
  final String title;               // text
  final WorkOrderStatus status;     // text
  final WorkOrderPriority priority; // text
  final DateTime? scheduledDate;    // date
  final Duration? scheduledTime;    // time (HH:mm:ss)
  final double? estimatedHours;     // numeric
  final String? assignedMechanicId; // uuid
  final String? notes;              // text
  final String? serviceId;          // uuid
  final DateTime? createdAt;        // timestamptz
  final DateTime? updatedAt;        // timestamptz

  /// Convenience: combine scheduledDate + scheduledTime -> DateTime
  DateTime? get scheduledStart {
    if (scheduledDate == null) return null;
    final base = DateTime(scheduledDate!.year, scheduledDate!.month, scheduledDate!.day);
    if (scheduledTime == null) return base;
    return base.add(scheduledTime!);
  }

  WorkOrder({
    required this.workOrderId,
    required this.code,
    required this.title,
    this.vehicleId,
    this.customerId,
    this.status = WorkOrderStatus.unassigned,
    this.priority = WorkOrderPriority.normal,
    this.scheduledDate,
    this.scheduledTime,
    this.estimatedHours,
    this.assignedMechanicId,
    this.notes,
    this.serviceId,
    this.createdAt,
    this.updatedAt,
  });



  factory WorkOrder.fromMap(Map<String, dynamic> m) {
    return WorkOrder(
      workOrderId: (m['work_order_id'] ?? m['id']).toString(),
      code: (m['code'] ?? '').toString(),
      vehicleId: m['vehicle_id']?.toString(),
      customerId: m['customer_id']?.toString(),
      title: (m['title'] ?? '').toString(),
      status: _statusFromString(m['status']?.toString()),
      priority: _priorityFromString(m['priority']?.toString()),
      scheduledDate: _parseDate(m['scheduled_date']),
      scheduledTime: _parsePgTime(m['scheduled_time']?.toString()),
      estimatedHours: m['estimated_hours'] == null ? null : double.tryParse(m['estimated_hours'].toString()),
      assignedMechanicId: m['assigned_mechanic_id']?.toString(),
      notes: m['notes']?.toString(),
      serviceId: m['service_id']?.toString(),
      createdAt: _parseTs(m['created_at']),
      updatedAt: _parseTs(m['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    // NOTE: we persist the canonical DB column names to match your schema.
    return {
      'work_order_id': workOrderId,
      'code': code,
      'vehicle_id': vehicleId,
      'customer_id': customerId,
      'title': title,
      'status': statusToString(status),
      'priority': _priorityToString(priority),
      'scheduled_date': scheduledDate?.toIso8601String(),
      // Postgres `time` expects "HH:MM:SS" string; keep this null to avoid bad casts.
      'scheduled_time': scheduledTime == null
          ? null
          : '${scheduledTime!.inHours.toString().padLeft(2, '0')}:'
          '${(scheduledTime!.inMinutes % 60).toString().padLeft(2, '0')}:'
          '${(scheduledTime!.inSeconds % 60).toString().padLeft(2, '0')}',
      'estimated_hours': estimatedHours,
      'assigned_mechanic_id': assignedMechanicId,
      'notes': notes,
      'service_id': serviceId,
    };
  }
}
