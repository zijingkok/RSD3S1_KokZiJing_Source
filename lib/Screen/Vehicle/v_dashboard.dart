import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/models/vehicle.dart';
import 'v_add_vehicle.dart';
import 'v_list.dart';
import 'v_detail.dart';

class VehicleDashboard extends StatefulWidget {
  const VehicleDashboard({super.key});

  @override
  State<VehicleDashboard> createState() => _VehicleDashboardState();
}

class _VehicleDashboardState extends State<VehicleDashboard> with WidgetsBindingObserver {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';

  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  Map<String, int> _stats = {
    'total': 0,
    'active': 0,
    'in_service': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  // This method is called when the app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh data
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load recent vehicles with customer data for proper display
      final vehicleResponse = await _supabase
          .from('vehicles')
          .select('''
            *,
            customers (
              customer_id,
              full_name,
              ic_no,
              phone,
              email,
              gender,
              address
            )
          ''')
          .order('created_at', ascending: false)
          .limit(5);

      _vehicles = (vehicleResponse as List)
          .map((json) => Vehicle.fromJson(json))
          .toList();

      // Load stats - get all vehicles for accurate count
      final allVehiclesResponse = await _supabase
          .from('vehicles')
          .select('status');

      final allVehicles = (allVehiclesResponse as List);

      _stats = {
        'total': allVehicles.length,
        'active': allVehicles.where((v) => v['status'] == 'active').length,
        'in_service': allVehicles.where((v) => v['status'] == 'in-service').length,
      };

      _applyFilters();

    } catch (e) {
      print('Error loading dashboard data: $e');
      _showErrorSnackBar('Failed to load dashboard data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredVehicles = _vehicles.where((vehicle) {
      // Status filter
      bool statusMatch = _selectedStatus == 'All' ||
          vehicle.status.toLowerCase() == _selectedStatus.toLowerCase();

      // Search filter
      bool searchMatch = _searchController.text.isEmpty ||
          vehicle.plateNumber.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          vehicle.make.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          vehicle.model.toLowerCase().contains(_searchController.text.toLowerCase());

      return statusMatch && searchMatch;
    }).toList();

    setState(() {});
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _navigateToAddVehicle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehiclePage()),
    );

    if (result == true) {
      _loadDashboardData(); // Refresh data if vehicle was added
    }
  }

  Future<void> _navigateToVehicleList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VehicleListPage()),
    );

    // Always refresh after returning from vehicle list
    // since user might have edited/deleted vehicles there
    _loadDashboardData();
  }

  Future<void> _navigateToVehicleDetail(Vehicle vehicle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailPage(vehicle: vehicle),
      ),
    );

    // Refresh if vehicle was edited or deleted
    if (result == true) {
      _loadDashboardData();
    }
  }

  // Add pull-to-refresh functionality
  Future<void> _onRefresh() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(width: 1, color: Color(0xFFB5B5B5));

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when content is short
        padding: const EdgeInsets.fromLTRB(
          16, 16, 16, 16 + kBottomNavigationBarHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title with refresh button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vehicle Dashboard',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadDashboardData,
                  tooltip: 'Refresh Dashboard',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Quick Actions
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
                    onTap: _navigateToAddVehicle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.list_alt_outlined,
                    label: 'View All',
                    onTap: _navigateToVehicleList,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats Overview
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
                    title: 'Total\nRegistered',
                    value: '${_stats['total']}',
                    border: border,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.build_circle_outlined,
                    title: 'In Service\n',
                    value: '${_stats['in_service']}',
                    border: border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Vehicles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Added Vehicles',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: _navigateToVehicleList,
                  child: const Text(
                    'View all >',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search and filter bar
            Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search vehicles',
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB5B5B5), width: 1),
                    ),
                  ),
                  onChanged: (value) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                // Status filter
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB5B5B5), width: 1),
                    ),
                  ),
                  hint: const Text('Filter by Status'),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'in-service', child: Text('In Service')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value!);
                    _applyFilters();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vehicle List
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_filteredVehicles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No vehicles found',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              ..._filteredVehicles.map((vehicle) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _VehicleCard(
                  vehicle: vehicle,
                  onTap: () => _navigateToVehicleDetail(vehicle),
                ),
              )).toList(),
          ],
        ),
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
                  Text(
                    title,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 13, // Using the smaller font size
                      fontWeight: FontWeight.w600,
                      height: 1.2, // Adjusts line spacing for two lines
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    required this.onTap,
  });

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
        title: Text(vehicle.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Status: ${vehicle.status}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}