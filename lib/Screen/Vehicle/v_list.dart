import 'package:flutter/material.dart';
import 'v_detail.dart';

class VehicleListPage extends StatefulWidget {
  const VehicleListPage({super.key});

  @override
  State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  String selectedStatus = "All"; // default filter
  final TextEditingController _searchController = TextEditingController();

  // Dummy data for now
  final List<Map<String, String>> vehicles = [
    {"plate": "ABC1234", "model": "Toyota GR 86", "status": "Active"},
    {"plate": "BXY5678", "model": "Honda Civic", "status": "Service"},
    {"plate": "WXY9999", "model": "Volkswagen Golf R", "status": "Inactive"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Vehicles")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Search + Filter Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by Plate or Model",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedStatus,
                  items: ["All", "Active", "Service", "Inactive"]
                      .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedStatus = value!);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 📋 Vehicle List
            Expanded(
              child: ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final v = vehicles[index];

                  // ✅ Apply search & filter
                  if (selectedStatus != "All" && v["status"] != selectedStatus) {
                    return const SizedBox.shrink();
                  }
                  if (_searchController.text.isNotEmpty &&
                      !v["plate"]!.toLowerCase().contains(_searchController.text.toLowerCase()) &&
                      !v["model"]!.toLowerCase().contains(_searchController.text.toLowerCase())) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFB5B5B5)),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFF3F4F6),
                        child: Icon(Icons.directions_car, color: Colors.black87),
                      ),
                      title: Text(v["plate"]!),
                      subtitle: Text(v["model"]!),
                      trailing: Text(v["status"]!,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VehicleDetailPage()),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
