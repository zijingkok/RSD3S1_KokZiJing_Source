class ProcurementRequest {
  final String id;
  final String partId;
  final int quantity;
  final String priority;
  final String status;
  final DateTime requestDate;

  ProcurementRequest({
    required this.id,
    required this.partId,
    required this.quantity,
    required this.priority,
    required this.status,
    required this.requestDate,
  });

  factory ProcurementRequest.fromJson(Map<String, dynamic> json) {
    return ProcurementRequest(
      id: json['request_id'] as String,
      partId: json['part_id'] as String,
      quantity: json['quantity'] as int,
      priority: json['priority'] ?? 'Normal',
      status: json['status'] ?? 'Pending',
      requestDate: DateTime.parse(json['request_date']),
    );
  }
}
