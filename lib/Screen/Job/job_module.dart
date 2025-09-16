import 'package:flutter/material.dart';
import ' job_task_tab.dart';
import 'job_workload_tab.dart';

class JobModule extends StatelessWidget {
  const JobModule({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Work Scheduler'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Task'),
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
          onPressed: () {
            // optional: open Create/Assign Job flow
          },
          icon: const Icon(Icons.add),
          label: const Text('Assign Job'),
        ),
      ),
    );
  }
}
