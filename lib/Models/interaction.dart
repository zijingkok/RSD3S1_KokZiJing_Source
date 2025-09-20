// lib/Models/interaction.dart

class Staff {
  final String id;                 // staff_id (uuid)
  final String fullName;           // full_name
  final String? role;              // role
  final int? dailyCapacityHours;   // daily_capacity_hours
  final bool active;               // active
  final DateTime? createdAt;       // created_at

  Staff({
    required this.id,
    required this.fullName,
    this.role,
    this.dailyCapacityHours,
    this.active = true,
    this.createdAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    int? _toInt(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    DateTime? _ts(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return Staff(
      id: (json['staff_id'] ?? json['id']).toString(),
      fullName: (json['full_name'] ?? '').toString(),
      role: json['role'] as String?,
      dailyCapacityHours: _toInt(json['daily_capacity_hours']),
      active: json['active'] is bool
          ? json['active'] as bool
          : (json['active']?.toString() == 'true'),
      createdAt: _ts(json['created_at']),
    );
  }
}

class Interaction {
  final String id;                 // interaction_id
  final String customerId;         // customer_id (FK)
  final String? staffId;           // staff_id (optional)
  final String channel;            // channel
  final String description;        // description
  final DateTime interactionDate;  // interaction_date
  final DateTime? createdAt;       // created_at (server default)

  /// Optional nested staff object when we SELECT with a join
  final Staff? staff;

  Interaction({
    required this.id,
    required this.customerId,
    this.staffId,
    required this.channel,
    required this.description,
    required this.interactionDate,
    this.createdAt,
    this.staff,
  });

  factory Interaction.fromJson(Map<String, dynamic> json) {
    DateTime _ts(dynamic v) => DateTime.parse(v as String);
    DateTime? _tsOrNull(dynamic v) =>
        v == null ? null : DateTime.parse(v as String);

    // Handle nested join: `staff:staff_id (...)` will appear as `staff`
    final Map<String, dynamic>? staffJson =
    json['staff'] is Map<String, dynamic> ? json['staff'] as Map<String, dynamic> : null;

    return Interaction(
      id: (json['interaction_id'] ?? json['id']).toString(),
      customerId: (json['customer_id'] ?? '').toString(),
      staffId: json['staff_id'] as String?,
      channel: (json['channel'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      interactionDate: _ts(json['interaction_date']),
      createdAt: _tsOrNull(json['created_at']),
      staff: staffJson == null ? null : Staff.fromJson(staffJson),
    );
  }

  Map<String, dynamic> toInsert() => {
    'customer_id': customerId,
    if (staffId != null) 'staff_id': staffId,
    'channel': channel,
    'description': description,
    'interaction_date': interactionDate.toIso8601String(),
  };

  Map<String, dynamic> toUpdate() => {
    if (staffId != null) 'staff_id': staffId,
    'channel': channel,
    'description': description,
    'interaction_date': interactionDate.toIso8601String(),
  };

  /// Handy getter for UI
  String get staffName => staff?.fullName ?? '';
}
