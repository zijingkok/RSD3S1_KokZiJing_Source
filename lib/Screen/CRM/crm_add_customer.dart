// lib/CRM/crm_add_customer.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Models/customer.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _icCtrl = TextEditingController(); // REQUIRED (auto-format xxxxxx-xx-xxxx)
  final _addressCtrl = TextEditingController(); // optional

  String _gender = 'Male'; // default

  // ---- Shared palette (matches other pages) ----
  static const _bg = Color(0xFFF5F7FA);
  static const _ink = Color(0xFF1D2A32);
  static const _muted = Color(0xFF6A7A88);
  static const _card = Colors.white;
  static const _stroke = Color(0xFFE6ECF1);
  static const _primary = Color(0xFF1E88E5);
  static const _primaryDark = Color(0xFF1565C0);

  String? _validateName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Name is required';
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(s)) {
      return 'Name must contain alphabets only';
    }
    return null;
  }

  String? _validateMyPhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Phone must be at least 10 digits';

    if (digits.startsWith('011')) {
      if (digits.length != 11) return 'Numbers starting with 011 must have 11 digits';
    } else {
      if (digits.length != 10) return 'Phone must have 10 digits (except 011 = 11 digits)';
    }
    return null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _icCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  ThemeData _localTheme(BuildContext context) {
    final base = Theme.of(context);
    final tuned = base.textTheme
        .copyWith(
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.3),
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
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Consistent input decoration
  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
  );

  @override
  Widget build(BuildContext context) {
    const cardRadius = 22.0;

    return Theme(
      data: _localTheme(context),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
          title: const Text('New Customer'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Container(
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(cardRadius),
                    border: Border.all(color: _stroke),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          const Center(
                            child: Text(
                              'New Customer Details',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Full name
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: _dec('Full Name'),
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                            ],
                            validator: _validateName,
                          ),

                          const SizedBox(height: 14),

                          // Phone
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: _dec('Phone Number').copyWith(counterText: ''),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11), // max for 011 numbers
                          ],
                          validator: _validateMyPhone,
                        ),

                          const SizedBox(height: 18),

                          // Gender segmented
                          const Text('Gender', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _muted)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _genderBtn('Male')),
                              const SizedBox(width: 10),
                              Expanded(child: _genderBtn('Female')),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Email (REQUIRED)
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _dec('Email'),
                            validator: (v) {
                              final s = v?.trim() ?? '';
                              if (s.isEmpty) return 'Email is required';
                              final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
                              return ok ? null : 'Invalid email';
                            },
                          ),
                          const SizedBox(height: 14),

                          // IC Number (REQUIRED, auto 6-2-4 formatting)
                          TextFormField(
                            controller: _icCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              NricTextInputFormatter(), // custom formatter inserts dashes
                            ],
                            maxLength: 14, // xxxxxx-xx-xxxx (14 incl. 2 dashes)
                            decoration: _dec('IC Number').copyWith(counterText: ''),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              final digits = s.replaceAll('-', '');
                              if (digits.isEmpty) return 'IC number is required';
                              if (digits.length != 12) return 'IC must be 12 digits';
                              final ok = RegExp(r'^\d{6}-\d{2}-\d{4}$').hasMatch(s);
                              return ok ? null : 'Format must be xxxxxx-xx-xxxx';
                            },
                          ),
                          const SizedBox(height: 14),

                          // Address (optional)
                          TextFormField(
                            controller: _addressCtrl,
                            minLines: 2,
                            maxLines: 4,
                            decoration: _dec('Address (optional)'),
                          ),

                          const SizedBox(height: 22),

                          // Submit button (shared gradient look)
                          _PrimaryButton(
                            label: 'Submit',
                            onPressed: _onSubmit,
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
      ),
    );
  }

  Widget _genderBtn(String value) {
    final selected = _gender == value;
    return Material(
      color: selected ? const Color(0xFF26323A) : Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: selected ? const Color(0xFF26323A) : _stroke),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _gender = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------- Pretty confirm dialog (polished UI) -------
  Future<bool> _showPrettyConfirm(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F1824),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirm Submit?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  // YES (green)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2EB872),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // NO (red)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('No', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ??
        false;
  }

  // Normalize IC to digits-only for storage
  String _normalizedIc() => _icCtrl.text.replaceAll('-', '').trim();

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await _showPrettyConfirm(context);
    if (!confirm) return;

    // Build a Customer "draft" to return to the dashboard.
    final draft = Customer(
      id: '',
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(), // required -> guaranteed non-empty & valid
      gender: _gender,
      icNo: _normalizedIc(), // store 12 digits without dashes
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      createdAt: null,
      updatedAt: null,
    );

    if (!mounted) return;
    Navigator.pop(context, draft);
  }
}

/* ---------- Shared primary button (same look as other pages) ---------- */
class _PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  const _PrimaryButton({required this.onPressed, required this.label});

  static const _primary = _AddCustomerPageState._primary;
  static const _primaryDark = _AddCustomerPageState._primaryDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: 1.0,
      child: DecoratedBox(
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- Malaysian IC live input formatter xxxxxx-xx-xxxx ---------- */
class NricTextInputFormatter extends TextInputFormatter {
  static final _nonDigits = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // 1) Strip to digits and cap at 12
    var digits = newValue.text.replaceAll(_nonDigits, '');
    if (digits.length > 12) digits = digits.substring(0, 12);

    // 2) Build formatted text with dashes after 6th and 8th digit
    final sb = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      sb.write(digits[i]);
      if (i == 5 && digits.length > 6) sb.write('-'); // after 6th digit
      if (i == 7 && digits.length > 8) sb.write('-'); // after 8th digit
    }
    final formatted = sb.toString();

    // 3) Recalculate caret position
    final selectionIndex = newValue.selection.end;
    final digitsBeforeCursor = _countDigitsBeforeIndex(newValue.text, selectionIndex);
    final newCursor = _positionForDigitIndex(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
      composing: TextRange.empty,
    );
  }

  // Counts digits in `text` strictly before `index`
  int _countDigitsBeforeIndex(String text, int index) {
    var count = 0;
    for (var i = 0; i < index && i < text.length; i++) {
      final cu = text.codeUnitAt(i);
      if (cu >= 48 && cu <= 57) count++; // '0'..'9'
    }
    return count;
  }

  // Returns caret position in `formatted` after `digitCount` digits
  int _positionForDigitIndex(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      final cu = formatted.codeUnitAt(i);
      final isDigit = cu >= 48 && cu <= 57;
      if (isDigit) {
        seen++;
        if (seen == digitCount) return i + 1; // caret after this digit
      }
    }
    return formatted.length;
  }
}
