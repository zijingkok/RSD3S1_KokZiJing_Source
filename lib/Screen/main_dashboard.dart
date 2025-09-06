import 'package:flutter/material.dart';

import '../Widget/bottom_NavigationBar.dart';
import '../Widget/app_bar.dart';
import 'Inventory/inventoryModule.dart';
import 'Inventory/inventory_dashboard.dart';
import 'Inventory/inventory_list.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0; // bottom nav





  //Here is where u put your screen----------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Dashboard'),
      body: IndexedStack(
        index: _index, // 0=Dashboard, 1=Vehicle, 2=Job, 3=CRM, 4=Inventory
        children: [
          _DashboardBody(),
          const Center(child: Text('Vehicle')),
          const Center(child: Text('Job')),
          const Center(child: Text('CRM')),

          const InventoryModule(), // go to inventory module
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
//Here is where u put your screen----------------------






class _DashboardBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeBorder = BorderSide(width: 1, color: const Color(0xFFB5B5B5));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16, 16, 16, 16 + kBottomNavigationBarHeight, // leave room for bottom bar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: const [
              Expanded(
                child: _StatCard(
                  title: 'Active Jobs',
                  value: '12',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Completed Jobs',
                  value: '256',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Feature Cards
          _FeatureCard(
            icon: Icons.directions_car_outlined,
            title: 'Vehicle Management',
            subtitle: 'Track Vehicle & Service History',
            border: themeBorder,
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.event_note_outlined,
            title: 'Job Scheduling',
            subtitle: 'Manage Appointment & Workflow',
            border: themeBorder,
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.person_outline,
            title: 'Customer Management',
            subtitle: 'CRM & customer database',
            border: themeBorder,
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory Management',
            subtitle: 'Parts and Supply Tracking',
            border: themeBorder,
          ),

          const SizedBox(height: 20),
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Activity Items
          _ActivityItem(
            title: 'Oil Change Completed',
            subtitle: 'Toyota GR 86 · Lim Kai Wei',
            timeAgo: '2h ago',
            border: themeBorder,
          ),
          const SizedBox(height: 12),
          _ActivityItem(
            title: 'New Appointment Scheduled',
            subtitle: 'Volkswagen Golf R · Kok Zi Jing',
            timeAgo: '4h ago',
            border: themeBorder,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFB5B5B5)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.black),
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
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
                  Text(title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
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
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFF3F4F6),
              child: Icon(Icons.build_outlined, color: Colors.black87, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            Text(timeAgo, style: const TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}
