import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/models/vehicle.dart';
import 'v_detail.dart';

class EnhancedVehicleSearchPage extends StatefulWidget {
  const EnhancedVehicleSearchPage({super.key});

  @override
  State<EnhancedVehicleSearchPage> createState() => _EnhancedVehicleSearchPageState();
}

class _EnhancedVehicleSearchPageState extends State<EnhancedVehicleSearchPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Vehicle> _allVehicles = [];
  List<Vehicle> _filteredVehicles = [];
  Set<String> _selectedVehicles = {};
  bool _isLoading = true;
  bool _isAdvancedSearch = false;

  // Filter states
  Set<String> _selectedStatuses = {};
  Set<String> _selectedMakes = {};
  Set<String> _selectedYears = {};
  RangeValues _mileageRange = const RangeValues(0, 200000);
  DateTime? _purchaseDateFrom;
  DateTime? _purchaseDateTo;
  DateTime? _createdDateFrom;
  DateTime? _createdDateTo;

  // Available options for filters
  List<String> _availableMakes = [];
  List<String> _availableYears = [];
  double _maxMileage = 200000;

  // Predefined filter presets
  final Map<String, Map<String, dynamic>> _filterPresets = {
    'All Active Vehicles': {
      'statuses': {'active'},
      'description': 'Show only active vehicles'
    },
    'High Mileage': {
      'mileageMin': 100000.0,
      'description': 'Vehicles with over 100,000 miles'
    },
    'Recent Additions': {
      'createdDaysAgo': 30,
      'description': 'Vehicles added in the last 30 days'
    },
    'German Brands': {
      'makes': {'BMW', 'Mercedes', 'Volkswagen'},
      'description': 'BMW, Mercedes, and Volkswagen vehicles'
    },
    'In Service': {
      'statuses': {'in-service'},
      'description': 'Vehicles currently being serviced'
    },
  };

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
          .order('created_at', ascending: false);

      _allVehicles = (response as List)
          .map((json) => Vehicle.fromJson(json))
          .toList();

      _buildFilterOptions();
      _applyFilters();

    } catch (e) {
      print('Error loading vehicles: $e');
      _showErrorSnackBar('Failed to load vehicles');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _buildFilterOptions() {
    // Extract unique makes
    _availableMakes = _allVehicles
        .map((v) => v.make)
        .toSet()
        .toList()
      ..sort();

    // Extract unique years
    _availableYears = _allVehicles
        .map((v) => v.year.toString())
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort years descending

    // Find max mileage for range slider
    _maxMileage = _allVehicles.isEmpty
        ? 200000
        : _allVehicles.map((v) => v.mileage.toDouble()).reduce((a, b) => a > b ? a : b);

    if (_maxMileage < 100000) _maxMileage = 200000; // Ensure reasonable max
    _mileageRange = RangeValues(0, _maxMileage);
  }

  void _applyFilters() {
    _filteredVehicles = _allVehicles.where((vehicle) {
      // Text search
      bool searchMatch = _searchController.text.isEmpty ||
          vehicle.plateNumber.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          vehicle.make.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          vehicle.model.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          vehicle.vin.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (vehicle.customerName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);

      // Status filter
      bool statusMatch = _selectedStatuses.isEmpty ||
          _selectedStatuses.contains(vehicle.status);

      // Make filter
      bool makeMatch = _selectedMakes.isEmpty ||
          _selectedMakes.contains(vehicle.make);

      // Year filter
      bool yearMatch = _selectedYears.isEmpty ||
          _selectedYears.contains(vehicle.year.toString());

      // Mileage range filter
      bool mileageMatch = vehicle.mileage >= _mileageRange.start &&
          vehicle.mileage <= _mileageRange.end;

      // Purchase date filter
      bool purchaseDateMatch = true;
      if (_purchaseDateFrom != null || _purchaseDateTo != null) {
        if (vehicle.purchaseDate != null) {
          if (_purchaseDateFrom != null && vehicle.purchaseDate!.isBefore(_purchaseDateFrom!)) {
            purchaseDateMatch = false;
          }
          if (_purchaseDateTo != null && vehicle.purchaseDate!.isAfter(_purchaseDateTo!)) {
            purchaseDateMatch = false;
          }
        } else {
          purchaseDateMatch = false;
        }
      }

      // Created date filter
      bool createdDateMatch = true;
      if (_createdDateFrom != null || _createdDateTo != null) {
        if (vehicle.createdAt != null) {
          if (_createdDateFrom != null && vehicle.createdAt!.isBefore(_createdDateFrom!)) {
            createdDateMatch = false;
          }
          if (_createdDateTo != null && vehicle.createdAt!.isAfter(_createdDateTo!)) {
            createdDateMatch = false;
          }
        } else {
          createdDateMatch = false;
        }
      }

      return searchMatch && statusMatch && makeMatch && yearMatch &&
          mileageMatch && purchaseDateMatch && createdDateMatch;
    }).toList();

    setState(() {});
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatuses.clear();
      _selectedMakes.clear();
      _selectedYears.clear();
      _mileageRange = RangeValues(0, _maxMileage);
      _purchaseDateFrom = null;
      _purchaseDateTo = null;
      _createdDateFrom = null;
      _createdDateTo = null;
      _selectedVehicles.clear();
    });
    _applyFilters();
  }

  void _applyPreset(String presetName) {
    _clearAllFilters();

    final preset = _filterPresets[presetName]!;

    setState(() {
      if (preset['statuses'] != null) {
        _selectedStatuses = Set<String>.from(preset['statuses']);
      }
      if (preset['makes'] != null) {
        _selectedMakes = Set<String>.from(preset['makes']);
      }
      if (preset['mileageMin'] != null) {
        _mileageRange = RangeValues(preset['mileageMin'], _maxMileage);
      }
      if (preset['createdDaysAgo'] != null) {
        _createdDateFrom = DateTime.now().subtract(Duration(days: preset['createdDaysAgo']));
      }
    });

    _applyFilters();

    _showSuccessSnackBar('Applied preset: $presetName');
  }

  void _toggleVehicleSelection(String vehicleId) {
    setState(() {
      if (_selectedVehicles.contains(vehicleId)) {
        _selectedVehicles.remove(vehicleId);
      } else {
        _selectedVehicles.add(vehicleId);
      }
    });
  }

  void _selectAllFiltered() {
    setState(() {
      _selectedVehicles.clear();
      _selectedVehicles.addAll(_filteredVehicles.map((v) => v.id!));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedVehicles.clear();
    });
  }

  Future<void> _bulkStatusUpdate(String newStatus) async {
    if (_selectedVehicles.isEmpty) {
      _showErrorSnackBar('No vehicles selected');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Status Update'),
        content: Text('Update ${_selectedVehicles.length} vehicles to "$newStatus" status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        for (String vehicleId in _selectedVehicles) {
          await _supabase
              .from('vehicles')
              .update({'status': newStatus})
              .eq('vehicle_id', vehicleId);
        }

        _showSuccessSnackBar('Updated ${_selectedVehicles.length} vehicles');
        _clearSelection();
        _loadVehicles();

      } catch (e) {
        _showErrorSnackBar('Failed to update vehicles: $e');
      }
    }
  }

  Future<void> _selectDate(bool isFrom, bool isPurchaseDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          if (isFrom) {
            _purchaseDateFrom = picked;
          } else {
            _purchaseDateTo = picked;
          }
        } else {
          if (isFrom) {
            _createdDateFrom = picked;
          } else {
            _createdDateTo = picked;
          }
        }
      });
      _applyFilters();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Vehicle Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicles,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllFilters,
            tooltip: 'Clear All Filters',
          ),
        ],
      ),
      body: Column(
        children: [
      // Search and Filter Controls
      Flexible(
      child: Container(
      child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Main search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by plate, make, model, VIN, or customer name',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(_isAdvancedSearch ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                      onPressed: () {
                        setState(() {
                          _isAdvancedSearch = !_isAdvancedSearch;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),

                if (_isAdvancedSearch) ...[
                  const SizedBox(height: 16),

                  // Filter Presets
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Quick Presets',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _filterPresets.keys.map((preset) {
                      return FilterChip(
                        label: Text(preset),
                        onSelected: (_) => _applyPreset(preset),
                        tooltip: _filterPresets[preset]!['description'],
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // Advanced Filters
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Advanced Filters',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Filter
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['active', 'inactive', 'in-service'].map((status) {
                      return FilterChip(
                        label: Text(status == 'in-service' ? 'In Service' : status.capitalize()),
                        selected: _selectedStatuses.contains(status),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStatuses.add(status);
                            } else {
                              _selectedStatuses.remove(status);
                            }
                          });
                          _applyFilters();
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Make Filter
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Make', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _availableMakes.map((make) {
                      return FilterChip(
                        label: Text(make),
                        selected: _selectedMakes.contains(make),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedMakes.add(make);
                            } else {
                              _selectedMakes.remove(make);
                            }
                          });
                          _applyFilters();
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Mileage Range
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Mileage Range', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  RangeSlider(
                    values: _mileageRange,
                    min: 0,
                    max: _maxMileage,
                    divisions: 20,
                    labels: RangeLabels(
                      '${_mileageRange.start.round()}',
                      '${_mileageRange.end.round()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _mileageRange = values;
                      });
                    },
                    onChangeEnd: (_) => _applyFilters(),
                  ),

                  const SizedBox(height: 16),

                  // Date Filters
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Purchase Date From', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _selectDate(true, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_formatDate(_purchaseDateFrom).isEmpty ? 'Select Date' : _formatDate(_purchaseDateFrom)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Purchase Date To', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _selectDate(false, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_formatDate(_purchaseDateTo).isEmpty ? 'Select Date' : _formatDate(_purchaseDateTo)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
    ),
      ),


          // Results and Bulk Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: const Border(
                top: BorderSide(color: Colors.grey, width: 0.5),
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Column(
              children: [
                // First row with results count
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Found ${_filteredVehicles.length} vehicle${_filteredVehicles.length != 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (_filteredVehicles.isNotEmpty && _selectedVehicles.isEmpty) ...[
                      TextButton(
                        onPressed: _selectAllFiltered,
                        child: const Text('Select All'),
                      ),
                    ],
                  ],
                ),
                // Second row with bulk actions (only show when vehicles are selected)
                if (_selectedVehicles.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedVehicles.length} vehicle${_selectedVehicles.length != 1 ? 's' : ''} selected',
                          style: const TextStyle(fontSize: 14, color: Colors.blue),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearSelection,
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Bulk Actions',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        onSelected: (value) => _bulkStatusUpdate(value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'active', child: Text('Mark as Active')),
                          const PopupMenuItem(value: 'inactive', child: Text('Mark as Inactive')),
                          const PopupMenuItem(value: 'in-service', child: Text('Mark as In Service')),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Vehicle List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVehicles.isEmpty
                ? const Center(
              child: Text(
                'No vehicles match your search criteria',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _filteredVehicles[index];
                final isSelected = _selectedVehicles.contains(vehicle.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Colors.blue : const Color(0xFFB5B5B5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleVehicleSelection(vehicle.id!),
                        ),
                        const Icon(Icons.directions_car, size: 24),
                      ],
                    ),
                    title: Text(
                      '${vehicle.plateNumber} - ${vehicle.make} ${vehicle.model}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Year: ${vehicle.year} • ${vehicle.mileage} miles'),
                        if (vehicle.customerName != null)
                          Text('Owner: ${vehicle.customerName}'),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(vehicle.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(vehicle.status)),
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
        ],
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
}

extension StringCapitalization on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}