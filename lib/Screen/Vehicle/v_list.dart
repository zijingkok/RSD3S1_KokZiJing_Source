import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/models/vehicle.dart';
import 'v_detail.dart';

class VehicleListPage extends StatefulWidget {
  const VehicleListPage({super.key});

  @override
  State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = "All";
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .order('created_at', ascending: false);

      _vehicles = (response as List)
          .map((json) => Vehicle.fromJson(json))
          .toList();

      _applyFilters();

    } catch (e) {
      print('Error loading vehicles: $e');
      _showErrorSnackBar('Failed to load vehicles');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredVehicles = _vehicles.where((vehicle) {
      // Status filter
      bool statusMatch = _selectedStatus == "All" ||
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'in-service':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'in-service':
        return 'In Service';
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      default:
        return status;
    }
  }

  Future<void> _refreshVehicles() async {
    await _loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Vehicles"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshVehicles,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Search + Filter Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by Plate, Make, or Model",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    underline: const SizedBox(),
                    items: ["All", "Active", "In-Service", "Inactive"]
                        .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value!);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Results count
            Row(
              children: [
                Text(
                  'Found ${_filteredVehicles.length} vehicle${_filteredVehicles.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_vehicles.length != _filteredVehicles.length)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = "All";
                        _searchController.clear();
                      });
                      _applyFilters();
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // 📋 Vehicle List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredVehicles.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _vehicles.isEmpty
                          ? 'No vehicles found'
                          : 'No vehicles match your filters',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_vehicles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _refreshVehicles,
                child: ListView.builder(
                  itemCount: _filteredVehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _filteredVehicles[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFB5B5B5)),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFF3F4F6),
                          radius: 24,
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          vehicle.plateNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${vehicle.make} ${vehicle.model}'),
                            const SizedBox(height: 2),
                            Text('Year: ${vehicle.year} • ${vehicle.mileage} miles'),
                            if (vehicle.customerIc != null && vehicle.customerIc!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text('Owner: ${vehicle.customerIc}'),
                            ],
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(vehicle.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(vehicle.status),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getStatusDisplayText(vehicle.status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(vehicle.status),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VehicleDetailPage(vehicle: vehicle),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}