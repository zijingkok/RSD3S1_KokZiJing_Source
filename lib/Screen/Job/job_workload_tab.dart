
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/work_order_store.dart';
import '../../state/mechanic_store.dart';
import '../../Models/work_order.dart';
import '../../Models/mechanic.dart';
import 'job_workload_detail_page.dart';

enum _Window { overdue, today, week, month, all }

/// Humanized workload view with interactive window chips.
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
      case WorkOrderStatus.onHold:
      case WorkOrderStatus.unassigned:
      case WorkOrderStatus.accepted:
      case WorkOrderStatus.inProgress:
        return true;
    }
  }

  /// Returns (start, end) where end is exclusive.
  (DateTime, DateTime) _windowDates(DateTime now, _Window w) {
    final day0 = DateTime(now.year, now.month, now.day);
    switch (w) {
      case _Window.overdue:
      // everything strictly before today
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

  @override
  Widget build(BuildContext context) {
    final woStore   = context.watch<WorkOrderStore>();
    final mechStore = context.watch<MechanicStore>();
    final allOrders = woStore.workOrders;
    final mechs     = mechStore.mechanics.where((m) => m.active).toList();

    // 👉 get window from selected chip
    final now = DateTime.now();
    final (start, end) = _windowDates(now, _sel);

    // FILTER first (status + window)
    final orders = allOrders.where((w) {
      if (!_isOpenStatus(w.status)) return false;

      final d = w.scheduledDate;
      if (_sel == _Window.all) return true;

      if (_sel == _Window.overdue) {
        // overdue = scheduled before today; include null? usually no
        if (d == null) return false;
        return d.isBefore(end); // end = today
      }

      if (d == null) return true; // keep undated jobs for planning
      return !d.isBefore(start) && d.isBefore(end);
    }).toList();

    // === chips UI ===
    Widget chips() {
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

    // === aggregate ===
    final Map<String, _Agg> agg = {};
    for (final wo in orders) {
      final idRaw = (wo.assignedMechanicId ?? '').trim();
      final id = idRaw.isEmpty ? 'unassigned' : idRaw;
      final a = agg.putIfAbsent(id, () => _Agg());
      a.count += 1;
      a.hours += (wo.estimatedHours ?? 0).toDouble();
    }

    final List<_Row> mechRows = [];
    for (final m in mechs) {
      final key = m.id.trim();
      final a = agg[key] ?? _Agg();
      final cap = (m.dailyCapacityHours).toDouble();
      mechRows.add(_Row(
        label: m.name,
        mechanicId: m.id,
        hours: a.hours,
        count: a.count,
        capacity: cap <= 0 ? 8.0 : cap,
        sortKey: m.name.toLowerCase(),
        isUnassigned: false,
      ));
      agg.remove(key);
    }
    mechRows.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    double unassignedHours = 0.0;
    int unassignedCount = 0;
    for (final e in agg.entries) {
      final a = e.value;
      if (a.count == 0) continue;
      unassignedHours += a.hours;
      unassignedCount += a.count;
    }

    final totalCards = mechRows.length + (unassignedCount > 0 ? 1 : 0);

    if (totalCards == 0) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            chips(),
            const SizedBox(height: 12),
            const Expanded(child: Center(child: Text('No work orders for this window.'))),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        chips(),
        const SizedBox(height: 12),

        if (mechRows.isNotEmpty) ...[
          const _SectionHeader('Active mechanics'),
          const SizedBox(height: 8),
          ...mechRows.map((r) => _WorkloadCard(
            row: r,
            // Pass current window to details page
            onOpen: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => JobWorkloadDetailPage(
                  title: r.label,
                  mechanicId: r.mechanicId,
                  isUnassigned: false,
                  windowStart: start,
                  windowEnd: end,
                  windowType: _sel.name,
                ),
              ),
            ),
          )).toList(),
        ],
        if (unassignedCount > 0) ...[
          const SizedBox(height: 16),
          const _SectionHeader('Unassigned jobs'),
          const SizedBox(height: 8),
          _WorkloadCard(
            row: _Row(
              label: 'Unassigned',
              mechanicId: null,
              hours: unassignedHours,
              count: unassignedCount,
              capacity: 8.0,
              sortKey: 'zzz_unassigned',
              isUnassigned: true,
            ),
            onOpen: (ctx) => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => JobWorkloadDetailPage(
                  title: 'Unassigned',
                  isUnassigned: true,
                  windowStart: start,
                  windowEnd: end,
                  windowType: _sel.name,
                ),
              ),
            ),
          ),
        ],
      ],
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
  final void Function(BuildContext) onOpen;
  const _WorkloadCard({required this.row, required this.onOpen, super.key});

  @override
  Widget build(BuildContext context) {
    final pct = (row.hours / row.capacity).clamp(0.0, 1.0);

    return Card(
      child: ListTile(
        onTap: () => onOpen(context),
        leading: row.isUnassigned
            ? const Icon(Icons.report_gmailerrorred)
            : const Icon(Icons.engineering),
        title: Text(row.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            LinearProgressIndicator(value: pct),
            const SizedBox(height: 6),
            Text(
              '${row.count} orders • '
                  '${row.hours.toStringAsFixed(1)} / ${row.capacity.toStringAsFixed(1)} hrs',
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.list_alt),
          tooltip: row.isUnassigned ? 'View unassigned orders' : 'View orders',
          onPressed: () => onOpen(context),
        ),
      ),
    );
  }
}

class _Agg { int count = 0; double hours = 0.0; }

class _Row {
  final String label;
  final String? mechanicId; // carries mechanic id to detail page
  final double capacity;
  final double hours;
  final int count;
  final String sortKey;
  final bool isUnassigned;
  _Row({
    required this.label,
    required this.capacity,
    required this.hours,
    required this.count,
    required this.sortKey,
    required this.isUnassigned,
    this.mechanicId,
  });
}
