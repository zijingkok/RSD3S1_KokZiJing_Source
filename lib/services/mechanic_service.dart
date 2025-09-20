import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/mechanic.dart';

class MechanicService {
  final _client = Supabase.instance.client;

  Future<List<Mechanic>> fetchMechanics() async {
    final rows = await _client
        .from('staff')
        .select('staff_id, full_name, role, daily_capacity_hours, active')
        .eq('role', 'Mechanic')
        .eq('active', true);

    return (rows as List)
        .map((m) => Mechanic.fromMap(m as Map<String, dynamic>))
        .toList();
  }
}
