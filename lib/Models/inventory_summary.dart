class InventorySummary {
  final int totalStockedParts;
  final int lowStockAlerts;
  final int pendingProcurement;

  InventorySummary({
    required this.totalStockedParts,
    required this.lowStockAlerts,
    required this.pendingProcurement,
  });
}
