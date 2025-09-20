import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '/models/vehicle.dart';
import 'v_detail.dart';

class VehicleAnalyticsPage extends StatefulWidget {
  const VehicleAnalyticsPage({super.key});

  @override
  State<VehicleAnalyticsPage> createState() => _VehicleAnalyticsPageState();
}

class _VehicleAnalyticsPageState extends State<VehicleAnalyticsPage>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  bool _isLoading = true;
  List<Vehicle> _vehicles = [];
  List<Map<String, dynamic>> _workOrders = [];

  // Analytics data
  Map<String, int> _statusDistribution = {};
  Map<String, int> _makeDistribution = {};
  Map<String, int> _serviceFrequency = {};
  Map<String, double> _averageMileageByMake = {};
  List<Map<String, dynamic>> _agingVehicles = [];
  List<Map<String, dynamic>> _topServicedVehicles = [];
  List<Map<String, dynamic>> _monthlyStats = [];
  Map<String, int> _yearDistribution = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      // Load vehicles with customer data
      final vehiclesResponse = await _supabase
          .from('vehicles')
          .select('''
            *,
            customers (
              customer_id,
              full_name,
              ic_no,
              phone,
              email
            )
          ''');

      _vehicles = (vehiclesResponse as List)
          .map((json) => Vehicle.fromJson(json))
          .toList();

      // Load work orders for service analysis
      final workOrdersResponse = await _supabase
          .from('work_orders')
          .select('*');

      _workOrders = (workOrdersResponse as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      _calculateAnalytics();

    } catch (e) {
      print('Error loading analytics data: $e');
      _showErrorSnackBar('Failed to load analytics data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateAnalytics() {
    _calculateStatusDistribution();
    _calculateMakeDistribution();
    _calculateServiceFrequency();
    _calculateAverageMileageByMake();
    _calculateAgingVehicles();
    _calculateTopServicedVehicles();
    _calculateMonthlyStats();
    _calculateYearDistribution();
  }

  void _calculateStatusDistribution() {
    _statusDistribution.clear();
    for (var vehicle in _vehicles) {
      _statusDistribution[vehicle.status] =
          (_statusDistribution[vehicle.status] ?? 0) + 1;
    }
  }

  void _calculateMakeDistribution() {
    _makeDistribution.clear();
    for (var vehicle in _vehicles) {
      _makeDistribution[vehicle.make] =
          (_makeDistribution[vehicle.make] ?? 0) + 1;
    }
  }

  void _calculateServiceFrequency() {
    _serviceFrequency.clear();
    for (var workOrder in _workOrders) {
      final vehicleId = workOrder['vehicle_id'];
      if (vehicleId != null) {
        final vehicle = _vehicles.firstWhere(
              (v) => v.id == vehicleId,
          orElse: () => _vehicles.first,
        );
        final key = '${vehicle.make} ${vehicle.model}';
        _serviceFrequency[key] = (_serviceFrequency[key] ?? 0) + 1;
      }
    }
  }

  void _calculateAverageMileageByMake() {
    _averageMileageByMake.clear();
    Map<String, List<int>> mileagesByMake = {};

    for (var vehicle in _vehicles) {
      if (!mileagesByMake.containsKey(vehicle.make)) {
        mileagesByMake[vehicle.make] = [];
      }
      mileagesByMake[vehicle.make]!.add(vehicle.mileage);
    }

    mileagesByMake.forEach((make, mileages) {
      _averageMileageByMake[make] =
          mileages.reduce((a, b) => a + b) / mileages.length;
    });
  }

  void _calculateAgingVehicles() {
    final now = DateTime.now();
    final threeMonthsAgo = now.subtract(const Duration(days: 90));

    _agingVehicles = _vehicles.where((vehicle) {
      // Find last service date for this vehicle
      final vehicleWorkOrders = _workOrders
          .where((wo) => wo['vehicle_id'] == vehicle.id)
          .toList();

      if (vehicleWorkOrders.isEmpty) return true; // Never serviced

      vehicleWorkOrders.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });

      final lastServiceDate = DateTime.parse(vehicleWorkOrders.first['created_at']);
      return lastServiceDate.isBefore(threeMonthsAgo);
    }).map((vehicle) {
      final vehicleWorkOrders = _workOrders
          .where((wo) => wo['vehicle_id'] == vehicle.id)
          .toList();

      DateTime? lastServiceDate;
      if (vehicleWorkOrders.isNotEmpty) {
        vehicleWorkOrders.sort((a, b) {
          final dateA = DateTime.parse(a['created_at']);
          final dateB = DateTime.parse(b['created_at']);
          return dateB.compareTo(dateA);
        });
        lastServiceDate = DateTime.parse(vehicleWorkOrders.first['created_at']);
      }

      return {
        'vehicle': vehicle,
        'lastServiceDate': lastServiceDate,
        'daysSinceService': lastServiceDate != null
            ? now.difference(lastServiceDate).inDays
            : null,
      };
    }).toList();

    // Sort by days since service (longest first)
    _agingVehicles.sort((a, b) {
      final daysA = a['daysSinceService'] ?? 9999;
      final daysB = b['daysSinceService'] ?? 9999;
      return daysB.compareTo(daysA);
    });
  }

  void _calculateTopServicedVehicles() {
    Map<String, int> serviceCounts = {};

    for (var workOrder in _workOrders) {
      final vehicleId = workOrder['vehicle_id'];
      if (vehicleId != null) {
        serviceCounts[vehicleId] = (serviceCounts[vehicleId] ?? 0) + 1;
      }
    }

    _topServicedVehicles = serviceCounts.entries.map((entry) {
      final vehicle = _vehicles.firstWhere(
            (v) => v.id == entry.key,
        orElse: () => _vehicles.first,
      );
      return {
        'vehicle': vehicle,
        'serviceCount': entry.value,
      };
    }).toList();

    _topServicedVehicles.sort((a, b) =>
        b['serviceCount'].compareTo(a['serviceCount']));
    _topServicedVehicles = _topServicedVehicles.take(10).toList();
  }

  void _calculateMonthlyStats() {
    final now = DateTime.now();
    _monthlyStats.clear();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final vehiclesAdded = _vehicles.where((v) =>
      v.createdAt != null &&
          v.createdAt!.isAfter(month) &&
          v.createdAt!.isBefore(nextMonth)).length;

      final servicesCompleted = _workOrders.where((wo) {
        final createdAt = DateTime.parse(wo['created_at']);
        return createdAt.isAfter(month) && createdAt.isBefore(nextMonth);
      }).length;

      _monthlyStats.add({
        'month': _getMonthName(month.month),
        'vehiclesAdded': vehiclesAdded,
        'servicesCompleted': servicesCompleted,
      });
    }
  }

  void _calculateYearDistribution() {
    _yearDistribution.clear();
    for (var vehicle in _vehicles) {
      _yearDistribution[vehicle.year.toString()] =
          (_yearDistribution[vehicle.year.toString()] ?? 0) + 1;
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Charts', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Reports', icon: Icon(Icons.assignment)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildChartsTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Cards
          const Text(
            'Key Metrics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total Vehicles',
                  value: '${_vehicles.length}',
                  icon: Icons.directions_car,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Active Services',
                  value: '${_statusDistribution['in-service'] ?? 0}',
                  icon: Icons.build,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total Services',
                  value: '${_workOrders.length}',
                  icon: Icons.assignment,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Need Attention',
                  value: '${_agingVehicles.length}',
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status Distribution
          const Text(
            'Vehicle Status Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _statusDistribution.entries.map((entry) {
                  final percentage = (entry.value / _vehicles.length * 100);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(entry.key),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getStatusDisplayText(entry.key),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top Vehicle Makes
          const Text(
            'Popular Vehicle Makes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: (_makeDistribution.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                    .take(5)
                    .map((entry) {
                  final maxValue = _makeDistribution.values.reduce((a, b) => a > b ? a : b);
                  final percentage = entry.value / maxValue;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${entry.value} vehicles',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Pie Chart
          const Text(
            'Vehicle Status Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: PieChart(
                PieChartData(
                  sections: _statusDistribution.entries.map((entry) {
                    final percentage = entry.value / _vehicles.length * 100;
                    return PieChartSectionData(
                      color: _getStatusColor(entry.key),
                      value: entry.value.toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Monthly Trends Bar Chart
          const Text(
            'Monthly Trends (Last 6 Months)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _monthlyStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['vehiclesAdded'].toDouble(),
                          color: Colors.blue,
                          width: 16,
                        ),
                        BarChartRodData(
                          toY: data['servicesCompleted'].toDouble(),
                          color: Colors.green,
                          width: 16,
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _monthlyStats.length) {
                            return Text(
                              _monthlyStats[value.toInt()]['month'],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: Colors.blue, label: 'Vehicles Added'),
              const SizedBox(width: 20),
              _LegendItem(color: Colors.green, label: 'Services Completed'),
            ],
          ),
          const SizedBox(height: 24),

          // Average Mileage by Make
          const Text(
            'Average Mileage by Make',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: (_averageMileageByMake.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                    .map((entry) {
                  final maxMileage = _averageMileageByMake.values.reduce((a, b) => a > b ? a : b);
                  final percentage = entry.value / maxMileage;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${entry.value.toStringAsFixed(0)} miles',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aging Vehicles Report
          const Text(
            'Vehicles Needing Attention',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: _agingVehicles.take(10).map((item) {
                final Vehicle vehicle = item['vehicle'];
                final int? daysSince = item['daysSinceService'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getAgingColor(daysSince),
                    child: Text(
                      daysSince?.toString() ?? '∞',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '${vehicle.plateNumber} - ${vehicle.make} ${vehicle.model}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    daysSince != null
                        ? 'Last serviced $daysSince days ago'
                        : 'Never serviced',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VehicleDetailPage(vehicle: vehicle),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Most Serviced Vehicles
          const Text(
            'Most Serviced Vehicles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: _topServicedVehicles.map((item) {
                final Vehicle vehicle = item['vehicle'];
                final int serviceCount = item['serviceCount'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(
                      serviceCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '${vehicle.plateNumber} - ${vehicle.make} ${vehicle.model}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '$serviceCount service${serviceCount > 1 ? 's' : ''} completed',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VehicleDetailPage(vehicle: vehicle),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Service Frequency by Model
          const Text(
            'Service Frequency by Model',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: (_serviceFrequency.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                    .take(10)
                    .map((entry) {
                  final maxServices = _serviceFrequency.values.reduce((a, b) => a > b ? a : b);
                  final percentage = entry.value / maxServices;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${entry.value} services',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
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

  Color _getAgingColor(int? days) {
    if (days == null) return Colors.red;
    if (days > 180) return Colors.red;
    if (days > 90) return Colors.orange;
    return Colors.yellow.shade700;
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}