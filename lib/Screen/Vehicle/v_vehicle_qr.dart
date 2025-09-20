import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '/models/vehicle.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VehicleQRPage extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleQRPage({super.key, required this.vehicle});

  @override
  State<VehicleQRPage> createState() => _VehicleQRPageState();
}

class _VehicleQRPageState extends State<VehicleQRPage> {
  String _selectedQRType = 'vehicle_id';
  bool _includeVehicleInfo = true;
  bool _includePlateNumber = true;
  bool _includeOwnerInfo = false;
  bool _includeVehicleImage = true;
  final GlobalKey _qrKey = GlobalKey();

  final Map<String, String> _qrTypes = {
    'vehicle_id': 'Vehicle ID Only',
    'vehicle_url': 'Vehicle Detail URL',
    'vehicle_info': 'Vehicle Information',
    'service_tag': 'Service Tag',
  };

  String _generateQRContent() {
    switch (_selectedQRType) {
      case 'vehicle_id':
        return widget.vehicle.id ?? '';

      case 'vehicle_url':
        return 'myworkshop://vehicle/${widget.vehicle.id}';

      case 'vehicle_info':
        final Map<String, dynamic> vehicleData = {};

        if (_includeVehicleInfo) {
          vehicleData.addAll({
            'id': widget.vehicle.id,
            'plate': widget.vehicle.plateNumber,
            'make': widget.vehicle.make,
            'model': widget.vehicle.model,
            'year': widget.vehicle.year,
            'vin': widget.vehicle.vin,
            'status': widget.vehicle.status,
          });
        }

        if (_includePlateNumber && !_includeVehicleInfo) {
          vehicleData['plate'] = widget.vehicle.plateNumber;
        }

        if (_includeOwnerInfo && widget.vehicle.customerName != null) {
          vehicleData.addAll({
            'owner_name': widget.vehicle.customerName,
            'owner_ic': widget.vehicle.customerIc,
            'owner_phone': widget.vehicle.customerPhone,
          });
        }

        final entries = vehicleData.entries
            .map((e) => '"${e.key}":"${e.value}"')
            .join(',');
        return '{$entries}';

      case 'service_tag':
        return 'SERVICE_TAG:${widget.vehicle.id}:${widget.vehicle.plateNumber}';

      default:
        return widget.vehicle.id ?? '';
    }
  }

  String _getQRDescription() {
    switch (_selectedQRType) {
      case 'vehicle_id':
        return 'Contains only the vehicle ID for secure database lookup';
      case 'vehicle_url':
        return 'Deep link URL to open vehicle details directly in the app';
      case 'vehicle_info':
        return 'Complete vehicle information encoded in JSON format';
      case 'service_tag':
        return 'Standardized service tag format for workshop operations';
      default:
        return '';
    }
  }

