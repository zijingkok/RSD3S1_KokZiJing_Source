
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management/state/work_order_store.dart';
import 'package:workshop_management/state/mechanic_store.dart';
import 'package:workshop_management/Models/work_order.dart';
import 'package:workshop_management/Models/mechanic.dart';

class JobWorkloadDetailPage extends StatelessWidget {
  final String? mechanicId;
  final String title;
  final bool isUnassigned;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final String? windowType;

  const JobWorkloadDetailPage({
    super.key,
    required this.title,
    this.mechanicId,
    this.isUnassigned = false,
    this.windowStart,
    this.windowEnd,
    this.windowType,
  });

  bool _isOpenStatus(WorkOrderStatus s) {
    switch (s) {
      case WorkOrderStatus.completed:
        return false;
      case WorkOrderStatus.onHold:
      case WorkOrderStatus.unassigned:
      case WorkOrderStatus.scheduled:
      case WorkOrderStatus.inProgress:
        return true;
    }
  }

  Color _barColor(double util, int overdue) {
    if (overdue > 0) return Colors.red;
    if (util > 1.0) return Colors.red;
    if (util >= 0.8) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final woStore   = context.watch<WorkOrderStore>();
    final mechStore = context.watch<MechanicStore>();

    final allOrders = woStore.workOrders;
    final mechanics = mechStore.mechanics;

    List<WorkOrder> scoped;
    if (isUnassigned) {
      scoped = allOrders.where((w) => (w.assignedMechanicId ?? '').trim().isEmpty).toList();
    } else {
      final id = (mechanicId ?? '').trim();
      scoped = allOrders.where((w) => (w.assignedMechanicId ?? '').trim() == id).toList();
    }

    final now   = DateTime.now();
    final day0  = DateTime(now.year, now.month, now.day);
    final start = windowStart ?? day0;
    final end   = windowEnd   ?? day0.add(const Duration(days: 8));
    final days  = (end.difference(start).inDays).clamp(1, 365);

    var orders = scoped.where((w) {
      if (!_isOpenStatus(w.status)) return false;
      final d = w.scheduledDate;
      if (windowType == 'all') return true;
      if (windowType == 'overdue') {
        if (d == null) return false;
        return d.isBefore(day0);
      }
      if (d == null) return true;
      return !d.isBefore(start) && d.isBefore(end);
    }).toList();

    final today = DateTime(now.year, now.month, now.day);
    final overdueCount = scoped.where((w) {
      if (!_isOpenStatus(w.status)) return false;
      final d = w.scheduledDate;
      return d != null && d.isBefore(today);
    }).length;

    Mechanic? mech;
    if (!isUnassigned && mechanicId != null) {
      try {
        mech = mechanics.firstWhere((m) => m.id.trim() == mechanicId!.trim());
      } catch (_) {
        mech = null;
      }
    }

    final totalHours = orders.fold<double>(0.0, (sum, w) => sum + (w.estimatedHours ?? 0).toDouble());
    final capacityPerDay = (mech?.dailyCapacityHours ?? 8).toDouble();
    final capacityWindow = (capacityPerDay <= 0 ? 8.0 : capacityPerDay) * days;
    final util = totalHours / capacityWindow;
    final color = _barColor(util, overdueCount);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SummaryHeaderDelegate(
              minExtent: 120,
              maxExtent: 150,
              child: _SummaryCard(
                title: title,
                isUnassigned: isUnassigned,
                mechanic: mech,
                orderCount: orders.length,
                totalHours: totalHours,
                capacity: capacityWindow,
                util: util,
                color: color,
                windowStart: start,
                windowEnd: end,
                windowType: windowType,
                overdue: overdueCount,
              ),
            ),
          ),
          SliverList.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) => _OrderTile(order: orders[i]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _SummaryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtent;
  final double maxExtent;
  final Widget child;
  _SummaryHeaderDelegate({required this.minExtent, required this.maxExtent, required this.child});
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Material(color: Theme.of(context).scaffoldBackgroundColor, child: child);
  @override
  bool shouldRebuild(covariant _SummaryHeaderDelegate oldDelegate) => oldDelegate.child != child || oldDelegate.minExtent != minExtent || oldDelegate.maxExtent != maxExtent;
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final bool isUnassigned;
  final Mechanic? mechanic;
  final int orderCount;
  final double totalHours;
  final double capacity;
  final double util;
  final Color color;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String? windowType;
  final int overdue;

  const _SummaryCard({
    required this.title,
    required this.isUnassigned,
    required this.mechanic,
    required this.orderCount,
    required this.totalHours,
    required this.capacity,
    required this.util,
    required this.color,
    required this.windowStart,
    required this.windowEnd,
    this.windowType,
    required this.overdue,
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
            const SizedBox(height: 8),
            Text('Window: $startStr → $endStr${windowType != null ? '  (${windowType!})' : ''}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: util.clamp(0.0, 1.0), color: color),
            const SizedBox(height: 6),
            Text('$orderCount orders • ${totalHours.toStringAsFixed(1)} / ${capacity.toStringAsFixed(1)} hrs'
                '${overdue > 0 ? '  •  Overdue: $overdue' : ''}'),
          ],
        ),
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
    final statusLabel = statusToString(order.status);
    final prioLabel   = order.priority.name;
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
