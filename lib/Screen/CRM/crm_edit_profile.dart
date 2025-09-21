import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Models/customer.dart';

/// Edit DB Customer
class EditCustomerPage extends StatefulWidget {
  final Customer customer;
  const EditCustomerPage({super.key, required this.customer});

  @override
  State<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullName;
  late final TextEditingController _icNo;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;

  late String _gender;

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
    _icNo     = TextEditingController(text: _fmtIc(widget.customer.icNo ?? ''));
    _phone    = TextEditingController(text: _fmtPhone(widget.customer.phone ?? ''));
    _email    = TextEditingController(text: widget.customer.email ?? '');
    _address  = TextEditingController(text: widget.customer.address ?? '');
    _gender   = widget.customer.gender ?? '';
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
        // 🔴 Make validation messages more visible
        errorStyle: const TextStyle(
          color: Color(0xFFD32F2F),
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        errorMaxLines: 2,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
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

  // ---------- Display formatters ----------
  String _fmtIc(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    final p1 = d.substring(0, d.length.clamp(0, 6));
    final p2 = d.length > 6 ? d.substring(6, d.length.clamp(0, 8)) : '';
    final p3 = d.length > 8 ? d.substring(8, d.length.clamp(0, 12)) : '';
    return [
      if (p1.isNotEmpty) p1,
      if (p2.isNotEmpty) '-$p2',
      if (p3.isNotEmpty) '-$p3',
    ].join();
  }

  String _fmtPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    if (d.length <= 3) return d;
    if (d.length <= 7) return '${d.substring(0, 3)}-${d.substring(3)}';
    final p1 = d.substring(0, 3);
    final p2 = d.substring(3, 7);
    final p3 = d.substring(7);
    return '$p1-$p2 $p3';
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  // ---------- Validators ----------
  String? _vName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Full Name is required';
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(s)) return 'Full Name must contain alphabets only';
    return null;
  }

  String? _vIc(String? v) {
    final digits = _digitsOnly(v ?? '');
    if (digits.isEmpty) return 'IC Number is required';
    if (digits.length != 12) return 'IC must be 12 digits (format xxxxxx-xx-xxxx)';
    return null;
  }

  String? _vPhone(String? v) {
    final digits = _digitsOnly(v ?? '');
    if (digits.isEmpty) return 'Phone is required';
    if (digits.length < 10) return 'Phone must have at least 10 digits';
    if (digits.startsWith('011')) {
      if (digits.length != 11) return 'Numbers starting with 011 must have 11 digits';
    } else {
      if (digits.length != 10) return 'Phone must have 10 digits (except 011 = 11 digits)';
    }
    return null;
  }

  bool _isValidEmail(String s) => RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s.trim());
  String? _vEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email is required';
    if (!_isValidEmail(s)) return 'Invalid email';
    return null;
  }

  // ---------- Save ----------
  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // Optional: nudge user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields')),
      );
      return;
    }

    final icDigits = _digitsOnly(_icNo.text);

    final updated = Customer(
      id: widget.customer.id,
      fullName: _fullName.text.trim(),
      icNo: icDigits,                        // store 12 digits
      phone: _phone.text.trim(),             // keep formatted for display
      email: _email.text.trim(),
      gender: _gender.isEmpty ? null : _gender,
      address: _address.text.trim().isEmpty ? null : _address.text.trim(), // optional
      createdAt: widget.customer.createdAt,
      updatedAt: widget.customer.updatedAt,
    );

    Navigator.pop(context, updated);
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
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    border: const Border.fromBorderSide(BorderSide(color: _stroke)),
                    boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 22, offset: Offset(0, 10))],
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction, // show red message as user types
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Edit Profile Details',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 18),

                        const _FieldLabel('Full Name'),
                        TextFormField(
                          controller: _fullName,
                          textAlignVertical: TextAlignVertical.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                          ],
                          decoration: const InputDecoration(hintText: 'Full name'),
                          validator: _vName,
                        ),
                        const SizedBox(height: 16),

                        const _FieldLabel('IC No'),
                        TextFormField(
                          controller: _icNo,
                          keyboardType: TextInputType.number,
                          textAlignVertical: TextAlignVertical.center,
                          inputFormatters: [
                            _NricTextInputFormatter(),           // live 6-2-4
                            LengthLimitingTextInputFormatter(14) // 12 digits + 2 dashes
                          ],
                          decoration: const InputDecoration(hintText: 'e.g. 010203-10-1234'),
                          validator: _vIc,
                        ),
                        const SizedBox(height: 16),

                        const _FieldLabel('Phone'),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textAlignVertical: TextAlignVertical.center,
                          inputFormatters: [
                            _MyPhoneDisplayFormatter(),           // 3-4 <space> rest
                            LengthLimitingTextInputFormatter(14),
                          ],
                          decoration: const InputDecoration(hintText: '012-3456 789'),
                          validator: _vPhone,
                        ),
                        const SizedBox(height: 16),

                        const _FieldLabel('Email'),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(hintText: 'name@example.com'),
                          validator: _vEmail,
                        ),
                        const SizedBox(height: 16),

                        const _FieldLabel('Gender'),
                        DropdownButtonFormField<String>(
                          value: _gender.isEmpty ? null : _gender,
                          isExpanded: true,
                          icon: const SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (v) => setState(() => _gender = v ?? ''),
                          decoration: const InputDecoration(hintText: 'Select gender'),
                          // If you want gender required, add validator here. Currently optional per your note.
                        ),
                        const SizedBox(height: 16),

                        const _FieldLabel('Address (optional)'),
                        TextFormField(
                          controller: _address,
                          minLines: 2,
                          maxLines: 4,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(hintText: 'Street, city, state, postcode'),
                          // optional -> no validator
                        ),

                        const SizedBox(height: 24),

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
      ),
    );
  }
}

