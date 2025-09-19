class Part {
  final String id;
  final String name;
  final String number;
  final int stockQuantity;
  final String location;
  final int reorderLevel;


  Part({
    required this.id,
    required this.name,
    required this.number,
    required this.stockQuantity,
    required this.location,
    required this.reorderLevel,

  });

  bool get lowStock  => stockQuantity <= reorderLevel;

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      id: json['part_id'] as String,
      name: json['part_name'] as String,
      number: json['part_number'] ?? '',
      stockQuantity: json['stock_quantity'] as int,
      location: json['location'] ?? '',
      reorderLevel: json['reorder_level'] ?? 0,
    );
  }
}
