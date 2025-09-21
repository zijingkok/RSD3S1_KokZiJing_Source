// models/procurement_request.dart

class ProcurementRequest {
  final String id;           // request_id (UUID or text)
  final String partId;       // part_id (FK)
  final int quantity;        // quantity
  final String priority;     // Low | Normal | Urgent
  final String status;       // Pending | Approved | Arrived
  final DateTime requestDate;
  final String? partName;

  const ProcurementRequest({
    required this.id,
    required this.partId,
    required this.quantity,
    required this.priority,
    required this.status,
    required this.requestDate,
    this.partName,           // nullable
  });

  bool get highPriority => priority.toLowerCase() == 'urgent';

  factory ProcurementRequest.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['request_date'];
    final qtyRaw = json['quantity'];

    return ProcurementRequest(
      id: json['request_id'] as String,
      partId: json['part_id'] as String,
      quantity: (qtyRaw is int) ? qtyRaw : int.tryParse('$qtyRaw') ?? 0,
      priority: (json['priority'] as String?) ?? 'Normal',
      status: (json['status'] as String?) ?? 'Pending',
      requestDate: dateRaw is String
          ? DateTime.parse(dateRaw)
          : (dateRaw is DateTime ? dateRaw : DateTime.fromMillisecondsSinceEpoch(0)),
      // If parts join is included, pick part_name, else null
      partName: (json['parts']?['part_name'] as String?) ?? null,
    );
  }

  Map<String, dynamic> toJson() => {
    'request_id': id,
    'part_id': partId,
    'quantity': quantity,
    'priority': priority,
    'status': status,
    'request_date': requestDate.toIso8601String(),
    if (partName != null) 'part_name': partName,
  };
}
