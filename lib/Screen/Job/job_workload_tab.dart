import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/work_order_store.dart';
import '../../state/mechanic_store.dart';
import 'job_workload_detail_page.dart';

class JobWorkloadTab extends StatelessWidget {
  const JobWorkloadTab({super.key});

  @override
  Widget build(BuildContext context) {
    final woStore   = context.watch<WorkOrderStore>();
    final mechStore = context.watch<MechanicStore>();
    final orders    = woStore.workOrders;
    final mechs     = mechStore.mechanics.where((m) => m.active).toList();

    // 1) Aggregate assigned hours/counts per mechanicId
    final Map<String, _Agg> agg = {};
    for (final wo in orders) {
      final idRaw = (wo.assignedMechanicId ?? '').trim();
      final id = idRaw.isEmpty ? 'unassigned' : idRaw;
      final a = agg.putIfAbsent(id, () => _Agg());
      a.count += 1;
      a.hours += (wo.estimatedHours ?? 0).toDouble();
    }

    // 2) Build mechanic rows (active only)
    final List<_Row> mechRows = [];
    for (final m in mechs) {
      final key = m.id.trim();
      final a = agg[key] ?? _Agg();
      final cap = (m.dailyCapacityHours).toDouble();
      mechRows.add(_Row(
        label: m.name,
        mechanicId: m.id,                 // 🔹 PASS THE ID HERE
        hours: a.hours,
        count: a.count,
        capacity: cap <= 0 ? 8.0 : cap,
        sortKey: m.name.toLowerCase(),
        isUnassigned: false,
      ));
      agg.remove(key); // consumed
    }
    mechRows.sort((a, b) => a.sortKey.compareTo(b.sortKey));

    // 3) Merge everything not matched (including explicit 'unassigned') into ONE unassigned bucket
    double unassignedHours = 0.0;
    int unassignedCount = 0;
    for (final e in agg.entries) {
      final a = e.value;
      if (a.count == 0) continue;
      unassignedHours += a.hours;
      unassignedCount += a.count;
    }

    // 4) Empty state
    final totalCards = mechRows.length + (unassignedCount > 0 ? 1 : 0);
    if (totalCards == 0) {
      return const Center(child: Text('No work orders yet.'));
    }

    // 5) UI: separate sections
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (unassignedCount > 0) ...[
          const SizedBox(height: 16),
          const _SectionHeader('Unassigned jobs'),
          const SizedBox(height: 8),
          _WorkloadCard(
            row: _Row(
              label: 'Unassigned',
              mechanicId: null,            // 🔹 NULL FOR UNASSIGNED
              hours: unassignedHours,
              count: unassignedCount,
              capacity: 8.0,
              sortKey: 'zzz_unassigned',
              isUnassigned: true,
            ),
          ),
        ],
        if (mechRows.isNotEmpty) ...[
          const _SectionHeader('Active mechanics'),
          const SizedBox(height: 8),
          ...mechRows.map((r) => _WorkloadCard(row: r)).toList(),
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
  const _WorkloadCard({required this.row, super.key});

  void _open(BuildContext context) {
    if (row.isUnassigned) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const JobWorkloadDetailPage(
            title: 'Unassigned',
            isUnassigned: true,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobWorkloadDetailPage(
            title: row.label,
            mechanicId: row.mechanicId,  // 🔹 USED HERE
            isUnassigned: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (row.hours / row.capacity).clamp(0.0, 1.0);

    return Card(
      child: ListTile(
        onTap: () => _open(context), // 🔹 TAP WHOLE TILE
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
          onPressed: () => _open(context), // 🔹 SAME ACTION
        ),
      ),
    );
  }
}

class _Agg { int count = 0; double hours = 0.0; }

class _Row {
  final String label;
  final String? mechanicId; // ✅ carries the mechanic id to detail page
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
