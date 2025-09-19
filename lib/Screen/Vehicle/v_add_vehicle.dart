import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/models/vehicle.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _mileageController = TextEditingController();
  final _vinController = TextEditingController();
  final _ownerIcController = TextEditingController();
  final _purchaseDateController = TextEditingController();

  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  DateTime? _selectedPurchaseDate;
  File? _selectedImage;
  Map<String, dynamic>? _customerData;

  // Lists for random generation
  final List<String> _carMakes = [
    'Honda', 'Toyota', 'Perodua', 'Proton', 'Nissan', 'Mazda',
    'Hyundai', 'Kia', 'Ford', 'Volkswagen', 'BMW', 'Mercedes'
  ];

  final Map<String, List<String>> _carModels = {
    'Honda': ['Civic', 'Accord', 'CR-V', 'City', 'HR-V', 'Jazz'],
    'Toyota': ['Camry', 'Corolla', 'Vios', 'Innova', 'Rush', 'Hilux'],
    'Perodua': ['Myvi', 'Axia', 'Bezza', 'Alza', 'Ativa', 'Aruz'],
    'Proton': ['Saga', 'Persona', 'Iriz', 'X50', 'X70', 'Exora'],
    'Nissan': ['Almera', 'Navara', 'X-Trail', 'Serena', 'Teana'],
    'Mazda': ['CX-5', 'CX-3', 'Mazda3', 'Mazda6', 'CX-30'],
    'Hyundai': ['Elantra', 'Tucson', 'Kona', 'i30', 'Santa Fe'],
    'Kia': ['Cerato', 'Sportage', 'Picanto', 'Rio', 'Sorento'],
    'Ford': ['Focus', 'Fiesta', 'Ranger', 'EcoSport', 'Everest'],
    'Volkswagen': ['Polo', 'Golf', 'Passat', 'Tiguan', 'Jetta'],
    'BMW': ['3 Series', '5 Series', 'X3', 'X5', '1 Series'],
    'Mercedes': ['C-Class', 'E-Class', 'GLC', 'A-Class', 'CLA']
  };

  @override
  void dispose() {
    _plateController.dispose();
    _mileageController.dispose();
    _vinController.dispose();
    _ownerIcController.dispose();
    _purchaseDateController.dispose();
    super.dispose();
  }

  String _generateRandomMake() {
    _carMakes.shuffle();
    return _carMakes.first;
  }

  String _generateRandomModel(String make) {
    final models = _carModels[make] ?? ['Model'];
    models.shuffle();
    return models.first;
  }

  int _generateRandomYear() {
    final currentYear = DateTime.now().year;
    final random = DateTime.now().millisecondsSinceEpoch % 15;
    return currentYear - 5 - random;
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
      } else {
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

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    if (_customerData == null) {
      _showErrorSnackBar('Please enter a valid Owner IC');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if VIN already exists
      final existingVin = await _supabase
          .from('vehicles')
          .select('vin')
          .eq('vin', _vinController.text.trim())
          .maybeSingle();

      if (existingVin != null) {
        _showErrorSnackBar('VIN already exists in the system');
        return;
      }

      // Check if plate number already exists
      final existingPlate = await _supabase
          .from('vehicles')
          .select('plate_number')
          .eq('plate_number', _plateController.text.trim())
          .maybeSingle();

      if (existingPlate != null) {
        _showErrorSnackBar('Plate number already exists in the system');
        return;
      }

      // Upload image if selected
      String? vehicleImageUrl;
      if (_selectedImage != null) {
        vehicleImageUrl = await _uploadImage();
      }

      // Generate random data
      final randomMake = _generateRandomMake();
      final randomModel = _generateRandomModel(randomMake);
      final randomYear = _generateRandomYear();

      // Prepare vehicle data for insert
      final vehicleData = {
        'vin': _vinController.text.trim(),
        'make': randomMake,
        'model': randomModel,
        'plate_number': _plateController.text.trim(),
        'year': randomYear,
        'mileage': int.parse(_mileageController.text.trim()),
        'purchase_date': _selectedPurchaseDate?.toIso8601String().split('T')[0],
        'status': 'active',
        'customer_id': () {
          print('Customer data: $_customerData');
          print('Available keys: ${_customerData!.keys.toList()}');
          return _customerData!['id'] ?? _customerData!['customer_id'];
        }(),
        'vehicle_image_url': vehicleImageUrl,
      };

      // Insert to database
      await _supabase
          .from('vehicles')
          .insert(vehicleData);

      _showSuccessSnackBar('Vehicle added successfully!');
      Navigator.pop(context, true);

    } catch (e) {
      print('Error adding vehicle: $e');
      _showErrorSnackBar('Failed to add vehicle: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add New Vehicle"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              // VIN
              TextFormField(
                controller: _vinController,
                decoration: const InputDecoration(
                  labelText: "VIN *",
                  hintText: "Enter Vehicle VIN",
                  helperText: "17 characters required",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "VIN is required";
                  }
                  if (value.length != 17) {
                    return "VIN must be 17 characters";
                  }
                  return null;
                },
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

              // Vehicle Image Upload - Fixed section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedImage != null ? Colors.grey.shade100 : null,
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
                    ],
                  )
                      : const Center(
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
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Card for auto-generated data
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Make, Model, and Year will be automatically generated',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveVehicle,
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
                          : const Text("Add Vehicle"),
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
}