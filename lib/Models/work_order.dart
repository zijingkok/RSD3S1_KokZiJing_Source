// models/work_order.dart
class WorkOrder {
  final String? id;
  final String code;
  final String vehicleId;
  final String customerId;
  final String title;
  final String status;
  final String priority;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final double? estimatedHours;
  final String? assignedMechanicId;
  final String? notes;
  final String? serviceId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkOrder({
    this.id,
    required this.code,
    required this.vehicleId,
    required this.customerId,
    required this.title,
    required this.status,
    required this.priority,
    this.scheduledDate,
    this.scheduledTime,
    this.estimatedHours,
    this.assignedMechanicId,
    this.notes,
    this.serviceId,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from JSON (Supabase response)
  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['work_order_id'],
      code: json['code'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? 'Unassigned',
      priority: json['priority'] ?? 'Normal',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      scheduledTime: json['scheduled_time'],
      estimatedHours: json['estimated_hours']?.toDouble(),
      assignedMechanicId: json['assigned_mechanic_id'],
      notes: json['notes'],
      serviceId: json['service_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'work_order_id': id,
      'code': code,
      'vehicle_id': vehicleId,
      'customer_id': customerId,
      'title': title,
      'status': status,
      'priority': priority,
      'scheduled_date': scheduledDate?.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime,
      'estimated_hours': estimatedHours,
      'assigned_mechanic_id': assignedMechanicId,
      'notes': notes,
      'service_id': serviceId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // For insert operations (without id, created_at, updated_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'code': code,
      'vehicle_id': vehicleId,
      'customer_id': customerId,
      'title': title,
      'status': status,
      'priority': priority,
      'scheduled_date': scheduledDate?.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime,
      'estimated_hours': estimatedHours,
      'assigned_mechanic_id': assignedMechanicId,
      'notes': notes,
      'service_id': serviceId,
    };
  }

  // Create copy with updated fields
  WorkOrder copyWith({
    String? id,
    String? code,
    String? vehicleId,
    String? customerId,
    String? title,
    String? status,
    String? priority,
    DateTime? scheduledDate,
    String? scheduledTime,
    double? estimatedHours,
    String? assignedMechanicId,
    String? notes,
    String? serviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkOrder(
      id: id ?? this.id,
      code: code ?? this.code,
      vehicleId: vehicleId ?? this.vehicleId,
      customerId: customerId ?? this.customerId,
      title: title ?? this.title,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      assignedMechanicId: assignedMechanicId ?? this.assignedMechanicId,
      notes: notes ?? this.notes,
      serviceId: serviceId ?? this.serviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get formatted status display text
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'unassigned':
        return 'Unassigned';
      case 'assigned':
        return 'Assigned';
      case 'in-progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'on-hold':
        return 'On Hold';
      default:
        return status;
    }
  }

  // Get formatted priority display text
  String get priorityDisplay {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }

  @override
  String toString() {
    return 'WorkOrder(id: $id, code: $code, title: $title, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkOrder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}