import 'package:flutter/material.dart';
import 'v_add_vehicle.dart';
import 'v_list.dart';
import 'v_detail.dart';



class VehicleDashboard extends StatelessWidget {
  const VehicleDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(width: 1, color: Color(0xFFB5B5B5));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16, 16, 16, 16 + kBottomNavigationBarHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          const Text(
            'Vehicle Dashboard',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),

          // ⚡ Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.add_circle_outline,
                  label: 'Add Vehicle',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddVehiclePage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.list_alt_outlined,
                  label: 'View All',

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VehicleListPage()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 📊 Stats Overview
          const Text(
            'Stats Overview',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.directions_car_filled_outlined,
                  title: 'Total Registered',
                  value: '127', // replace with dynamic data later
                  border: border,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.build_circle_outlined,
                  title: 'Serviced This Month',
                  value: '42',
                  border: border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 🚗 Recent Vehicles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Added Vehicles',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VehicleListPage()),
                  );
                },
                child: const Text(
                  'View all >',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
// 🚗 Search and filter bar
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search vehicles',
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFB5B5B5), width: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFFB5B5B5), width: 1),
                    ),
                  ),
                  hint: const Text('Status'),
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Serviced', child: Text('Serviced')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                  ],
                  onChanged: (value) {
                    // TODO: implement filter logic
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _VehicleCard(title: 'PERODUA MYVI VGE 6639'),
          const SizedBox(height: 10),
          _VehicleCard(title: 'PERODUA MYVI JKH 8618'),
          const SizedBox(height: 10),
          _VehicleCard(title: 'HONDA CITY AKE 7967'),
        ],
      ),
    );
  }
}

// ------------------- Widgets -------------------

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFB5B5B5), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.black87),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final BorderSide border;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border.color),
              ),
              child: Icon(icon, size: 24, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final String title;
  const _VehicleCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFB5B5B5), width: 1),
      ),
      child: ListTile(
        leading: const Icon(Icons.directions_car, size: 32, color: Colors.black87),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.edit, color: Colors.black54),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VehicleDetailPage()),
          );
        },
      ),
    );
  }
}
