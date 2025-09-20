
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/work_order_store.dart';
import '../../state/mechanic_store.dart';
import '../../Models/work_order.dart';
import '../../Models/mechanic.dart';

class JobWorkloadDetailPage extends StatelessWidget {
  final String? mechanicId;   // null when showing Unassigned
  final String title;         // mechanic name or "Unassigned"
  final bool isUnassigned;

  // Optional window (passed from tab for consistency)
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final String? windowType; // just for display/debug

  const JobWorkloadDetailPage({
    super.key,
    required this.title,
    this.mechanicId,
    this.isUnassigned = false,
    this.windowStart,
    this.windowEnd,
    this.windowType,
  });

  // Treat anything not explicitly "done" as open
  bool _isOpenStatus(WorkOrderStatus s) {
    switch (s) {
      case WorkOrderStatus.completed:
        return false;
      case WorkOrderStatus.onHold:
      case WorkOrderStatus.unassigned:
      case WorkOrderStatus.accepted:
      case WorkOrderStatus.inProgress:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final woStore   = context.watch<WorkOrderStore>();
    final mechStore = context.watch<MechanicStore>();

    final allOrders = woStore.workOrders;
    final mechanics = mechStore.mechanics;

    // Filter by mechanic/unassigned first
    List<WorkOrder> orders;
    if (isUnassigned) {
      orders = allOrders.where((w) => (w.assignedMechanicId ?? '').trim().isEmpty).toList();
    } else {
      final id = (mechanicId ?? '').trim();
      orders = allOrders.where((w) => (w.assignedMechanicId ?? '').trim() == id).toList();
    }

    // Apply the same window if provided; else default to week
    final now   = DateTime.now();
    final day0  = DateTime(now.year, now.month, now.day);
    final start = windowStart ?? day0;
    final end   = windowEnd   ?? day0.add(const Duration(days: 8));

    orders = orders.where((w) {
      if (!_isOpenStatus(w.status)) return false;
      final d = w.scheduledDate;
      if (d == null) return true;
      return !d.isBefore(start) && d.isBefore(end);
    }).toList();

    // Mechanic info (if not unassigned)
    Mechanic? mech;
    if (!isUnassigned && mechanicId != null) {
      try {
        mech = mechanics.firstWhere((m) => m.id.trim() == mechanicId!.trim());
      } catch (_) {
        mech = null;
      }
    }

    final totalHours = orders.fold<double>(0.0, (sum, w) => sum + (w.estimatedHours ?? 0).toDouble());
    final capacity   = (mech?.dailyCapacityHours ?? 8).toDouble().clamp(1, 24);
    final loadPct    = (totalHours / (isUnassigned ? 8.0 : capacity)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _SummaryCard(
            title: title,
            isUnassigned: isUnassigned,
            mechanic: mech,
            orderCount: orders.length,
            totalHours: totalHours,
            capacity: isUnassigned ? 8.0 : capacity.toDouble(),
            loadPct: loadPct,
            windowStart: start,
            windowEnd: end,
            windowType: windowType,
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No work orders to display.'),
              ),
            )
          else
            ...orders.map((w) => _OrderTile(order: w)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final bool isUnassigned;
  final Mechanic? mechanic;
  final int orderCount;
  final double totalHours;
  final double capacity;
  final double loadPct;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String? windowType;

  const _SummaryCard({
    required this.title,
    required this.isUnassigned,
    required this.mechanic,
    required this.orderCount,
    required this.totalHours,
    required this.capacity,
    required this.loadPct,
    required this.windowStart,
    required this.windowEnd,
    this.windowType,
  });

  @override
  Widget build(BuildContext context) {
    final startStr = '${windowStart.year}-${windowStart.month.toString().padLeft(2,'0')}-${windowStart.day.toString().padLeft(2,'0')}';
    final endStr   = '${windowEnd.year}-${windowEnd.month.toString().padLeft(2,'0')}-${windowEnd.day.toString().padLeft(2,'0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(isUnassigned ? Icons.report_gmailerrorred : Icons.engineering),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ]),
            const SizedBox(height: 12),
            Text('Window: $startStr → $endStr${windowType != null ? '  ($windowType)' : ''}'),
            const SizedBox(height: 8),
            if (!isUnassigned && mechanic != null) ...[
              _KV('Status', mechanic!.active ? 'Active' : 'Inactive'),
              _KV('Daily capacity', '${capacity.toStringAsFixed(1)} hrs'),
            ] else ...[
              const Text('Jobs not yet assigned to any mechanic.'),
              _KV('Bucket capacity (virtual)', '${capacity.toStringAsFixed(1)} hrs'),
            ],
            const SizedBox(height: 12),
            LinearProgressIndicator(value: loadPct),
            const SizedBox(height: 8),
            Text('$orderCount orders • ${totalHours.toStringAsFixed(1)} / ${capacity.toStringAsFixed(1)} hrs'),
          ],
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String k;
  final String v;
  const _KV(this.k, this.v, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final WorkOrder order;
  const _OrderTile({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    final code   = order.code;
    final title  = order.title;
    final statusLabel = statusToString(order.status); // enum -> string
    final prioLabel   = order.priority.name;          // low/normal/high/urgent
    final schedD = order.scheduledDate == null
        ? ''
        : order.scheduledDate!.toIso8601String().split('T').first;
    final hrs    = (order.estimatedHours ?? 0).toDouble();

    return Card(
      child: ListTile(
        leading: const Icon(Icons.assignment),
        title: Text('${code.isNotEmpty ? '$code • ' : ''}$title'),
        subtitle: Text('Status: $statusLabel • Priority: $prioLabel${schedD.isNotEmpty ? ' • Due: $schedD' : ''}'),
        trailing: Text('${hrs.toStringAsFixed(1)}h'),
        onTap: () {
          // Optionally navigate to a Work Order detail page if you have one.
        },
      ),
    );
  }
}
