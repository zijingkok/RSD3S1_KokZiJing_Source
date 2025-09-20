import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/models/vehicle.dart';
import 'v_edit_vehicle.dart';

class VehicleDetailPage extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final _supabase = Supabase.instance.client;
  late Vehicle _currentVehicle;
  bool _isLoading = false;
  bool _isCustomerDetailsExpanded = false;
  List<Map<String, dynamic>> _serviceHistory = [];

  @override
  void initState() {
    super.initState();
    _currentVehicle = widget.vehicle;
    _loadVehicleWithCustomer();
    _loadServiceHistory();
  }

  Future<void> _loadVehicleWithCustomer() async {
    setState(() => _isLoading = true);

    try {
      // Debug: Print the vehicle ID we're looking for
      print('Looking for vehicle with ID: ${_currentVehicle.id}');

      // Try method 1: Join query
      try {
        final response = await _supabase
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
            .eq('vehicle_id', _currentVehicle.id!)
            .single();

        print('Join query response: $response');

        setState(() {
          _currentVehicle = Vehicle.fromJson(response);
        });

        // If customer data is still null, try separate query
        if (_currentVehicle.customerName == null && _currentVehicle.customerId != null) {
          print('Join failed, trying separate query for customer_id: ${_currentVehicle.customerId}');
          await _loadCustomerSeparately();
        }

      } catch (joinError) {
        print('Join query failed: $joinError');

        // Method 2: Load vehicle first, then customer separately
        final vehicleResponse = await _supabase
            .from('vehicles')
            .select('*')
            .eq('vehicle_id', _currentVehicle.id!)
            .single();

        print('Vehicle only response: $vehicleResponse');

        setState(() {
          _currentVehicle = Vehicle.fromJson(vehicleResponse);
        });

        // Load customer separately
        if (_currentVehicle.customerId != null) {
          await _loadCustomerSeparately();
        }
      }

      // Debug: Print final parsed customer data
      print('Final parsed customer name: ${_currentVehicle.customerName}');
      print('Final parsed customer IC: ${_currentVehicle.customerIc}');

    } catch (e) {
      print('Error loading vehicle with customer: $e');
      _showErrorSnackBar('Failed to load vehicle details');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCustomerSeparately() async {
    try {
      final customerResponse = await _supabase
          .from('customers')
          .select('*')
          .eq('customer_id', _currentVehicle.customerId!)
          .single();

      print('Separate customer query response: $customerResponse');

      setState(() {
        _currentVehicle = _currentVehicle.copyWith(
          customerName: customerResponse['full_name'],
          customerIc: customerResponse['ic_no'],
          customerPhone: customerResponse['phone'],
          customerEmail: customerResponse['email'],
          customerGender: customerResponse['gender'],
          customerAddress: customerResponse['address'],
        );
      });

    } catch (e) {
      print('Error loading customer separately: $e');
    }
  }

  Future<void> _loadServiceHistory() async {
    setState(() => _isLoading = true);

    try {
      // For now, we'll use dummy data since work_orders table is not implemented yet
      // This is where you would load from work_orders table when ready
      _serviceHistory = [
        {
          'title': 'Alignment Service',
          'status': 'In-progress',
          'date': null,
        },
        {
          'title': 'Brake Pad Service',
          'status': 'Completed',
          'date': '28 Sept 2023',
        },
        {
          'title': 'Oil Changing Service',
          'status': 'Completed',
          'date': '11 Aug 2022',
        },
      ];

    } catch (e) {
      print('Error loading service history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshVehicleData() async {
    try {
      final response = await _supabase
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
          .eq('vehicle_id', _currentVehicle.id!)
          .single();

      setState(() {
        _currentVehicle = Vehicle.fromJson(response);
      });

    } catch (e) {
      print('Error refreshing vehicle data: $e');
      _showErrorSnackBar('Failed to refresh vehicle data');
    }
  }

  Future<void> _deleteVehicle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text('Are you sure you want to delete this vehicle? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await _supabase
            .from('vehicles')
            .delete()
            .eq('vehicle_id', _currentVehicle.id!);

        _showSuccessSnackBar('Vehicle deleted successfully');
        Navigator.pop(context, true); // Return to previous page

      } catch (e) {
        print('Error deleting vehicle: $e');
        _showErrorSnackBar('Failed to delete vehicle');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehiclePage(vehicle: _currentVehicle),
      ),
    );

    if (result == true) {
      _refreshVehicleData();
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final BorderSide border = const BorderSide(width: 1, color: Color(0xFFB5B5B5));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Vehicle', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _deleteVehicle();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _currentVehicle.vehicleImageUrl != null
                    ? Image.network(
                  _currentVehicle.vehicleImageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                )
                    : _buildPlaceholderImage(),
              ),
            ),
            const SizedBox(height: 12),

            // Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${_currentVehicle.year} ${_currentVehicle.make} ${_currentVehicle.model}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_currentVehicle.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getStatusColor(_currentVehicle.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusDisplayText(_currentVehicle.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(_currentVehicle.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mileage & Year Cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: "Mileage",
                    value: "${_currentVehicle.mileage.toString()} miles",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "Year",
                    value: _currentVehicle.year.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Vehicle Details
            const Text(
              "Vehicle Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: border,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: "Plate Number", value: _currentVehicle.plateNumber),
                    const SizedBox(height: 8),
                    _DetailRow(label: "Make", value: _currentVehicle.make),
                    const SizedBox(height: 8),
                    _DetailRow(label: "Model", value: _currentVehicle.model),
                    const SizedBox(height: 8),
                    if (_currentVehicle.purchaseDate != null) ...[
                      _DetailRow(
                          label: "Purchase Date",
                          value: "${_currentVehicle.purchaseDate!.day}/${_currentVehicle.purchaseDate!.month}/${_currentVehicle.purchaseDate!.year}"
                      ),
                      const SizedBox(height: 8),
                    ],
                    _DetailRow(label: "VIN", value: _currentVehicle.vin),
                    const SizedBox(height: 8),
                    _DetailRow(label: "Status", value: _getStatusDisplayText(_currentVehicle.status)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Customer Details Section
            const Text(
              "Owner Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: border,
              ),
              child: Column(
                children: [
                  // Header with expand/collapse button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isCustomerDetailsExpanded = !_isCustomerDetailsExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentVehicle.customerName ?? 'Owner Information',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            _isCustomerDetailsExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expandable content
                  if (_isCustomerDetailsExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_currentVehicle.customerName != null)
                            _DetailRow(label: "Full Name", value: _currentVehicle.customerName!),
                          if (_currentVehicle.customerName != null)
                            const SizedBox(height: 8),

                          if (_currentVehicle.customerIc != null)
                            _DetailRow(label: "IC Number", value: _currentVehicle.customerIc!),
                          if (_currentVehicle.customerIc != null)
                            const SizedBox(height: 8),

                          if (_currentVehicle.customerGender != null)
                            _DetailRow(label: "Gender", value: _currentVehicle.customerGender!),
                          if (_currentVehicle.customerGender != null)
                            const SizedBox(height: 8),

                          if (_currentVehicle.customerPhone != null)
                            _DetailRow(label: "Phone", value: _currentVehicle.customerPhone!),
                          if (_currentVehicle.customerPhone != null)
                            const SizedBox(height: 8),

                          if (_currentVehicle.customerEmail != null)
                            _DetailRow(label: "Email", value: _currentVehicle.customerEmail!),
                          if (_currentVehicle.customerEmail != null)
                            const SizedBox(height: 8),

                          if (_currentVehicle.customerAddress != null)
                            _DetailRow(label: "Address", value: _currentVehicle.customerAddress!),

                          // Show message if no customer data
                          if (_currentVehicle.customerName == null &&
                              _currentVehicle.customerIc == null &&
                              _currentVehicle.customerPhone == null &&
                              _currentVehicle.customerEmail == null) ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No customer information available',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Service History
            const Text(
              "Service History",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            ..._serviceHistory.map((service) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ServiceCard(
                title: service['title'],
                status: service['status'],
                date: service['date'],
                border: border,
              ),
            )).toList(),

            if (_serviceHistory.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: border,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No service history available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(color: Colors.grey),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500))),
        Expanded(
            flex: 3,
            child: Text(value,
                style: const TextStyle(fontSize: 14, color: Colors.black54))),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String? date;
  final String status;
  final BorderSide border;

  const _ServiceCard({
    required this.title,
    required this.status,
    this.date,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: border,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  if (date != null) ...[
                    const SizedBox(height: 6),
                    Text(date!,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                  ],
                ],
              ),
            ),
            Text(status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: status == "Completed"
                      ? Colors.green
                      : Colors.orange,
                )),
          ],
        ),
      ),
    );
  }
}