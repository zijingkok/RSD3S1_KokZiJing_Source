import 'package:flutter/material.dart';

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

              // Vehicle Image Upload (placeholder)
              GestureDetector(
                onTap: () {
                  // TODO: implement image picker
                },
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text("Upload Vehicle Image\n(png/jpg only)",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mileage
              TextFormField(
                controller: _mileageController,
                decoration: const InputDecoration(
                  labelText: "Mileage *",
                  hintText: "Enter in miles",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? "Mileage is required" : null,
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
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // TODO: Save vehicle logic
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Add Vehicle"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red,
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

