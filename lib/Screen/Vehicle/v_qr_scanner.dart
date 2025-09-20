// v_qr_scanner.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/models/vehicle.dart';
import 'v_detail.dart';
import 'dart:convert';

class VehicleQRScannerPage extends StatefulWidget {
  const VehicleQRScannerPage({super.key});

  @override
  State<VehicleQRScannerPage> createState() => _VehicleQRScannerPageState();
}

class _VehicleQRScannerPageState extends State<VehicleQRScannerPage> {
  final _supabase = Supabase.instance.client;
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedData;
  Vehicle? _scannedVehicle;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String data) async {
    if (_isProcessing || data == _lastScannedData) return;

    setState(() {
      _isProcessing = true;
      _lastScannedData = data;
    });

    try {
      await _parseAndHandleQRData(data);
    } catch (e) {
      _showErrorDialog('Error processing QR code: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _parseAndHandleQRData(String data) async {
    if (data.isEmpty) {
      _showErrorDialog('QR code is empty');
      return;
    }

    // Check QR type and handle accordingly
    if (data.startsWith('myworkshop://vehicle/')) {
      // Vehicle URL format
      await _handleVehicleUrl(data);
    } else if (data.startsWith('SERVICE_TAG:')) {
      // Service tag format
      await _handleServiceTag(data);
    } else if (data.startsWith('{') && data.endsWith('}')) {
      // JSON vehicle info format
      await _handleVehicleInfo(data);
    } else {
      // Assume it's a vehicle ID
      await _handleVehicleId(data);
    }
  }

  Future<void> _handleVehicleUrl(String url) async {
    // Extract vehicle ID from URL: myworkshop://vehicle/{id}
    final vehicleId = url.split('/').last;
    await _loadVehicleById(vehicleId);
  }

  Future<void> _handleServiceTag(String serviceTag) async {
    // Format: SERVICE_TAG:vehicle_id:plate_number
    final parts = serviceTag.split(':');
    if (parts.length >= 2) {
      final vehicleId = parts[1];
      await _loadVehicleById(vehicleId);
    } else {
      _showErrorDialog('Invalid service tag format');
    }
  }

  Future<void> _handleVehicleInfo(String jsonData) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonData);

      if (data.containsKey('id')) {
        await _loadVehicleById(data['id']);
      } else if (data.containsKey('plate')) {
        await _loadVehicleByPlate(data['plate']);
      } else {
        _showScanResultDialog('Vehicle Information', _formatVehicleInfoFromJson(data));
      }
    } catch (e) {
      _showErrorDialog('Invalid JSON format in QR code');
    }
  }

  Future<void> _handleVehicleId(String vehicleId) async {
    await _loadVehicleById(vehicleId);
  }

  Future<void> _loadVehicleById(String vehicleId) async {
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
          .eq('vehicle_id', vehicleId)
          .single();

      final vehicle = Vehicle.fromJson(response);
      _navigateToVehicleDetail(vehicle);
    } catch (e) {
      _showErrorDialog('Vehicle not found with ID: $vehicleId');
    }
  }

  Future<void> _loadVehicleByPlate(String plateNumber) async {
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
          .eq('plate_number', plateNumber)
          .single();

      final vehicle = Vehicle.fromJson(response);
      _navigateToVehicleDetail(vehicle);
    } catch (e) {
      _showErrorDialog('Vehicle not found with plate: $plateNumber');
    }
  }

  String _formatVehicleInfoFromJson(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    if (data.containsKey('plate')) buffer.writeln('Plate: ${data['plate']}');
    if (data.containsKey('make')) buffer.writeln('Make: ${data['make']}');
    if (data.containsKey('model')) buffer.writeln('Model: ${data['model']}');
    if (data.containsKey('year')) buffer.writeln('Year: ${data['year']}');
    if (data.containsKey('vin')) buffer.writeln('VIN: ${data['vin']}');
    if (data.containsKey('status')) buffer.writeln('Status: ${data['status']}');
    if (data.containsKey('owner_name')) buffer.writeln('Owner: ${data['owner_name']}');
    if (data.containsKey('owner_phone')) buffer.writeln('Phone: ${data['owner_phone']}');

    return buffer.toString();
  }

  void _navigateToVehicleDetail(Vehicle vehicle) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailPage(vehicle: vehicle),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _lastScannedData = null; // Reset to allow rescanning
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showScanResultDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _lastScannedData = null; // Reset to allow rescanning
              });
            },
            child: const Text('Scan Again'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleFlashlight() {
    cameraController.toggleTorch();
  }

  void _switchCamera() {
    cameraController.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleFlashlight,
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle Flashlight',
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  _processQRCode(code);
                }
              }
            },
          ),

          // Scanning Overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            child: Stack(
              children: [
                // Scan area cutout
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),

                // Corner indicators
                Center(
                  child: SizedBox(
                    width: 250,
                    height: 250,
                    child: Stack(
                      children: [
                        // Top-left corner
                        Positioned(
                          top: -2,
                          left: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.green, width: 4),
                                left: BorderSide(color: Colors.green, width: 4),
                              ),
                            ),
                          ),
                        ),
                        // Top-right corner
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.green, width: 4),
                                right: BorderSide(color: Colors.green, width: 4),
                              ),
                            ),
                          ),
                        ),
                        // Bottom-left corner
                        Positioned(
                          bottom: -2,
                          left: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.green, width: 4),
                                left: BorderSide(color: Colors.green, width: 4),
                              ),
                            ),
                          ),
                        ),
                        // Bottom-right corner
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.green, width: 4),
                                right: BorderSide(color: Colors.green, width: 4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions and Status
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const Text(
                      'Position QR code within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported: Vehicle ID, Service Tags, Vehicle Info',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing QR Code...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Scanning will automatically open vehicle details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: Icons.flash_on,
                          label: 'Flash',
                          onTap: _toggleFlashlight,
                        ),
                        _ActionButton(
                          icon: Icons.cameraswitch,
                          label: 'Switch',
                          onTap: _switchCamera,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}