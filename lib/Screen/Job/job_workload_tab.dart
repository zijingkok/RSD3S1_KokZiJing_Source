import 'package:flutter/material.dart';

class JobWorkloadTab extends StatelessWidget {
  const JobWorkloadTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data — replace with real aggregation later
    final mechanics = [
      {'name':'Ali','assigned':5,'hours':6.0,'capacity':8.0},
      {'name':'Siti','assigned':2,'hours':3.0,'capacity':8.0},
      {'name':'John','assigned':7,'hours':8.0,'capacity':8.0},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: mechanics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = mechanics[i];
        final pct = (m['hours'] as double) / (m['capacity'] as double);
        final over = pct >= 1.0;
        return Card(
          child: ListTile(
            title: Text(m['name'] as String),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                LinearProgressIndicator(value: pct.clamp(0.0, 1.0)),
                const SizedBox(height: 6),
                Text('${m['assigned']} jobs • ${m['hours']}h / ${m['capacity']}h',
                    style: TextStyle(color: over ? Colors.red : Colors.black54)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: () {
                // optional: drill into this mechanic’s jobs
              },
              tooltip: 'View assigned jobs',
            ),
          ),
        );
      },
    );
  }
}
