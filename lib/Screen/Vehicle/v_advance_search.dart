import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/models/vehicle.dart';
import 'v_detail.dart';

class EnhancedVehicleSearchPage extends StatefulWidget {
  const EnhancedVehicleSearchPage({super.key});

  @override
  State<EnhancedVehicleSearchPage> createState() => _EnhancedVehicleSearchPageState();
}

class _EnhancedVehicleSearchPageState extends State<EnhancedVehicleSearchPage>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  late TabController _tabController;

  List<Vehicle> _allVehicles = [];
  List<Vehicle> _filteredVehicles = [];
  Set<String> _selectedVehicles = {};
  bool _isLoading = true;

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
    'All Active': {
      'statuses': {'active'},
      'description': 'Show only active vehicles'
    },
    'High Mileage': {
      'mileageMin': 100000.0,
      'description': 'Vehicles with over 100,000 miles'
    },
    'Recent': {
      'createdDaysAgo': 30,
      'description': 'Added in last 30 days'
    },
    'In Service': {
      'statuses': {'in-service'},
      'description': 'Currently being serviced'
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVehicles();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    _availableMakes = _allVehicles
        .map((v) => v.make)
        .toSet()
        .toList()
      ..sort();

    _availableYears = _allVehicles
        .map((v) => v.year.toString())
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    _maxMileage = _allVehicles.isEmpty
        ? 200000
        : _allVehicles.map((v) => v.mileage.toDouble()).reduce((a, b) => a > b ? a : b);

    if (_maxMileage < 100000) _maxMileage = 200000;
    _mileageRange = RangeValues(0, _maxMileage);
  }

  void _applyFilters() {
    _filteredVehicles = _allVehicles.where((vehicle) {
      bool searchMatch = _searchController.text.isEmpty ||
          vehicle.plateNumber.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          vehicle.make.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          vehicle.model.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          vehicle.vin.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (vehicle.customerName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);

      bool statusMatch = _selectedStatuses.isEmpty ||
          _selectedStatuses.contains(vehicle.status);

      bool makeMatch = _selectedMakes.isEmpty ||
          _selectedMakes.contains(vehicle.make);

      bool yearMatch = _selectedYears.isEmpty ||
          _selectedYears.contains(vehicle.year.toString());

      bool mileageMatch = vehicle.mileage >= _mileageRange.start &&
          vehicle.mileage <= _mileageRange.end;

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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters & Presets',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _clearAllFilters,
                        child: const Text('Clear All'),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Presets
                      const Text(
                        'Quick Presets',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _filterPresets.keys.map((preset) {
                          return ActionChip(
                            label: Text(preset),
                            onPressed: () {
                              _applyPreset(preset);
                              Navigator.pop(context);
                            },
                            backgroundColor: Colors.blue.shade50,
                            side: BorderSide(color: Colors.blue.shade200),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Status Filter
                      const Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
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

                      const SizedBox(height: 20),

                      // Make Filter
                      const Text('Vehicle Make', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
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

                      const SizedBox(height: 20),

                      // Mileage Range
                      const Text('Mileage Range', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 8),
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
                      Text(
                        '${_mileageRange.start.round()} - ${_mileageRange.end.round()} miles',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),

                      const SizedBox(height: 20),

                      // Date Filters
                      const Text('Purchase Date Range', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(true, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatDate(_purchaseDateFrom).isEmpty ? 'From Date' : _formatDate(_purchaseDateFrom),
                                        style: TextStyle(
                                          color: _formatDate(_purchaseDateFrom).isEmpty ? Colors.grey.shade600 : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(false, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatDate(_purchaseDateTo).isEmpty ? 'To Date' : _formatDate(_purchaseDateTo),
                                        style: TextStyle(
                                          color: _formatDate(_purchaseDateTo).isEmpty ? Colors.grey.shade600 : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedStatuses.isNotEmpty ||
        _selectedMakes.isNotEmpty ||
        _selectedYears.isNotEmpty ||
        _mileageRange.start > 0 ||
        _mileageRange.end < _maxMileage ||
        _purchaseDateFrom != null ||
        _purchaseDateTo != null ||
        _createdDateFrom != null ||
        _createdDateTo != null;
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
        title: const Text('Vehicle Search'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Search Results', icon: Icon(Icons.search)),
            Tab(text: 'Selection', icon: Icon(Icons.checklist)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicles,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (always visible)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search vehicles...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _hasActiveFilters() ? Colors.blue : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasActiveFilters() ? Colors.blue : Colors.grey.shade300,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: _hasActiveFilters() ? Colors.white : Colors.grey.shade600,
                    ),
                    onPressed: _showFilterBottomSheet,
                    tooltip: 'Filters & Presets',
                  ),
                ),
              ],
            ),
          ),

          // Results Count & Active Filters
          if (_hasActiveFilters() || _filteredVehicles.length != _allVehicles.length)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_filteredVehicles.length} of ${_allVehicles.length} vehicles',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_hasActiveFilters())
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Clear Filters'),
                    ),
                ],
              ),
            ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Search Results Tab
                _buildSearchResults(),

                // Selection Tab
                _buildSelectionView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredVehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No vehicles found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
    );
  }

  Widget _buildSelectionView() {
    final selectedVehiclesList = _allVehicles.where((v) => _selectedVehicles.contains(v.id)).toList();

    return Column(
      children: [
        // Selection Actions Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedVehicles.length} vehicle${_selectedVehicles.length != 1 ? 's' : ''} selected',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_filteredVehicles.isNotEmpty && _selectedVehicles.isEmpty)
                    TextButton(
                      onPressed: _selectAllFiltered,
                      child: const Text('Select All Filtered'),
                    ),
                  if (_selectedVehicles.isNotEmpty)
                    TextButton(
                      onPressed: _clearSelection,
                      child: const Text('Clear Selection'),
                    ),
                ],
              ),

              // Bulk Actions
              if (_selectedVehicles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _bulkStatusUpdate('active'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Mark Active', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _bulkStatusUpdate('in-service'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text('Mark In Service', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _bulkStatusUpdate('inactive'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Mark Inactive', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Selected Vehicles List
        Expanded(
          child: selectedVehiclesList.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checklist, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No vehicles selected',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Go to Search Results to select vehicles',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: selectedVehiclesList.length,
            itemBuilder: (context, index) {
              final vehicle = selectedVehiclesList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.blue, width: 2),
                ),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _toggleVehicleSelection(vehicle.id!),
                        tooltip: 'Remove from selection',
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