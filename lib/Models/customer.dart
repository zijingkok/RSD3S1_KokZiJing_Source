// lib/Models/customer.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class Customer {
  final String id;              // customer_id
  final String fullName;        // full_name
  final String? icNo;           // ic_no
  final String? phone;          // phone
  final String? email;          // email
  final String? gender;         // gender
  final String? address;        // address
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Related vehicles (optional; empty when not fetched with a join)
  final List<Vehicle> vehicles;

  Customer({
    required this.id,
    required this.fullName,
    this.icNo,
    this.phone,
    this.email,
    this.gender,
    this.address,
    this.createdAt,
    this.updatedAt,
    this.vehicles = const [],
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    DateTime? _ts(dynamic v) => v == null ? null : DateTime.parse(v as String);
    final rawVehicles = (json['vehicles'] as List?) ?? const [];
    return Customer(
      id: json['customer_id'] as String,
      fullName: (json['full_name'] ?? '').toString(),
      icNo: json['ic_no'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      createdAt: _ts(json['created_at']),
      updatedAt: _ts(json['updated_at']),
      vehicles: rawVehicles
          .whereType<Map<String, dynamic>>()
          .map(Vehicle.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toInsert() => {
    'full_name': fullName,
    'ic_no': icNo,
    'phone': phone,
    'email': email,
    'gender': gender,
    'address': address,
  };

  Map<String, dynamic> toUpdate() => {
    'full_name': fullName,
    'ic_no': icNo,
    'phone': phone,
    'email': email,
    'gender': gender,
    'address': address,
    'updated_at': DateTime.now().toIso8601String(),
  };
}

/// --- Vehicle model (same file) ---
class Vehicle {
  final String id;              // vehicle_id
  final String customerId;      // customer_id
  final String plateNumber;     // plate_number
  final String? vin;
  final String? make;           // brand
  final String? model;
  final int? year;
  final int? mileage;
  final DateTime? purchaseDate; // date
  final String? status;
  final String? imageUrl;
  final String? vehicleImageUrl;
  final DateTime? createdAt;

  Vehicle({
    required this.id,
    required this.customerId,
    required this.plateNumber,
    this.vin,
    this.make,
    this.model,
    this.year,
    this.mileage,
    this.purchaseDate,
    this.status,
    this.imageUrl,
    this.vehicleImageUrl,
    this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    int? _toInt(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    DateTime? _toDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return Vehicle(
      id: (json['vehicle_id'] ?? json['id']).toString(),
      customerId: (json['customer_id'] ?? '').toString(),
      plateNumber: (json['plate_number'] ?? '').toString(),
      vin: json['vin'] as String?,
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: _toInt(json['year']),
      mileage: _toInt(json['mileage']),
      purchaseDate: _toDate(json['purchase_date']),
      status: json['status'] as String?,
      imageUrl: json['image_url'] as String?,
      vehicleImageUrl: json['vehicle_image_url'] as String?,
      createdAt: _toDate(json['created_at']),
    );
  }
}

/// --- Optional: one-call fetch (customer + vehicles) ---
class CustomerRepo {
  final supa = Supabase.instance.client;

  /// Requires a FK from vehicles.customer_id -> customers.customer_id
  Future<Customer?> getWithVehicles(String customerId) async {
    final data = await supa
        .from('customers')
        .select('''
          customer_id, full_name, ic_no, phone, email, gender, address, created_at, updated_at,
          vehicles (vehicle_id, customer_id, plate_number, make, model, year, created_at)
        ''')
        .eq('customer_id', customerId)
        .single();

    return data == null ? null : Customer.fromJson(data as Map<String, dynamic>);
  }

  /// Or list only the plate + make if you prefer a lightweight call
  Future<List<Vehicle>> listPlates(String customerId) async {
    final data = await supa
        .from('vehicles')
        .select('vehicle_id, customer_id, plate_number, make, created_at')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
