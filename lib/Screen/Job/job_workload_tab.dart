
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management/state/work_order_store.dart';
import 'package:workshop_management/state/mechanic_store.dart';
import 'package:workshop_management/Models/work_order.dart';
import 'package:workshop_management/Models/mechanic.dart';
import 'package:workshop_management/Screen/Job/job_workload_detail_page.dart';

enum _Window { overdue, today, week, month, all }

/// Workload tab (Default math + color cues + near-due + prioritized sorting + pull-to-refresh).
class JobWorkloadTab extends StatefulWidget {
  const JobWorkloadTab({super.key});
  @override
  State<JobWorkloadTab> createState() => _JobWorkloadTabState();
}

class _JobWorkloadTabState extends State<JobWorkloadTab> {
  _Window _sel = _Window.week; // default “7 days”

  // Treat anything not explicitly "done" as open
  bool _isOpenStatus(WorkOrderStatus s) {
    switch (s) {
      case WorkOrderStatus.completed:
        return false;
    // Keep these counted for baseline
      case WorkOrderStatus.onHold:
      case WorkOrderStatus.unassigned:
      case WorkOrderStatus.scheduled:
      case WorkOrderStatus.inProgress:
        return true;
    }
  }

  /// Returns (start, end) where end is exclusive.
  (DateTime, DateTime) _windowDates(DateTime now, _Window w) {
    final day0 = DateTime(now.year, now.month, now.day);
    switch (w) {
      case _Window.overdue:
        return (DateTime(1970), day0);
      case _Window.today:
        return (day0, day0.add(const Duration(days: 1)));
      case _Window.week:
        return (day0, day0.add(const Duration(days: 8))); // today + 7
      case _Window.month:
        return (day0, day0.add(const Duration(days: 31)));
      case _Window.all:
        return (DateTime(1970), DateTime(9999, 12, 31));
    }
  }

  Color _barColor(double util, int overdue) {
    if (overdue > 0) return Colors.red;
    if (util > 1.0) return Colors.red;
    if (util >= 0.8) return Colors.orange;
    return Colors.green;
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final ws = context.read<WorkOrderStore>() as dynamic;
    final ms = context.read<MechanicStore>() as dynamic;
    Future<void> _tryAll(dynamic obj) async {
      try { final r = obj.refresh(); if (r is Future) await r; return; } catch (_) {}
      try { final r = obj.fetch();   if (r is Future) await r; return; } catch (_) {}
      try { final r = obj.load();    if (r is Future) await r; return; } catch (_) {}
      try { final r = obj.sync();    if (r is Future) await r; return; } catch (_) {}
    }
    await Future.wait([_tryAll(ws), _tryAll(ms)]);
  }