/* ---------- Small UI bits ---------- */

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

/* ---------- Live input formatters ---------- */

/// Malaysian NRIC live input formatter: xxxxxx-xx-xxxx (6-2-4)
class _NricTextInputFormatter extends TextInputFormatter {
  static final _nonDigits = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var digits = newValue.text.replaceAll(_nonDigits, '');
    if (digits.length > 12) digits = digits.substring(0, 12);

    final sb = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      sb.write(digits[i]);
      if (i == 5 && digits.length > 6) sb.write('-');
      if (i == 7 && digits.length > 8) sb.write('-');
    }
    final formatted = sb.toString();

    final selectionIndex = newValue.selection.end;
    final digitsBeforeCursor = _countDigitsBeforeIndex(newValue.text, selectionIndex);
    final newCursor = _positionForDigitIndex(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
      composing: TextRange.empty,
    );
  }

  int _countDigitsBeforeIndex(String text, int index) {
    var count = 0;
    for (var i = 0; i < index && i < text.length; i++) {
      final cu = text.codeUnitAt(i);
      if (cu >= 48 && cu <= 57) count++;
    }
    return count;
  }

  int _positionForDigitIndex(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      final cu = formatted.codeUnitAt(i);
      final isDigit = cu >= 48 && cu <= 57;
      if (isDigit) {
        seen++;
        if (seen == digitCount) return i + 1;
      }
    }
    return formatted.length;
  }
}

/// Phone display formatter: 3-4 <space> rest (e.g., 012-3456 789[0])
class _MyPhoneDisplayFormatter extends TextInputFormatter {
  static final _nonDigits = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    var d = newValue.text.replaceAll(_nonDigits, '');

    String formatted;
    if (d.length <= 3) {
      formatted = d;
    } else if (d.length <= 7) {
      formatted = '${d.substring(0, 3)}-${d.substring(3)}';
    } else {
      final p1 = d.substring(0, 3);
      final p2 = d.substring(3, 7);
      final p3 = d.substring(7);
      formatted = '$p1-$p2 $p3';
    }

    final selectionIndex = newValue.selection.end;
    final digitsBeforeCursor = _countDigitsBeforeIndex(newValue.text, selectionIndex);
    final newCursor = _positionForDigitIndex(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
      composing: TextRange.empty,
    );
  }

  int _countDigitsBeforeIndex(String text, int index) {
    var count = 0;
    for (var i = 0; i < index && i < text.length; i++) {
      final cu = text.codeUnitAt(i);
      if (cu >= 48 && cu <= 57) count++;
    }
    return count;
  }

  int _positionForDigitIndex(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      final cu = formatted.codeUnitAt(i);
      final isDigit = cu >= 48 && cu <= 57;
      if (isDigit) {
        seen++;
        if (seen == digitCount) return i + 1;
      }
    }
    return formatted.length;
  }
}
