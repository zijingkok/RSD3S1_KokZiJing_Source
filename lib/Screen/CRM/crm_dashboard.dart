import 'package:flutter/material.dart';
import 'crm_customer_detail.dart';
import 'crm_add_customer.dart';
import 'crm_history.dart';


class CrmDashboard extends StatefulWidget {
  const CrmDashboard({super.key});

  @override
  State<CrmDashboard> createState() => _CrmDashboardState();
}

class _CrmDashboardState extends State<CrmDashboard> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<Customer> _all = const [
    Customer(
      name: 'Cheng Siu',
      phone: '012-345 6789',
      email: 'chengxuy@gmail.com',
      gender: 'Male',
      dob: '22/07/2003',
      avatarAsset: 'assets/cheng_siu.jpg', // optional; use null if not available
      vehicles: [
        Vehicle(plate: 'ABC 1234', model: 'Toyota Vellfire V6'),
        Vehicle(plate: 'JKH 8618', model: 'Perodua Myvi'),
      ],
    ),
    Customer(
      name: 'Name',
      phone: '012-345 6789',
      email: 'name@example.com',
      gender: '—',
      dob: '—',
      vehicles: [],
    ),
    Customer(
      name: 'Kok Jing Jing',
      phone: '012-121 1212',
      email: 'kokjing@example.com',
      gender: '—',
      dob: '—',
      vehicles: [],
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeBorder = BorderSide(width: 1, color: Color(0xFFB5B5B5));
    final filtered = _all
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16, 16, 16, 16 + kBottomNavigationBarHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),

          // Total Customer Count
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: themeBorder,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827).withOpacity(.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 44, color: Colors.black87),
                  ),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Customer Count',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('69.2k',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search by Name',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
          const SizedBox(height: 18),

          const Text('Customer List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          // Add New Customer
// Add New Customer (inside CrmDashboard build)
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              side: themeBorder,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFF3F4F6),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFB5B5B5)),
                  ),
                  child: const Icon(Icons.add, size: 28, color: Colors.black87),
                ),
              ),
              title: const Text('Add New Customer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              onTap: () async {
                final created = await Navigator.push<Customer>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCustomerPage()),
                );
                if (created != null) {
                  setState(() => _all.insert(0, created)); // add to top
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${created.name}')),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 12),

          // Customers
          for (final c in filtered) ...[
            _CustomerTile(
              customer: c,
              border: themeBorder,
              onHistory: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomerHistoryPage(customer: c),
                  ),
                );
              },
              onDetails: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailPage(customer: c),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final BorderSide border;
  final VoidCallback onHistory;
  final VoidCallback onDetails;

  const _CustomerTile({
    required this.customer,
    required this.border,
    required this.onHistory,
    required this.onDetails,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            customer.avatarAsset != null
                ? CircleAvatar(radius: 28, backgroundImage: AssetImage(customer.avatarAsset!))
                : const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFF3F4F6),
              child: Icon(Icons.person, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(customer.phone,
                        style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
            ),
            _miniButton('History', onHistory, bg: const Color(0xFF111827)),
            const SizedBox(width: 8),
            _miniButton('Details', onDetails, bg: const Color(0xFF2E4A57)),
          ],
        ),
      ),
    );
  }

  Widget _miniButton(String label, VoidCallback onTap, {required Color bg}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        backgroundColor: bg,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

// ===== Shared models =====

class Customer {
  final String name;
  final String phone;
  final String email;
  final String gender;
  final String dob; // dd/MM/yyyy shown in UI
  final String? avatarAsset;
  final List<Vehicle> vehicles;

  const Customer({
    required this.name,
    required this.phone,
    required this.email,
    required this.gender,
    required this.dob,
    this.avatarAsset,
    this.vehicles = const [],
  });
}

class Vehicle {
  final String plate;
  final String model;
  const Vehicle({required this.plate, required this.model});
}