  @override
  Widget build(BuildContext context) {
    final woStore   = context.watch<WorkOrderStore>();
    final mechStore = context.watch<MechanicStore>();
    final allOrders = woStore.workOrders;
    final mechs     = mechStore.mechanics.where((m) => m.active).toList();

    // date window from selected chip
    final now = DateTime.now();
    final (start, end) = _windowDates(now, _sel);
    final days = (end.difference(start).inDays).clamp(1, 365);

    // FILTER first (status + window)
    final filtered = allOrders.where((w) {
      if (!_isOpenStatus(w.status)) return false;

      final d = w.scheduledDate;
      if (_sel == _Window.all) return true;

      if (_sel == _Window.overdue) {
        if (d == null) return false;
        return d.isBefore(end); // end = today
      }

      if (d == null) return true; // keep undated jobs for planning
      return !d.isBefore(start) && d.isBefore(end);
    }).toList();

    // Build overdue and near-due across ALL open orders (global risk view)
    final today = DateTime(now.year, now.month, now.day);
    final nearDueCutoff = today.add(const Duration(hours: 48));
    final Map<String, int> overdueMap = {};
    final Map<String, int> nearDueMap = {};
    for (final w in allOrders) {
      if (!_isOpenStatus(w.status)) continue;
      final d = w.scheduledDate;
      final idRaw = (w.assignedMechanicId ?? '').trim();
      final bucket = idRaw.isEmpty ? 'unassigned' : idRaw;

      if (d != null && d.isBefore(today)) {
        overdueMap[bucket] = (overdueMap[bucket] ?? 0) + 1;
      } else if (d != null && !d.isBefore(today) && d.isBefore(nearDueCutoff)) {
        nearDueMap[bucket] = (nearDueMap[bucket] ?? 0) + 1;
      }
    }

    // Aggregate planned hours/counts per mechanic (in window)
    final Map<String, _Agg> agg = {};
    for (final wo in filtered) {
      final idRaw = (wo.assignedMechanicId ?? '').trim();
      final id = idRaw.isEmpty ? 'unassigned' : idRaw;
      final a = agg.putIfAbsent(id, () => _Agg());
      a.count += 1;
      a.hours += (wo.estimatedHours ?? 0).toDouble();
    }

    // Active mechanic IDs set
    final activeIds = mechs.map((m) => m.id.trim()).toSet();

    // Build rows (mechanics)
    final List<_Row> mechRows = [];
    for (final m in mechs) {
      final key = m.id.trim();
      final a = agg[key] ?? _Agg();
      final capPerDay = (m.dailyCapacityHours).toDouble();
      final capacityWindow = (capPerDay <= 0 ? 8.0 : capPerDay) * days;
      final overdue = overdueMap[key] ?? 0;
      final nearDue = nearDueMap[key] ?? 0;
      final util = capacityWindow > 0 ? (a.hours / capacityWindow) : 0.0;

      mechRows.add(_Row(
        label: m.name,
        mechanicId: m.id,
        hours: a.hours,
        count: a.count,
        capacityWindow: capacityWindow,
        sortKey: m.name.toLowerCase(),
        isUnassigned: false,
        overdue: overdue,
        nearDue: nearDue,
        util: util,
      ));
      agg.remove(key); // consumed
    }

    // Merge leftovers to Unassigned
    double unassignedHours = 0.0;
    int unassignedCount = 0;
    for (final e in agg.entries) {
      final a = e.value;
      if (a.count == 0) continue;
      unassignedHours += a.hours;
      unassignedCount += a.count;
    }
    // Overdue/nearDue for unassigned = explicit unassigned + stray ids not in active
    int unassignedOverdue = overdueMap['unassigned'] ?? 0;
    int unassignedNearDue = nearDueMap['unassigned'] ?? 0;
    overdueMap.forEach((k, v) {
      if (k != 'unassigned' && !activeIds.contains(k)) unassignedOverdue += v;
    });
    nearDueMap.forEach((k, v) {
      if (k != 'unassigned' && !activeIds.contains(k)) unassignedNearDue += v;
    });

    // Prioritized sort
    mechRows.sort((a, b) {
      if (b.overdue != a.overdue) return b.overdue.compareTo(a.overdue);
      if (b.nearDue != a.nearDue) return b.nearDue.compareTo(a.nearDue);
      if (b.util != a.util) return b.util.compareTo(a.util);
      return a.sortKey.compareTo(b.sortKey);
    });

    // Build list items
    final List<Widget> items = [
      _chips(),
      const SizedBox(height: 12),
    ];

    if (unassignedCount > 0) {
      items.addAll([
        const _SectionHeader('Unassigned jobs'),
        const SizedBox(height: 8),
        _WorkloadCard(
          row: _Row(
            label: 'Unassigned',
            mechanicId: null,
            hours: unassignedHours,
            count: unassignedCount,
            capacityWindow: 8.0 * days,
            sortKey: 'zzz_unassigned',
            isUnassigned: true,
            overdue: unassignedOverdue,
            nearDue: unassignedNearDue,
            util: (8.0 * days) > 0 ? (unassignedHours / (8.0 * days)) : 0.0,
          ),
          windowStart: start,
          windowEnd: end,
          windowType: _sel.name,
        ),
        const SizedBox(height: 16),
      ]);
    }

    if (mechRows.isNotEmpty) {
      items.addAll([
        const _SectionHeader('Active mechanics'),
        const SizedBox(height: 8),
        ...mechRows.map((r) => _WorkloadCard(
          row: r,
          windowStart: start,
          windowEnd: end,
          windowType: _sel.name,
        )),
      ]);
    }

    if (mechRows.isEmpty && unassignedCount == 0) {
      items.add(const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No work orders for this window. Pull to refresh.')),
      ));
    }

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(context),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: items,
      ),
    );
  }

  Widget _chips() {
    Widget chip(String label, _Window w) => ChoiceChip(
      label: Text(label),
      selected: _sel == w,
      onSelected: (_) => setState(() => _sel = w),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Overdue', _Window.overdue),
          const SizedBox(width: 8),
          chip('Today', _Window.today),
          const SizedBox(width: 8),
          chip('7 days', _Window.week),
          const SizedBox(width: 8),
          chip('30 days', _Window.month),
          const SizedBox(width: 8),
          chip('All', _Window.all),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: .2,
      ),
    );
  }
}

class _WorkloadCard extends StatelessWidget {
  final _Row row;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String windowType;

  const _WorkloadCard({
    required this.row,
    required this.windowStart,
    required this.windowEnd,
    required this.windowType,
    super.key,
  });

  Color _barColor(double util, int overdue) {
    if (overdue > 0) return Colors.red;
    if (util > 1.0) return Colors.red;
    if (util >= 0.8) return Colors.orange;
    return Colors.green;
  }

  void _open(BuildContext context) {
    if (row.isUnassigned) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobWorkloadDetailPage(
            title: 'Unassigned',
            isUnassigned: true,
            windowStart: windowStart,
            windowEnd: windowEnd,
            windowType: windowType,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobWorkloadDetailPage(
            title: row.label,
            mechanicId: row.mechanicId,
            isUnassigned: false,
            windowStart: windowStart,
            windowEnd: windowEnd,
            windowType: windowType,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final util = row.util;
    final color = _barColor(util, row.overdue);

    return Card(
      child: ListTile(
        onTap: () => _open(context),
        leading: row.isUnassigned
            ? const Icon(Icons.report_gmailerrorred)
            : const Icon(Icons.engineering),
        title: Row(
          children: [
            Expanded(child: Text(row.label)),
            if (row.nearDue > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text('Due soon: ${row.nearDue}', style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            LinearProgressIndicator(value: util.clamp(0.0, 1.0), color: color),
            const SizedBox(height: 6),
            Text(
              '${row.count} orders • '
                  '${row.hours.toStringAsFixed(1)} / ${row.capacityWindow.toStringAsFixed(1)} hrs'
                  '${row.overdue > 0 ? '  •  Overdue: ${row.overdue}' : ''}',
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.list_alt),
          tooltip: row.isUnassigned ? 'View unassigned orders' : 'View orders',
          onPressed: () => _open(context),
        ),
      ),
    );
  }
}

class _Agg { int count = 0; double hours = 0.0; }

class _Row {
  final String label;
  final String? mechanicId; // carries mechanic id to detail page
  final double capacityWindow; // per selected window (days * capacityPerDay)
  final double hours;
  final int count;
  final String sortKey;
  final bool isUnassigned;
  final int overdue;
  final int nearDue;
  final double util;
  _Row({
    required this.label,
    required this.capacityWindow,
    required this.hours,
    required this.count,
    required this.sortKey,
    required this.isUnassigned,
    required this.overdue,
    required this.nearDue,
    required this.util,
    this.mechanicId,
  });
}