  Future<Uint8List?> _captureQRImage() async {
    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing QR image: $e');
      return null;
    }
  }

  void _copyToClipboard() {
    final content = _generateQRContent();
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('QR code content copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareQR() async {
    try {
      final imageBytes = await _captureQRImage();
      if (imageBytes != null) {
        // Save image to temporary directory
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/qr_code_${widget.vehicle.plateNumber}.png').create();
        await file.writeAsBytes(imageBytes);

        // Share the image file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'QR Code for ${widget.vehicle.plateNumber} - ${widget.vehicle.make} ${widget.vehicle.model}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.share, color: Colors.white),
                SizedBox(width: 8),
                Text('QR code shared successfully'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error sharing QR code: $e');
      _showErrorSnackBar('Failed to share QR code: ${e.toString()}');
    }
  }

  Future<void> _printQR() async {
    try {
      final imageBytes = await _captureQRImage();
      if (imageBytes != null) {
        // Create PDF document
        final pdf = pw.Document();

        // Convert image bytes to PDF image
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 50),
                  pw.Text(
                    'Vehicle QR Code',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    '${widget.vehicle.plateNumber} - ${widget.vehicle.make} ${widget.vehicle.model}',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Container(
                    width: 300,
                    height: 300,
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'QR Type: ${_qrTypes[_selectedQRType] ?? ''}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                ],
              );
            },
          ),
        );

        // Print the PDF
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'QR_Code_${widget.vehicle.plateNumber}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.print, color: Colors.white),
                SizedBox(width: 8),
                Text('QR code sent to printer'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error printing QR code: $e');
      _showErrorSnackBar('Failed to print QR code: ${e.toString()}');
    }
  }

// Alternative simpler share method (if you want to share just the content as text):
  Future<void> _shareQRAsText() async {
    try {
      final content = _generateQRContent();
      await Share.share(
        content,
        subject: 'QR Code Content for ${widget.vehicle.plateNumber}',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share QR content');
    }
  }



  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: _copyToClipboard,
            tooltip: 'Copy Content',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQR,
            tooltip: 'Share QR Code',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printQR,
            tooltip: 'Print QR Code',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Enhanced QR Code Display Card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Header with vehicle info and image
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle Image
                          if (_includeVehicleImage) ...[
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: widget.vehicle.vehicleImageUrl != null
                                    ? Image.network(
                                  widget.vehicle.vehicleImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholderImage();
                                  },
                                )
                                    : _buildPlaceholderImage(),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          // Vehicle Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.vehicle.plateNumber,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.vehicle.make} ${widget.vehicle.model}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Year: ${widget.vehicle.year}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (widget.vehicle.customerName != null)
                                  Text(
                                    'Owner: ${widget.vehicle.customerName}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                        ),
                        child: QrImageView(
                          data: _generateQRContent(),
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // QR Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Text(
                          _qrTypes[_selectedQRType] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Generated timestamp
                      Text(
                        'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Configuration Panel
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // QR Type Selection
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QR Code Type',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),

                          ..._qrTypes.entries.map((entry) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedQRType == entry.key
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  width: _selectedQRType == entry.key ? 2 : 1,
                                ),
                                color: _selectedQRType == entry.key
                                    ? Colors.blue.shade50
                                    : null,
                              ),
                              child: RadioListTile<String>(
                                title: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontWeight: _selectedQRType == entry.key
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: _selectedQRType == entry.key
                                    ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _getQRDescription(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                )
                                    : null,
                                value: entry.key,
                                groupValue: _selectedQRType,
                                activeColor: Colors.blue,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedQRType = value!;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Display Options
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Display Options',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),

                          SwitchListTile(
                            title: const Text('Include Vehicle Image'),
                            subtitle: const Text('Show vehicle photo in QR code layout'),
                            value: _includeVehicleImage,
                            onChanged: (value) {
                              setState(() {
                                _includeVehicleImage = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content Options (only for vehicle_info type)
                  if (_selectedQRType == 'vehicle_info') ...[
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Include in QR Code',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),

                            CheckboxListTile(
                              title: const Text('Vehicle Information'),
                              subtitle: const Text('ID, Plate, Make, Model, Year, VIN, Status'),
                              value: _includeVehicleInfo,
                              onChanged: (value) {
                                setState(() {
                                  _includeVehicleInfo = value!;
                                });
                              },
                            ),
                            if (!_includeVehicleInfo)
                              CheckboxListTile(
                                title: const Text('Plate Number Only'),
                                value: _includePlateNumber,
                                onChanged: (value) {
                                  setState(() {
                                    _includePlateNumber = value!;
                                  });
                                },
                              ),
                            CheckboxListTile(
                              title: const Text('Owner Information'),
                              subtitle: Text(widget.vehicle.customerName != null
                                  ? 'Name, IC, Phone'
                                  : 'No owner information available'),
                              value: _includeOwnerInfo,
                              onChanged: widget.vehicle.customerName != null
                                  ? (value) {
                                setState(() {
                                  _includeOwnerInfo = value!;
                                });
                              }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // QR Content Preview
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'QR Code Content',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: _copyToClipboard,
                                tooltip: 'Copy to Clipboard',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              _generateQRContent(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareQR,
                          icon: const Icon(Icons.share),
                          label: const Text('Share QR Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _printQR,
                          icon: const Icon(Icons.print),
                          label: const Text('Print QR Code'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Usage Instructions
                  Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.blue.shade200, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Usage Tips',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'â€¢ Print QR codes on durable labels for vehicle keys\n'
                                'â€¢ Use "Vehicle ID Only" for secure internal tracking\n'
                                'â€¢ "Service Tag" format works best for workshop bay management\n'
                                'â€¢ Include vehicle image for easy visual identification\n'
                                'â€¢ Share with customers for real-time service updates',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(
        Icons.directions_car,
        size: 32,
        color: Colors.grey.shade400,
      ),
    );
  }
}