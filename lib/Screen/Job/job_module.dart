import 'package:flutter/material.dart';
import 'job_task_tab.dart';
import 'job_workload_tab.dart';

class JobModule extends StatelessWidget {
  const JobModule({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Work Orders'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tasks'),
              Tab(text: 'Workload'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            JobTaskTab(),
            JobWorkloadTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            // optional quick-create flow; for now assignment happens per row menu
          },
          icon: const Icon(Icons.add),
          label: const Text('Assign'),
        ),
      ),
    );
  }
}
