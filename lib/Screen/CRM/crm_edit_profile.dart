import 'package:flutter/material.dart';
import '../../Models/customer.dart';

/// Edit DB Customer
class EditCustomerPage extends StatefulWidget {
  final Customer customer;
  const EditCustomerPage({super.key, required this.customer});

  @override
  State<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  late final TextEditingController _fullName;
  late final TextEditingController _icNo;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;

  // gender is nullable in DB; default to '' (blank)
  late String _gender;

  // ---- Shared palette  ----
  static const _bg = Color(0xFFF5F7FA);
  static const _ink = Color(0xFF1D2A32);
  static const _muted = Color(0xFF6A7A88);
  static const _card = Colors.white;
  static const _primary = Color(0xFF1E88E5);
  static const _primaryDark = Color(0xFF1565C0);
  static const _stroke = Color(0xFFE6ECF1);

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.customer.fullName);
    _icNo     = TextEditingController(text: widget.customer.icNo ?? '');
    _phone    = TextEditingController(text: widget.customer.phone ?? '');
    _email    = TextEditingController(text: widget.customer.email ?? '');
    _address  = TextEditingController(text: widget.customer.address ?? '');
    _gender   = widget.customer.gender ?? ''; // '', 'Male', 'Female', 'Other'
  }

  @override
  void dispose() {
    _fullName.dispose();
    _icNo.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  ThemeData _localTheme(BuildContext context) {
    final base = Theme.of(context);
    final tuned = base.textTheme
        .copyWith(
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.3),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    )
        .apply(bodyColor: _ink, displayColor: _ink);

    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: _bg,
      textTheme: tuned,
      colorScheme: base.colorScheme.copyWith(primary: _primary, secondary: _primary),
      dividerColor: _stroke,
      appBarTheme: AppBarTheme(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: tuned.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintStyle: TextStyle(color: _muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        contentTextStyle: tuned.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _save() {
    // minimal validation — require full name and phone
    if (_fullName.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Full Name and Phone')),
      );
      return;
    }

    final updated = Customer(
      id: widget.customer.id,
      fullName: _fullName.text.trim(),
      icNo: _icNo.text.trim().isEmpty ? null : _icNo.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      gender: _gender.isEmpty ? null : _gender,
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      createdAt: widget.customer.createdAt,
      updatedAt: widget.customer.updatedAt,
    );

    Navigator.pop(context, updated); // caller handles CustomerService.update(...)
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _localTheme(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600), // slightly smaller form
                child: Container(
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    border: const Border.fromBorderSide(BorderSide(color: _stroke)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0F000000), blurRadius: 22, offset: Offset(0, 10)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Edit Profile Details',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 18),

                      const _FieldLabel('Full Name'),
                      TextField(
                        controller: _fullName,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(hintText: 'Full name'),
                      ),
                      const SizedBox(height: 16),

                      const _FieldLabel('IC No'),
                      TextField(
                        controller: _icNo,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(hintText: 'e.g. 010203-10-1234'),
                      ),
                      const SizedBox(height: 16),

                      const _FieldLabel('Phone'),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(hintText: '012-345 6789'),
                      ),
                      const SizedBox(height: 16),

                      const _FieldLabel('Email'),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(hintText: 'name@example.com'),
                      ),
                      const SizedBox(height: 16),

                      const _FieldLabel('Gender'),
                      DropdownButtonFormField<String>(
                        value: _gender.isEmpty ? null : _gender,
                        isExpanded: true,
                        icon: const SizedBox.shrink(), // keep it minimal (no arrow icon)
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _gender = v ?? ''),
                        decoration: const InputDecoration(hintText: 'Select gender'),
                      ),
                      const SizedBox(height: 16),

                      const _FieldLabel('Address'),
                      TextField(
                        controller: _address,
                        minLines: 2,
                        maxLines: 4,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(hintText: 'Street, city, state, postcode'),
                      ),

                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: _PrimaryButton(
                              label: 'Save',
                              onPressed: _save,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SoftButton(
                              label: 'Cancel',
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- Small UI bits (consistent with other screens) ---------- */

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
  );
}

class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const _PrimaryButton({required this.onPressed, required this.label});

  static const _primary = _EditCustomerPageState._primary;
  static const _primaryDark = _EditCustomerPageState._primaryDark;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
    );

    return AnimatedScale(
      scale: onPressed == null ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [_primary, _primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SoftButton({required this.label, required this.onTap});

  static const _ink = _EditCustomerPageState._ink;
  static const _stroke = _EditCustomerPageState._stroke;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FB),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _stroke),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          child: Center(
            child: Text(
              'Cancel',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
