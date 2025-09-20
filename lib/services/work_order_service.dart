import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/work_order.dart';

class WorkOrderService {
  final _client = Supabase.instance.client;

  Future<List<WorkOrder>> fetchWorkOrders() async {
    final rows = await _client
        .from('work_orders')
        .select('work_order_id, code, vehicle_id, customer_id, title, status, priority, '
        'scheduled_date, scheduled_time, estimated_hours, assigned_mechanic_id, notes, '
        'service_id, created_at, updated_at');

    return (rows as List)
        .map((m) => WorkOrder.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> assign({
    required String workOrderId,
    required String mechanicId,
    required DateTime scheduledStart,
  }) async {
    await _client.from('work_orders').update({
      'assigned_mechanic_id': mechanicId,
      'status': 'accepted',
      'scheduled_date': DateTime(
          scheduledStart.year, scheduledStart.month, scheduledStart.day
      ).toIso8601String(),
      // Postgres time as HH:MM:SS
      'scheduled_time':
      '${scheduledStart.hour.toString().padLeft(2,'0')}:'
          '${scheduledStart.minute.toString().padLeft(2,'0')}:00',
    }).eq('work_order_id', workOrderId);
  }

  Future<void> updateStatus({
    required String workOrderId,
    required WorkOrderStatus status,
  }) async {
    await _client.from('work_orders')
        .update({'status': statusToString(status)})
        .eq('work_order_id', workOrderId);
  }

  Future<void> reschedule({
    required String workOrderId,
    required DateTime newStart,
  }) async {
    await _client.from('work_orders').update({
      'scheduled_date': DateTime(newStart.year, newStart.month, newStart.day)
          .toIso8601String(),
      'scheduled_time':
      '${newStart.hour.toString().padLeft(2,'0')}:'
          '${newStart.minute.toString().padLeft(2,'0')}:00',
    }).eq('work_order_id', workOrderId);
  }
}
