
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management/state/work_order_store.dart';
import 'package:workshop_management/state/mechanic_store.dart';
import 'package:workshop_management/Models/work_order.dart';
import 'package:workshop_management/Models/mechanic.dart';

/// Detail page with sticky summary + suggestions for unassigned.
class JobWorkloadDetailPage extends StatelessWidget {
  final String? mechanicId;   // null when showing Unassigned
  final String title;         // mechanic name or "Unassigned"
  final bool isUnassigned;

  // Window (passed from tab for consistency)
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
    final mechanics = mechStore.mechanics.where((m) => m.active).toList();

    // Filter by mechanic/unassigned first
    List<WorkOrder> scoped;
    if (isUnassigned) {
      scoped = allOrders.where((w) => (w.assignedMechanicId ?? '').trim().isEmpty).toList();
    } else {
      final id = (mechanicId ?? '').trim();
      scoped = allOrders.where((w) => (w.assignedMechanicId ?? '').trim() == id).toList();
    }

    // Apply the same window if provided; else default to week
    final now   = DateTime.now();
    final day0  = DateTime(now.year, now.month, now.day);
    final start = windowStart ?? day0;
    final end   = windowEnd   ?? day0.add(const Duration(days: 8));
    final days  = (end.difference(start).inDays).clamp(1, 365);

    // Filter open + window
    var orders = scoped.where((w) {
      if (!_isOpenStatus(w.status)) return false;
      final d = w.scheduledDate;
      if (windowType == 'all') return true; // defensive
      if (windowType == 'overdue') {
        if (d == null) return false;
        return d.isBefore(day0);
      }
      if (d == null) return true;
      return !d.isBefore(start) && d.isBefore(end);
    }).toList();

    // Overdue & near-due for this scope (across ALL open orders for that bucket)
    final today = DateTime(now.year, now.month, now.day);
    final nearCut = today.add(const Duration(hours: 48));
    int overdueCount = 0;
    int nearDueCount = 0;
    for (final w in (isUnassigned
        ? allOrders.where((x) => (x.assignedMechanicId ?? '').trim().isEmpty)
        : allOrders.where((x) => (x.assignedMechanicId ?? '').trim() == (mechanicId ?? '').trim()))) {
      if (!_isOpenStatus(w.status)) continue;
      final d = w.scheduledDate;
      if (d != null && d.isBefore(today)) overdueCount++;
      else if (d != null && !d.isBefore(today) && d.isBefore(nearCut)) nearDueCount++;
    }

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
    final capacityPerDay = (mech?.dailyCapacityHours ?? 8).toDouble();
    final capacityWindow = (capacityPerDay <= 0 ? 8.0 : capacityPerDay) * days;
    final util = isUnassigned ? (totalHours / (8.0 * days)) : (totalHours / capacityWindow);
    final color = _barColor(util, overdueCount);

    // Suggested assignees (only on Unassigned): top 2 mechanics with lowest utilization for this window
    List<_Suggestion> suggestions = [];
    if (isUnassigned) {
      for (final m in mechanics) {
        final mid = m.id.trim();
        final mOrders = allOrders.where((w) => (w.assignedMechanicId ?? '').trim() == mid).where((w) {
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
        final mhours = mOrders.fold<double>(0.0, (sum, w) => sum + (w.estimatedHours ?? 0).toDouble());
        final cap = ((m.dailyCapacityHours).toDouble() <= 0 ? 8.0 : (m.dailyCapacityHours).toDouble()) * days;
        final mu = cap > 0 ? (mhours / cap) : 0.0;
        suggestions.add(_Suggestion(name: m.name, mechanicId: m.id, utilization: mu, freeHours: (cap - mhours)));
      }
      // sort by lowest utilization then highest free hours
      suggestions.sort((a, b) {
        if (a.utilization != b.utilization) return a.utilization.compareTo(b.utilization);
        return b.freeHours.compareTo(a.freeHours);
      });
      if (suggestions.length > 2) suggestions = suggestions.sublist(0, 2);
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SummaryHeaderDelegate(
              minExtent: 140,
              maxExtent: 170,
              child: _SummaryCard(
                title: title,
                isUnassigned: isUnassigned,
                mechanic: mech,
                orderCount: orders.length,
                totalHours: totalHours,
                capacity: isUnassigned ? (8.0 * days) : capacityWindow,
                util: util,
                color: color,
                windowStart: start,
                windowEnd: end,
                windowType: windowType,
                overdue: overdueCount,
                nearDue: nearDueCount,
              ),
            ),
          ),
          if (isUnassigned && suggestions.isNotEmpty)
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Suggested assignees', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...suggestions.map((s) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(s.name)),
                          Text('${(s.utilization * 100).toStringAsFixed(0)}% util • ${s.freeHours.toStringAsFixed(1)}h free'),
                          // TODO: Add an "Assign" button wired to your assignment flow
                        ],
                      )),
                    ],
                  ),
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

class _Suggestion {
  final String name;
  final String mechanicId;
  final double utilization;
  final double freeHours;
  _Suggestion({required this.name, required this.mechanicId, required this.utilization, required this.freeHours});
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
  final int nearDue;

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
    required this.nearDue,
  });

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2,'0');
    final startStr = '${windowStart.year}-${two(windowStart.month)}-${two(windowStart.day)}';
    final endStr   = '${windowEnd.year}-${two(windowEnd.month)}-${two(windowEnd.day)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(isUnassigned ? Icons.report_gmailerrorred : Icons.engineering),
              const SizedBox(width: 8),
              Expanded(child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              )),
              if (nearDue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text('Due soon: $nearDue', style: const TextStyle(fontSize: 12)),
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
