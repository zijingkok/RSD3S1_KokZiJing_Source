import 'package:flutter/material.dart';
import 'job_task_tab.dart';
import 'job_workload_tab.dart';
import '../../ui/crm_style.dart';

class JobModule extends StatelessWidget {
  const JobModule({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(

          elevation: 0,
          title: const Text('Work Scheduler', style: TextStyle(fontWeight: FontWeight.w600)),
          bottom: const TabBar(
              // keep tab highlight consistent
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
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

      ),
    );
  }
}
