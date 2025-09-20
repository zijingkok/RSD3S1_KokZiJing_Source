import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/models/vehicle.dart';

class EditVehiclePage extends StatefulWidget {
  final Vehicle vehicle;

  const EditVehiclePage({super.key, required this.vehicle});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _plateController;
  late TextEditingController _mileageController;
  late TextEditingController _ownerIcController;
  late TextEditingController _purchaseDateController;

  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  late String _selectedStatus;
  DateTime? _selectedPurchaseDate;
  File? _selectedImage;
  Map<String, dynamic>? _customerData;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _validateOwnerIc(); // Load initial customer data
  }

  void _initializeControllers() {
    _plateController = TextEditingController(text: widget.vehicle.plateNumber);
    _mileageController = TextEditingController(text: widget.vehicle.mileage.toString());
    _ownerIcController = TextEditingController(text: widget.vehicle.customerIc ?? '');

    // Initialize purchase date
    _selectedPurchaseDate = widget.vehicle.purchaseDate;
    _purchaseDateController = TextEditingController(
        text: widget.vehicle.purchaseDate != null
            ? "${widget.vehicle.purchaseDate!.day}/${widget.vehicle.purchaseDate!.month}/${widget.vehicle.purchaseDate!.year}"
            : ''
    );

    // Fix the status value to match dropdown items
    String vehicleStatus = widget.vehicle.status.toLowerCase();
    if (vehicleStatus == 'in-service') {
      _selectedStatus = 'in-service';
    } else if (vehicleStatus == 'active') {
      _selectedStatus = 'active';
    } else if (vehicleStatus == 'inactive') {
      _selectedStatus = 'inactive';
    } else {
      _selectedStatus = 'active'; // Default fallback
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _mileageController.dispose();
    _ownerIcController.dispose();
    _purchaseDateController.dispose();
    super.dispose();
  }

  Future<void> _selectPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPurchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedPurchaseDate) {
      setState(() {
        _selectedPurchaseDate = picked;
        _purchaseDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show dialog to choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_plateController.text.trim().replaceAll(' ', '_')}.jpg';

      await _supabase.storage
          .from('vehicle_image')
          .uploadBinary(fileName, bytes);

      final imageUrl = _supabase.storage
          .from('vehicle_image')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<void> _validateOwnerIc() async {
    if (_ownerIcController.text.trim().isEmpty) return;

    try {
      final response = await _supabase
          .from('customers')
          .select()
          .eq('ic_no', _ownerIcController.text.trim())
          .maybeSingle();

      setState(() {
        _customerData = response;
      });

      if (response == null) {
        _showErrorSnackBar('Customer with IC ${_ownerIcController.text.trim()} not found in system');
      } else if (mounted) {
        _showSuccessSnackBar('Customer found: ${response['full_name']}');
      }
    } catch (e) {
      print('Error validating owner IC: $e');
      _showErrorSnackBar('Failed to validate owner IC');
      setState(() {
        _customerData = null;
      });
    }
  }

  Future<void> _updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    if (_customerData == null) {
      _showErrorSnackBar('Please enter a valid Owner IC');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if plate number already exists (excluding current vehicle)
      final existingPlate = await _supabase
          .from('vehicles')
          .select('plate_number')
          .eq('plate_number', _plateController.text.trim())
          .neq('vehicle_id', widget.vehicle.id!)
          .maybeSingle();

      if (existingPlate != null) {
        _showErrorSnackBar('Plate number already exists in the system');
        return;
      }

      // Upload new image if selected
      String? vehicleImageUrl = widget.vehicle.vehicleImageUrl; // Keep existing image
      if (_selectedImage != null) {
        vehicleImageUrl = await _uploadImage();
      }

      // Prepare update data
      final updateData = {
        'plate_number': _plateController.text.trim(),
        'mileage': int.parse(_mileageController.text.trim()),
        'purchase_date': _selectedPurchaseDate?.toIso8601String().split('T')[0],
        'status': _selectedStatus,
        'customer_id': () {
          print('Customer data: $_customerData');
          print('Available keys: ${_customerData!.keys.toList()}');
          return _customerData!['customer_id'] ?? _customerData!['id'];
        }(),
        'vehicle_image_url': vehicleImageUrl,
      };

      // Update in database
      await _supabase
          .from('vehicles')
          .update(updateData)
          .eq('vehicle_id', widget.vehicle.id!);

      _showSuccessSnackBar('Vehicle updated successfully!');
      Navigator.pop(context, true); // Return true to indicate success

    } catch (e) {
      print('Error updating vehicle: $e');
      _showErrorSnackBar('Failed to update vehicle: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit Vehicle"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Read-only fields section
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock, color: Colors.grey.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Vehicle Information (Read-only)',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ReadOnlyField(label: "VIN", value: widget.vehicle.vin),
                      const SizedBox(height: 12),
                      _ReadOnlyField(label: "Make", value: widget.vehicle.make),
                      const SizedBox(height: 12),
                      _ReadOnlyField(label: "Model", value: widget.vehicle.model),
                      const SizedBox(height: 12),
                      _ReadOnlyField(label: "Year", value: widget.vehicle.year.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Editable fields section
              const Text(
                'Editable Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Plate Number
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: "Plate Number *",
                  hintText: "Enter Plate Number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? "Plate number is required" : null,
              ),
              const SizedBox(height: 16),

              // Mileage
              TextFormField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Mileage *",
                  hintText: "Enter in miles",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Mileage is required";
                  }
                  final mileage = int.tryParse(value);
                  if (mileage == null || mileage < 0) {
                    return "Please enter a valid mileage";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Purchase Date
              TextFormField(
                controller: _purchaseDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Purchase Date",
                  hintText: "Select purchase date",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectPurchaseDate,
                  ),
                ),
                onTap: _selectPurchaseDate,
              ),
              const SizedBox(height: 16),

              // Owner IC with validation
              TextFormField(
                controller: _ownerIcController,
                decoration: InputDecoration(
                  labelText: "Owner IC *",
                  hintText: "Enter Owner's IC",
                  helperText: "Must be registered customer",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _validateOwnerIc,
                  ),
                ),
                validator: (value) =>
                value!.isEmpty ? "Owner IC is required" : null,
                onFieldSubmitted: (_) => _validateOwnerIc(),
              ),
              const SizedBox(height: 8),

              // Customer info display
              if (_customerData != null)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Customer Found',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Name: ${_customerData!['full_name']}'),
                        Text('Phone: ${_customerData!['phone'] ?? 'N/A'}'),
                        Text('Email: ${_customerData!['email'] ?? 'N/A'}'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Status Dropdown
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: "Status *",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(value: 'in-service', child: Text('In Service')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                },
              ),
              const SizedBox(height: 16),

              // Vehicle Image Upload
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedImage != null || widget.vehicle.vehicleImageUrl != null
                        ? Colors.grey.shade100 : null,
                  ),
                  child: _selectedImage != null
                      ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'New Image',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                      : widget.vehicle.vehicleImageUrl != null
                      ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.vehicle.vehicleImageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Tap to change',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                      : _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text("Update Vehicle"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            "Upload Vehicle Image\n(Tap to select from camera or gallery)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}