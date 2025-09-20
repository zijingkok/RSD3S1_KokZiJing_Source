import 'package:flutter/foundation.dart';
import '../Models/work_order.dart';
import '../services/work_order_service.dart';

class WorkOrderStore extends ChangeNotifier {
  final _svc = WorkOrderService();
  List<WorkOrder> workOrders = [];
  bool loading = false;

  Future<void> fetch() async {
    loading = true; notifyListeners();
    try {
      workOrders = await _svc.fetchWorkOrders();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> assign(String id, String mechId, DateTime start) async {
    await _svc.assign(workOrderId: id, mechanicId: mechId, scheduledStart: start);
    await fetch();
  }

  Future<void> setStatus(String id, WorkOrderStatus status) async {
    await _svc.updateStatus(workOrderId: id, status: status);
    await fetch();
  }

  Future<void> reschedule(String id, DateTime newStart) async {
    await _svc.reschedule(workOrderId: id, newStart: newStart);
    await fetch();
  }
}
