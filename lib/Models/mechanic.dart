// models/mechanic.dart  (represents rows from "staff")
class Mechanic {
  String id;                   // staff_id
  String name;                 // full_name
  String? role;                // role (Mechanic / Manager / Advisor)
  int dailyCapacityHours;      // int4
  bool active;                 // bool

  Mechanic({
    required this.id,
    required this.name,
    this.role,
    this.dailyCapacityHours = 8,
    this.active = true,
  });

  factory Mechanic.fromMap(Map<String, dynamic> m) => Mechanic(
    id: (m['staff_id'] ?? m['id'] ?? '').toString(),
    name: (m['full_name'] ?? m['name'] ?? '').toString(),
    role: m['role']?.toString(),
    dailyCapacityHours: m['daily_capacity_hours'] is int
        ? (m['daily_capacity_hours'] as int)
        : int.tryParse(m['daily_capacity_hours']?.toString() ?? '') ?? 8,
    active: m['active'] == null ? true : (m['active'] == true || m['active'].toString() == 'true'),
  );

  Map<String, dynamic> toMap() => {
    'staff_id': id,
    'full_name': name,
    'role': role,
    'daily_capacity_hours': dailyCapacityHours,
    'active': active,
  };
}
