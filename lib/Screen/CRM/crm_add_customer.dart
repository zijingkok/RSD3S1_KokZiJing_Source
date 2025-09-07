import 'package:flutter/material.dart';
import 'crm_dashboard.dart' show Customer;

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  DateTime? _dob;
  String _gender = 'Male';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  // ---------- UI helpers ----------
  InputDecoration _dec({String? hint}) => InputDecoration(
    hintText: hint,
    isDense: false,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB5B5B5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB5B5B5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.6),
    ),
  );

  String _formatDob(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<bool> _confirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFF0F172A),
                  child: const Icon(Icons.check, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Confirm Submit?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32), // green
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        child: const Text('Yes', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F), // red
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        child: const Text('No', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _onSubmitTap() async {
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields and DOB')),
      );
      return;
    }

    final ok = await _confirmDialog();
    if (!ok) return;

    final newCustomer = Customer(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      gender: _gender,
      dob: _formatDob(_dob!),
      avatarAsset: null,
      vehicles: const [],
    );

    Navigator.pop(context, newCustomer);
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final monthName = _dob == null ? 'July' : _months[_dob!.month - 1];
    final day = _dob?.day.toString().padLeft(2, '0') ?? '27';
    final year = (_dob?.year ?? 2002).toString();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // back
              Material(
                color: Colors.black87.withOpacity(.06),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // rounded white panel
              Container(
                width: double.infinity,
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
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text('New Customer Details',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 24),

                    const Text('Full Name',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _name,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: _dec(hint: 'Kok Jing Jing'),
                    ),
                    const SizedBox(height: 18),

                    const Text('Phone Number',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: _dec(hint: '012-121 1212'),
                    ),
                    const SizedBox(height: 18),

                    const Text('Date of Birth',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),

                    // calendar display as 3 boxes (read-only)
                    GestureDetector(
                      onTap: _pickDob,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              textAlign: TextAlign.center,
                              decoration: _dec(hint: day),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              textAlign: TextAlign.center,
                              decoration: _dec(hint: monthName),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              textAlign: TextAlign.center,
                              decoration: _dec(hint: year),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _pickDob,
                        child: Text(
                          _dob == null
                              ? 'Pick a date'
                              : 'Selected: ${_formatDob(_dob!)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text('Gender',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _gender = 'Male'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: _gender == 'Male'
                                  ? const Color(0xFF2E4A57)
                                  : Colors.white,
                              foregroundColor:
                              _gender == 'Male' ? Colors.white : Colors.black87,
                              side: BorderSide(
                                color: _gender == 'Male'
                                    ? const Color(0xFF2E4A57)
                                    : const Color(0xFFB5B5B5),
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Male', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _gender = 'Female'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: _gender == 'Female'
                                  ? const Color(0xFF2E4A57)
                                  : Colors.white,
                              foregroundColor: _gender == 'Female'
                                  ? Colors.white
                                  : Colors.black87,
                              side: BorderSide(
                                color: _gender == 'Female'
                                    ? const Color(0xFF2E4A57)
                                    : const Color(0xFFB5B5B5),
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child:
                            const Text('Female', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    const Text('Email',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: _dec(hint: 'zjingkok@gmail.com'),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onSubmitTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: const Text('Submit', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
