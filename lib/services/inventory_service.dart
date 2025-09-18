import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/inventory_summary.dart';
import '../Models/parts.dart';


class InventoryService {
  final supabase = Supabase.instance.client;

  /// Fetch summary values for the dashboard
  Future<InventorySummary> fetchInventorySummary() async {
    // 1) Total stock
    final totalRes =
    await supabase.from('parts').select('stock_quantity');
    final totalStock = totalRes.fold<int>(
        0, (sum, row) => sum + (row['stock_quantity'] as int? ?? 0));

    // 2) Low stock alerts: stock_quantity <= reorder_level
    final lowRes =
    await supabase.from('parts').select('stock_quantity, reorder_level');
    final lowStockCount = lowRes.where((row) {
      final stock = row['stock_quantity'] as int? ?? 0;
      final reorder = row['reorder_level'] as int? ?? 0;
      return stock <= reorder;
    }).length;

    // 3) Pending procurement
    final pendingRes = await supabase
        .from('procurement_requests')
        .select()
        .eq('status', 'Pending');
    final pendingCount = pendingRes.length;

    return InventorySummary(
      totalStockedParts: totalStock,
      lowStockAlerts: lowStockCount,
      pendingProcurement: pendingCount,
    );
  }

  /// 🔹 Fetch all parts (for inventory list)
  Future<List<Part>> fetchParts() async {
    final res = await supabase.from('parts').select();

    return (res as List<dynamic>)
        .map((row) => Part.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// 🔹 Add a procurement request
  Future<void> requestMore(String partId, int qty,
      {String priority = 'Normal'}) async {
    await supabase.from('procurement_requests').insert({
      'part_id': partId,
      'quantity': qty,
      'priority': priority,
    });
  }
}
