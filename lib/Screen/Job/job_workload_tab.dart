import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/work_order_store.dart';
import '../../Models/work_order.dart';

class JobWorkloadTab extends StatelessWidget {
  const JobWorkloadTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkOrderStore>();
    final list = store.workOrders;

    // Group by mechanicId
    final Map<String, _Agg> agg = {};
    for (final wo in list) {
      final id = wo.assignedMechanicId ?? 'unassigned';
      final a = agg.putIfAbsent(id, () => _Agg());
      a.count += 1;
      a.hours += wo.estimatedHours ?? 0.0;
      // you can compute active hours only for non-completed if you like
    }

    final keys = agg.keys.toList()..sort();
    if (keys.isEmpty) {
      return const Center(child: Text('No work orders yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: keys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final mechId = keys[i];
        final a = agg[mechId]!;
        const capacity = 8.0; // fallback; replace with real staff.daily_capacity_hours
        final pct = (a.hours / capacity).clamp(0.0, 1.0);

        return Card(
          child: ListTile(
            title: Text(mechId == 'unassigned' ? 'Unassigned' : 'Mechanic: $mechId'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                LinearProgressIndicator(value: pct),
                const SizedBox(height: 6),
                Text('${a.count} orders • ${a.hours.toStringAsFixed(1)} / ${capacity.toStringAsFixed(1)} hrs'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'View orders',
              onPressed: () {
                // Optional: push a filtered list screen
              },
            ),
          ),
        );
      },
    );
  }
}

class _Agg {
  int count = 0;
  double hours = 0.0;
}
