// models/vehicle.dart
class Vehicle {
  final String? id;
  final String vin;
  final String make;
  final String model;
  final String plateNumber;
  final int year;
  final int mileage;
  final DateTime? purchaseDate;
  final String status;
  final String? imageUrl;
  final String? customerId; // Foreign key to customers table
  final String? vehicleImageUrl; // New field for vehicle image
  final DateTime? createdAt;

  // Customer details (populated from join)
  final String? customerName;
  final String? customerIc;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerGender;
  final String? customerAddress;

  Vehicle({
    this.id,
    required this.vin,
    required this.make,
    required this.model,
    required this.plateNumber,
    required this.year,
    required this.mileage,
    this.purchaseDate,
    required this.status,
    this.imageUrl,
    this.customerId,
    this.vehicleImageUrl,
    this.createdAt,
    this.customerName,
    this.customerIc,
    this.customerPhone,
    this.customerEmail,
    this.customerGender,
    this.customerAddress,
  });

  // Convert from JSON (Supabase response)
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // Debug prints
    print('Vehicle.fromJson called with: $json');

    // Handle customer data from join
    Map<String, dynamic>? customerData;
    if (json['customers'] != null) {
      if (json['customers'] is List && (json['customers'] as List).isNotEmpty) {
        customerData = json['customers'][0];
      } else if (json['customers'] is Map) {
        customerData = json['customers'];
      }
    }

    print('Customer data extracted: $customerData');

    return Vehicle(
      id: json['vehicle_id'] ?? json['id'], // Handle both column names
      vin: json['vin'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      year: json['year'] ?? 0,
      mileage: json['mileage'] ?? 0,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : null,
      status: json['status'] ?? 'active',
      imageUrl: json['image_url'],
      customerId: json['customer_id'],
      vehicleImageUrl: json['vehicle_image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      // Customer details from join - handle both direct and nested access
      customerName: customerData?['full_name'] ?? json['customer_name'],
      customerIc: customerData?['ic_no'] ?? json['customer_ic'],
      customerPhone: customerData?['phone'] ?? json['customer_phone'],
      customerEmail: customerData?['email'] ?? json['customer_email'],
      customerGender: customerData?['gender'] ?? json['customer_gender'],
      customerAddress: customerData?['address'] ?? json['customer_address'],
    );
  }

  // Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'vehicle_id': id,
      'vin': vin,
      'make': make,
      'model': model,
      'plate_number': plateNumber,
      'year': year,
      'mileage': mileage,
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
      'status': status,
      'image_url': imageUrl,
      'customer_id': customerId,
      'vehicle_image_url': vehicleImageUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  // For insert operations (without id and created_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'vin': vin,
      'make': make,
      'model': model,
      'plate_number': plateNumber,
      'year': year,
      'mileage': mileage,
      'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
      'status': status,
      'image_url': imageUrl,
      'customer_id': customerId,
      'vehicle_image_url': vehicleImageUrl,
    };
  }

  // Create copy with updated fields
  Vehicle copyWith({
    String? id,
    String? vin,
    String? make,
    String? model,
    String? plateNumber,
    int? year,
    int? mileage,
    DateTime? purchaseDate,
    String? status,
    String? imageUrl,
    String? customerId,
    String? vehicleImageUrl,
    DateTime? createdAt,
    String? customerName,
    String? customerIc,
    String? customerPhone,
    String? customerEmail,
    String? customerGender,
    String? customerAddress,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vin: vin ?? this.vin,
      make: make ?? this.make,
      model: model ?? this.model,
      plateNumber: plateNumber ?? this.plateNumber,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      customerId: customerId ?? this.customerId,
      vehicleImageUrl: vehicleImageUrl ?? this.vehicleImageUrl,
      createdAt: createdAt ?? this.createdAt,
      customerName: customerName ?? this.customerName,
      customerIc: customerIc ?? this.customerIc,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      customerGender: customerGender ?? this.customerGender,
      customerAddress: customerAddress ?? this.customerAddress,
    );
  }

  // Get formatted display name
  String get displayName {
    return '$make $model $plateNumber';
  }

  // Get owner display name
  String get ownerDisplayName {
    if (customerName != null && customerName!.isNotEmpty) {
      return '$customerName ($customerIc)';
    }
    return customerIc ?? 'Unknown Owner';
  }

  @override
  String toString() {
    return 'Vehicle(id: $id, plateNumber: $plateNumber, make: $make, model: $model)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}