import 'package:flutter/material.dart';
import 'package:workshop_management/Screen/Job/job_module.dart';
import 'package:provider/provider.dart';

import '../Widget/bottom_NavigationBar.dart';
import '../Widget/app_bar.dart';
import 'CRM/crm_dashboard.dart';
import 'Inventory/inventoryModule.dart';
import 'Vehicle/v_dashboard.dart';
import '../Models/work_order.dart';
import '../state/work_order_store.dart';
import '../state/mechanic_store.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0; // 0=Dashboard, 1=Vehicle, 2=Job, 3=CRM, 4=Inventory

  void _goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(), // logo-only top bar (no title)
      body: IndexedStack(
        index: _index,
        children: [
          _DashboardBody(
            onNavigateTab: _goToTab, // <-- connect feature cards to tabs
          ),
          const VehicleDashboard(),
          const JobModule(),
          const CrmDashboard(),
          const InventoryModule(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: _goToTab,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;
  const _DashboardBody({required this.onNavigateTab});

  static const _cardStroke = Color(0xFFE6ECF1);

  @override
  Widget build(BuildContext context) {
    return Consumer2<WorkOrderStore, MechanicStore>(
      builder: (BuildContext context, WorkOrderStore woStore, MechanicStore mechStore, _) {
        final items = woStore.workOrders;

        // ---- Derived metrics ----
        int countCompleted = items.where((w) => w.status == WorkOrderStatus.completed).length;
        int countActive = items.length - countCompleted; // everything not completed
        int countOnHold = items.where((w) => w.status == WorkOrderStatus.onHold).length;
        int countUnassigned = items.where((w) => w.assignedMechanicId == null || w.assignedMechanicId!.isEmpty).length;

        // priority distribution
        int pHigh = items.where((w) => w.priority == WorkOrderPriority.high || w.priority == WorkOrderPriority.urgent).length;
        int pNormal = items.where((w) => w.priority == WorkOrderPriority.normal).length;
        int pLow = items.where((w) => w.priority == WorkOrderPriority.low).length;

        // simple progress (completed / total)
        final total = items.length == 0 ? 1 : items.length;
        final progress = countCompleted / total;

        // workload (active only), group by mechanic
        final Map<String?, int> byMech = {};
        for (final w in items.where((w) => w.status != WorkOrderStatus.completed)) {
          byMech[w.assignedMechanicId] = (byMech[w.assignedMechanicId] ?? 0) + 1;
        }
        // Top 3 rows: mechanic name (or Unassigned) + count
        final workloadRows = byMech.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topWorkload = workloadRows.take(3).toList();

        // recent activity: sort by updatedAt (fallback createdAt)
        final recent = [...items]..sort((a, b) {
          final ta = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tb = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
        });
        final recent5 = recent.take(5).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------- Top Counters --------
              Row(
                children: [
                  Expanded(child: _StatCard(title: 'Active Jobs', value: '$countActive')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: 'Completed Jobs', value: '$countCompleted')),
                ],
              ),
              const SizedBox(height: 10),
              // tiny progress
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: const Color(0xFFEFF3F6)),
              ),
              const SizedBox(height: 16),

              // -------- Priority chips --------
              _SectionCard(
                title: 'Priority',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: 'High/Urgent', count: pHigh, bg: const Color(0xFFFFF1F0)),
                    _Pill(label: 'Normal', count: pNormal, bg: const Color(0xFFF1F6FF)),
                    _Pill(label: 'Low', count: pLow, bg: const Color(0xFFF2FFF5)),
                    _Pill(label: 'Unassigned', count: countUnassigned, bg: const Color(0xFFFAF7FF)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // -------- Quick features (navigate to tabs) --------
              _FeatureCard(
                icon: Icons.directions_car_outlined,
                title: 'Vehicle Management',
                subtitle: 'Track Vehicle & Service History',
                onTap: () => onNavigateTab(1),
                border: const BorderSide(color: _cardStroke),
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.assignment_outlined,
                title: 'Job Scheduling',
                subtitle: 'Manage Appointment & Workflow',
                onTap: () => onNavigateTab(2),
                border: const BorderSide(color: _cardStroke),
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.people_alt_outlined,
                title: 'Customer Management',
                subtitle: 'CRM & customer database',
                onTap: () => onNavigateTab(3),
                border: const BorderSide(color: _cardStroke),
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.inventory_2_outlined,
                title: 'Inventory Management',
                subtitle: 'Parts and Supply Tracking',
                onTap: () => onNavigateTab(4),
                border: const BorderSide(color: _cardStroke),
              ),
              const SizedBox(height: 16),

              // -------- Mini workload --------
              _SectionCard(
                title: 'Mechanic Workload (active)',
                action: TextButton(
                  onPressed: () => onNavigateTab(2),
                  child: const Text('Open Jobs'),
                ),
                child: Column(
                  children: [
                    for (final e in topWorkload)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.engineering, size: 18, color: Color(0xFF6A7A88)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                mechStore.nameFor(e.key) ?? 'Unassigned',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text('${e.value}', style: const TextStyle(color: Color(0xFF6A7A88))),
                          ],
                        ),
                      ),
                    if (topWorkload.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No active jobs yet.'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // -------- Recent activity --------
              _SectionCard(
                title: 'Recent Activity',
                child: Column(
                  children: [
                    for (final w in recent5)
                      _ActivityItem(
                        title: w.title.isNotEmpty ? w.title : w.code,
                        subtitle: '${w.code} • ${_statusLabel(w.status)}',
                        timeAgo: _timeAgo(w.updatedAt ?? w.createdAt),
                        border: const BorderSide(color: Color(0xFFE6ECF1)), // add this line
                      ),
                    if (recent5.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No recent updates.'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  static String _statusLabel(WorkOrderStatus s) {
    switch (s) {
      case WorkOrderStatus.unassigned: return 'Unassigned';
      case WorkOrderStatus.scheduled: return 'Scheduled';
      case WorkOrderStatus.inProgress: return 'In-Progress';
      case WorkOrderStatus.onHold: return 'On-Hold';
      case WorkOrderStatus.completed: return 'Completed';
    }
  }

  static String _timeAgo(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// ---- small helpers used above ----

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _SectionCard({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE6ECF1)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
            if (action != null) action!,
          ]),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final int count;
  final Color bg;
  const _Pill({required this.label, required this.count, required this.bg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text('$label: $count', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
    );
  }
}


/* -------------------- Pieces -------------------- */

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6ECF1)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6A7A88),
              )),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2A32),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final BorderSide border;
  final VoidCallback onTap;
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: border,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border.color),
                ),
                child: Icon(icon, size: 26, color: const Color(0xFF1D2A32)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D2A32),
                        )),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6A7A88),
                        )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9AA6B2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeAgo;
  final BorderSide border;
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: border,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFF3F4F6),
              child: Icon(Icons.build_outlined, color: Color(0xFF1D2A32), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D2A32),
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6A7A88),
                      )),
                ],
              ),
            ),
            Text(timeAgo,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9AA6B2))),
          ],
        ),
      ),
    );
  }
}