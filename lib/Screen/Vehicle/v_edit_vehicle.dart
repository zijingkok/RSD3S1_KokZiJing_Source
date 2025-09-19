import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _mileageController;
  late TextEditingController _vinController;
  late TextEditingController _ownerIcController;

  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _plateController = TextEditingController(text: widget.vehicle.plateNumber);
    _makeController = TextEditingController(text: widget.vehicle.make);
    _modelController = TextEditingController(text: widget.vehicle.model);
    _yearController =
        TextEditingController(text: widget.vehicle.year.toString());
    _mileageController =
        TextEditingController(text: widget.vehicle.mileage.toString());
    _vinController = TextEditingController(text: widget.vehicle.vin);
    _ownerIcController =
        TextEditingController(text: widget.vehicle.customerIc ?? '');

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
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _vinController.dispose();
    _ownerIcController.dispose();
    super.dispose();
  }

  Future<void> _updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check if VIN already exists (excluding current vehicle)
      final existingVin = await _supabase
          .from('vehicles')
          .select('vin')
          .eq('vin', _vinController.text.trim())
          .neq('id', widget.vehicle.id!)
          .maybeSingle();

      if (existingVin != null) {
        _showErrorSnackBar('VIN already exists in the system');
        return;
      }

      // Check if plate number already exists (excluding current vehicle)
      final existingPlate = await _supabase
          .from('vehicles')
          .select('plate_number')
          .eq('plate_number', _plateController.text.trim())
          .neq('id', widget.vehicle.id!)
          .maybeSingle();

      if (existingPlate != null) {
        _showErrorSnackBar('Plate number already exists in the system');
        return;
      }

      // Prepare update data
      final updateData = {
        'vin': _vinController.text.trim(),
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'plate_number': _plateController.text.trim(),
        'year': int.parse(_yearController.text.trim()),
        'mileage': int.parse(_mileageController.text.trim()),
        'status': _selectedStatus,
        'owner_ic': _ownerIcController.text.trim(),
      };

      // Update in database
      await _supabase
          .from('vehicles')
          .update(updateData)
          .eq('id', widget.vehicle.id!);

      _showSuccessSnackBar('Vehicle updated successfully!');
      Navigator.pop(context, true); // Return true to indicate success

    } catch (e) {
      print('Error updating vehicle: $e');
      _showErrorSnackBar('Failed to update vehicle. Please try again.');
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

              // Make
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(
                  labelText: "Make *",
                  hintText: "e.g. Honda, Toyota, Perodua",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? "Make is required" : null,
              ),
              const SizedBox(height: 16),

              // Model
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: "Model *",
                  hintText: "e.g. Civic, Myvi, Camry",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? "Model is required" : null,
              ),
              const SizedBox(height: 16),

              // Year
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Year *",
                  hintText: "e.g. 2020",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Year is required";
                  }
                  final year = int.tryParse(value);
                  if (year == null) {
                    return "Please enter a valid year";
                  }
                  final currentYear = DateTime
                      .now()
                      .year;
                  if (year < 1900 || year > currentYear + 1) {
                    return "Please enter a valid year between 1900 and ${currentYear +
                        1}";
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

              // Owner IC
              TextFormField(
                controller: _ownerIcController,
                decoration: const InputDecoration(
                  labelText: "Owner IC *",
                  hintText: "Enter Owner's IC",
                  helperText: "Must be registered",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? "Owner IC is required" : null,
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
                  DropdownMenuItem(
                      value: 'in-service', child: Text('In Service')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                },
              ),
              const SizedBox(height: 16),

              // Vehicle Image Upload (placeholder)
              GestureDetector(
                onTap: () {
                  // TODO: implement image picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image upload coming soon!')),
                  );
                },
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text("Update Vehicle Image\n(png/jpg only)",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                  ),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                      )
                          : const Text("Update Vehicle"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () =>
                          Navigator.pop(context),
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