// lib/services/inventory_service.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Models/Inventory_models/inventory_summary.dart';
import '../../Models/Inventory_models/parts.dart';

class InventoryService {
  final supabase = Supabase.instance.client;

  /// Fetch summary values for the dashboard
  Future<InventorySummary> fetchInventorySummary() async {
    // 1) Total stock
    final totalRes = await supabase.from('parts').select('stock_quantity');
    final totalStock = (totalRes as List).fold<int>(
      0,
          (sum, row) => sum + (row['stock_quantity'] as int? ?? 0),
    );

    // 2) Low stock alerts: stock_quantity <= reorder_level
    final lowRes =
    await supabase.from('parts').select('stock_quantity, reorder_level');
    final lowStockCount = (lowRes as List).where((row) {
      final stock = row['stock_quantity'] as int? ?? 0;
      final reorder = row['reorder_level'] as int? ?? 0;
      return stock <= reorder;
    }).length;

    // 3) Pending procurement
    final pendingRes = await supabase
        .from('procurement_requests')
        .select()
        .eq('status', 'Pending');
    final pendingCount = (pendingRes as List).length;

    return InventorySummary(
      totalStockedParts: totalStock,
      lowStockAlerts: lowStockCount,
      pendingProcurement: pendingCount,
    );
  }

  /// 🔹 Fetch all parts (for inventory list)
  Future<List<Part>> fetchParts() async {
    final res = await supabase.from('parts').select();
    return (res as List)
        .map((row) => Part.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// 🔹 Add a procurement request
  Future<void> requestMore(
      String partId,
      int qty, {
        String priority = 'Normal',
      }) async {
    await supabase.from('procurement_requests').insert({
      'part_id': partId,
      'quantity': qty,
      'priority': priority,
    });
  }

  /// 🔹 Realtime dashboard stream
  Stream<InventorySummary> streamInventorySummary() {
    // Two streams: parts + procurement_requests
    final partsStream =
    supabase.from('parts').stream(primaryKey: ['part_id']);
    final procurementStream = supabase
        .from('procurement_requests')
        .stream(primaryKey: ['request_id']);

    // Controller that merges both
    final controller = StreamController<InventorySummary>();

    Future<void> emitSummary() async {
      final summary = await fetchInventorySummary();
      if (!controller.isClosed) controller.add(summary);
    }

    // Listen to both tables
    final sub1 = partsStream.listen((_) => emitSummary());
    final sub2 = procurementStream.listen((_) => emitSummary());

    // Emit once initially
    emitSummary();

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }
}
