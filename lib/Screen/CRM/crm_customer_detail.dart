import 'package:flutter/material.dart';
import 'crm_dashboard.dart' show Customer, Vehicle;
import 'crm_edit_profile.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (_) => EditCustomerPage(customer: _customer)),
    );
    if (updated != null) setState(() => _customer = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Scrollable body
          SingleChildScrollView(
            child: Column(
              children: [
                // Black cover
                Container(height: 220, color: Colors.black),

                // White card (like Edit page), not touching sides
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Avatar overlap (scrolls with content)
                              Positioned(
                                top: -70,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: CircleAvatar(
                                    radius: 70,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 66,
                                      backgroundColor: Colors.black87,
                                      backgroundImage: _customer.avatarAsset != null
                                          ? AssetImage(_customer.avatarAsset!)
                                          : null,
                                      child: _customer.avatarAsset == null
                                          ? const Icon(Icons.person,
                                          size: 64, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                ),
                              ),

                              // Card content
                              Padding(
                                padding:
                                const EdgeInsets.fromLTRB(20, 90, 20, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(
                                        _customer.name,
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    _InfoRow(
                                      leftLabel: 'Email',
                                      leftValue: _customer.email,
                                      rightLabel: 'Gender',
                                      rightValue: _customer.gender,
                                    ),
                                    const SizedBox(height: 18),
                                    _InfoRow(
                                      leftLabel: 'Phone Number',
                                      leftValue: _customer.phone,
                                      rightLabel: 'Date of Birth',
                                      rightValue: _customer.dob,
                                    ),
                                    const SizedBox(height: 28),

                                    const Text(
                                      'Registered Vehicle (Brand & Model)',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    if (_customer.vehicles.isEmpty)
                                      const Text('No vehicles added.',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54))
                                    else
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          for (final v in _customer.vehicles)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 6),
                                              child: Text(
                                                '${v.plate} (${v.model})',
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ),
                                        ],
                                      ),

                                    const SizedBox(height: 36),

                                    Center(
                                      child: SizedBox(
                                        width: 420,
                                        child: ElevatedButton(
                                          onPressed: _openEdit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            const Color(0xFF0F172A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(14),
                                            ),
                                            elevation: 2,
                                          ),
                                          child: const Text('Edit Profile',
                                              style:
                                              TextStyle(fontSize: 18)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Restored back button (floats at top-left)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.black.withOpacity(.7),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String leftLabel, leftValue, rightLabel, rightValue;
  const _InfoRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    Text _label(String t) =>
        Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
    Text _value(String t) =>
        Text(t, style: const TextStyle(fontSize: 18, color: Colors.black87));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(leftLabel),
                const SizedBox(height: 6),
                _value(leftValue),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(rightLabel),
                const SizedBox(height: 6),
                _value(rightValue),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
