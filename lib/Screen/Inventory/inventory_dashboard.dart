import 'package:flutter/material.dart';

import '../../Models/inventory_summary.dart' ;
import '../../services/inventory_service.dart' ;

class InventoryDashboard extends StatefulWidget {
  const InventoryDashboard({super.key});

  @override
  State<InventoryDashboard> createState() => _InventoryDashboardState();
}

class _InventoryDashboardState extends State<InventoryDashboard> {
  late final InventoryService _service;
  late final Stream<InventorySummary> _summaryStream;

  @override
  void initState() {
    super.initState();
    _service = InventoryService();
    _summaryStream = _service.streamInventorySummary(); // 👈 stable stream
  }

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(width: 1, color: Color(0xFFB5B5B5));

    return StreamBuilder<InventorySummary>(
      stream: _summaryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No data available.'));
        }

        final data = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + kBottomNavigationBarHeight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text(
                'Inventory Dashboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Welcome back, Manager',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 18),
              const Text(
                'Inventory Overview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // 🔹 Realtime cards
              _OverviewCard(
                icon: Icons.inventory_2_outlined,
                title: 'Total Stocked Parts',
                value: data.totalStockedParts.toString(),
                hint: 'Total Parts across warehouses',
                border: border,
              ),
              const SizedBox(height: 12),
              _OverviewCard(
                icon: Icons.warning_amber_outlined,
                title: 'Low Stock Alerts',
                value: data.lowStockAlerts.toString(),
                hint: 'Require immediate attention',
                border: border,
              ),
              const SizedBox(height: 12),
              _OverviewCard(
                icon: Icons.schedule_outlined,
                title: 'Pending Procurement',
                value: data.pendingProcurement.toString(),
                hint: 'Awaiting approval',
                border: border,
              ),

              const SizedBox(height: 20),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                leading: Icons.view_list_outlined,
                title: 'View Inventory List',
                subtitle: 'Browse all parts and stock levels',
                border: border,
                onTap: () => Navigator.of(context).pushNamed('/list'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                leading: Icons.playlist_add_outlined,
                title: 'Request Stock',
                subtitle: 'Add on spare parts',
                border: border,
                onTap: () => Navigator.of(context).pushNamed('/request'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                leading: Icons.schedule_outlined,
                title: 'Pending Procurement',
                subtitle: 'Check request Status',
                border: border,
                onTap: () => Navigator.of(context).pushNamed('/status'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String hint;
  final BorderSide border;

  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.hint,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border.color),
              ),
              child: Icon(icon, size: 26, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData leading;
  final String title;
  final String subtitle;
  final BorderSide border;
  final VoidCallback onTap;

  const _ActionCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border.color),
                ),
                child: Icon(leading, size: 24, color: Colors.black87),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}
