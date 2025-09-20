import 'package:flutter/material.dart';
import 'package:workshop_management/Screen/Job/job_module.dart';

import '../Widget/bottom_NavigationBar.dart';
import '../Widget/app_bar.dart';
import 'CRM/crm_dashboard.dart';
import 'Inventory/inventoryModule.dart';
import 'Vehicle/v_dashboard.dart';

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
  static const _ink = Color(0xFF1D2A32);
  static const _muted = Color(0xFF6A7A88);

  @override
  Widget build(BuildContext context) {
    final borderSide = const BorderSide(color: _cardStroke, width: 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16, 12, 16, 16 + kBottomNavigationBarHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Row(
            children: const [
              Expanded(child: _StatCard(title: 'Active Jobs', value: '12')),
              SizedBox(width: 12),
              Expanded(child: _StatCard(title: 'Completed Jobs', value: '256')),
            ],
          ),
          const SizedBox(height: 16),

          // Feature Cards (tap to navigate to same pages as bottom bar)
          _FeatureCard(
            icon: Icons.directions_car_outlined,
            title: 'Vehicle Management',
            subtitle: 'Track Vehicle & Service History',
            onTap: () => onNavigateTab(1),
            border: borderSide,
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.assignment_outlined,
            title: 'Job Scheduling',
            subtitle: 'Manage Appointment & Workflow',
            onTap: () => onNavigateTab(2),
            border: borderSide,
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.people_alt_outlined,
            title: 'Customer Management',
            subtitle: 'CRM & customer database',
            onTap: () => onNavigateTab(3),
            border: borderSide,
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory Management',
            subtitle: 'Parts and Supply Tracking',
            onTap: () => onNavigateTab(4),
            border: borderSide,
          ),

          const SizedBox(height: 20),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),

          // Activity
          _ActivityItem(
            title: 'Oil Change Completed',
            subtitle: 'Toyota GR 86 · Lim Kai Wei',
            timeAgo: '2h ago',
            border: borderSide,
          ),
          const SizedBox(height: 12),
          _ActivityItem(
            title: 'New Appointment Scheduled',
            subtitle: 'Volkswagen Golf R · Kok Zi Jing',
            timeAgo: '4h ago',
            border: borderSide,
          ),
        ],
      ),
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
