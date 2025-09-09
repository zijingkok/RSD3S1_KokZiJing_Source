import 'package:flutter/material.dart';

class VehicleDetailPage extends StatelessWidget {
  const VehicleDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final BorderSide border = const BorderSide(width: 1, color: Color(0xFFB5B5B5));

    return Scaffold(
      appBar: AppBar(title: const Text("Vehicle Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🚗 Vehicle Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/yigayhead.jpg',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            const Text(
              "2017 Perodua Myvi 1.5v",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // 📊 Mileage & Year Cards
            Row(
              children: const [
                Expanded(
                  child: _StatCard(
                    title: "Mileage",
                    value: "45,230 miles",
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "Year",
                    value: "2017",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 👤 Ownership Details
            const Text(
              "Ownership Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: border,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _DetailRow(label: "Owner", value: "Lim Kai Wei"),
                    SizedBox(height: 8),
                    _DetailRow(label: "Purchase Date", value: "15 Mar 2018"),
                    SizedBox(height: 8),
                    _DetailRow(label: "VIN", value: "WBA3A9C57DF477888"),
                    SizedBox(height: 8),
                    _DetailRow(label: "Status", value: "Active"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🛠 Service History
            const Text(
              "Service History",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            _ServiceCard(
              title: "Alignment Service",
              status: "In-progressing",
              date: null,
              border: border,
            ),
            const SizedBox(height: 12),

            _ServiceCard(
              title: "Brake Pad Service",
              status: "Completed",
              date: "28 Sept 2023",
              border: border,
            ),
            const SizedBox(height: 12),

            _ServiceCard(
              title: "Oil Changing Service",
              status: "Completed",
              date: "11 Aug 2022",
              border: border,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFB5B5B5)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500))),
        Expanded(
            flex: 3,
            child: Text(value,
                style: const TextStyle(fontSize: 14, color: Colors.black54))),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String? date;
  final String status;
  final BorderSide border;

  const _ServiceCard({
    required this.title,
    required this.status,
    this.date,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: border,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  if (date != null) ...[
                    const SizedBox(height: 6),
                    Text(date!,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                  ],
                ],
              ),
            ),
            Text(status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: status == "Completed"
                      ? Colors.green
                      : Colors.orange,
                )),
          ],
        ),
      ),
    );
  }
}
