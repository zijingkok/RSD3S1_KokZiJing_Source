// lib/services/customer_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/customer.dart';

class CustomerService {
  CustomerService._();
  static final instance = CustomerService._();

  SupabaseClient get _sb => Supabase.instance.client;
  static const _table = 'customers';

  /// SIMPLE search + filter
  ///   - query matches full_name / phone / ic_no (IC can be typed with or without dashes)
  ///   - filter: 'all' | 'added' (recently added by created_at) | 'updated' (recently updated by updated_at)
  Future<List<Customer>> fetchCustomers({
    String query = '',
    String filter = 'all', // 'all' | 'added' | 'updated'
    int recentDays = 7,
    int limit = 100,
    int offset = 0,
  }) async {
    // Use dynamic to avoid builder type-mismatch across SDK versions
    dynamic q = _sb.from(_table).select();

    // ---- search (name/phone/ic) ----
    final raw = query.trim();
    if (raw.isNotEmpty) {
      final icDigitsOnly = raw.replaceAll(RegExp(r'\D'), '');
      q = q.or('full_name.ilike.%$raw%,phone.ilike.%$raw%,ic_no.ilike.%$icDigitsOnly%');
    }

    // ---- filter ----
    final sinceIso = DateTime.now()
        .subtract(Duration(days: recentDays))
        .toUtc()
        .toIso8601String();

    if (filter == 'added') {
      q = q.gte('created_at', sinceIso).order('created_at', ascending: false);
    } else if (filter == 'updated') {
      // updated recently OR created recently (covers null updated_at)
      q = q
          .or('updated_at.gte.$sinceIso,created_at.gte.$sinceIso')
          .order('updated_at', ascending: false);
    } else {
      q = q.order('full_name', ascending: true);
    }

    // ---- pagination ----
    if (limit > 0) q = q.range(offset, offset + limit - 1);

    final rows = await q; // returns List<dynamic>
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Customer.fromJson)
        .toList();
  }

  Future<Customer?> getById(String id) async {
    final row = await _sb.from(_table).select().eq('customer_id', id).maybeSingle();
    return row == null ? null : Customer.fromJson(row as Map<String, dynamic>);
    // if maybeSingle() returns Map already, the cast is harmless
  }

  Future<Customer> insert(Customer draft) async {
    final rows = await _sb.from(_table).insert(draft.toInsert()).select().limit(1);
    final list = (rows as List).cast<Map<String, dynamic>>();
    return Customer.fromJson(list.first);
  }

  Future<Customer> update(String id, Customer data) async {
    final rows = await _sb
        .from(_table)
        .update(data.toUpdate())
        .eq('customer_id', id)
        .select()
        .limit(1);
    final list = (rows as List).cast<Map<String, dynamic>>();
    return Customer.fromJson(list.first);
  }

  Future<void> delete(String id) async {
    await _sb.from(_table).delete().eq('customer_id', id);
  }
}

class VehicleService {
  final supa = Supabase.instance.client;

  Future<List<Vehicle>> listByCustomer(String customerId) async {
    final data = await supa
        .from('vehicles')
        .select('vehicle_id, customer_id, plate_number, make, model, year, created_at')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (data as List)
        .cast<Map<String, dynamic>>()
        .map((e) => Vehicle.fromJson(e))
        .toList();
  }

  Future<Vehicle?> getPrimary(String customerId) async {
    final data = await supa
        .from('vehicles')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return data == null ? null : Vehicle.fromJson(data as Map<String, dynamic>);
  }
}
