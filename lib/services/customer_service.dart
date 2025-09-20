import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/customer.dart';

class CustomerService {
  CustomerService._();
  static final instance = CustomerService._();

  SupabaseClient get _sb => Supabase.instance.client;
  static const _table = 'customers';

  Future<List<Customer>> fetchCustomers({String query = '', int limit = 100, int offset = 0}) async {
    final table = _sb.from(_table);
    var q = table.select();
    if (query.trim().isNotEmpty) {
      q = q.ilike('full_name', '%${query.trim()}%');
    }


    final rows = await q;
    return (rows as List).cast<Map<String, dynamic>>().map(Customer.fromJson).toList();
  }

  Future<Customer?> getById(String id) async {
    final row = await _sb.from(_table).select().eq('customer_id', id).maybeSingle();
    return row == null ? null : Customer.fromJson(row);
  }

  Future<Customer> insert(Customer draft) async {
    final rows = await _sb.from(_table).insert(draft.toInsert()).select().limit(1);
    return Customer.fromJson((rows as List).first as Map<String, dynamic>);
  }

  Future<Customer> update(String id, Customer data) async {
    final rows = await _sb.from(_table).update(data.toUpdate()).eq('customer_id', id).select().limit(1);
    return Customer.fromJson((rows as List).first as Map<String, dynamic>);
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
    return (data as List).map((e) => Vehicle.fromJson(e)).toList();
  }

  Future<Vehicle?> getPrimary(String customerId) async {
    final data = await supa
        .from('vehicles')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data == null ? null : Vehicle.fromJson(data);
  }
}

