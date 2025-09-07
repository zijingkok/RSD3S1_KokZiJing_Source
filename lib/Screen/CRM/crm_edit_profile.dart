import 'package:flutter/material.dart';
import 'crm_dashboard.dart' show Customer;

/// Edit Profile (no icons, black background, no images)
class EditCustomerPage extends StatefulWidget {
  final Customer customer;
  const EditCustomerPage({super.key, required this.customer});

  @override
  State<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  // Basic
  final _name = TextEditingController();
  final _phone = TextEditingController();

  // Date
  bool _useCalendar = true;
  late DateTime _selectedDate;
  int _day = 1, _month = 7, _year = 2003;

  // Gender
  String _gender = 'Male';

  static const _months = <String>[
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  @override
  void initState() {
    super.initState();
    _name.text = widget.customer.name;
    _phone.text = widget.customer.phone;
    _gender = widget.customer.gender.isEmpty ? 'Male' : widget.customer.gender;

    final parsed = _parseDob(widget.customer.dob) ?? DateTime(2000, 1, 1);
    _selectedDate = parsed;
    _day = parsed.day; _month = parsed.month; _year = parsed.year;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  DateTime? _parseDob(String s) {
    final p = s.split('/');
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]), m = int.tryParse(p[1]), y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime.tryParse('$y-${m.toString().padLeft(2,"0")}-${d.toString().padLeft(2,"0")}');
  }

  String _formatDob(DateTime dt) =>
      '${dt.day.toString().padLeft(2, "0")}/${dt.month.toString().padLeft(2, "0")}/${dt.year}';

  int _daysInMonth(int year, int month) {
    final next = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }

  Future<void> _pickCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 50)),
      helpText: 'Select Date of Birth',
      builder: (ctx, child) {
        final theme = Theme.of(ctx);
        return Theme(
          data: theme.copyWith(
            datePickerTheme: const DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            colorScheme: theme.colorScheme.copyWith(
              primary: Colors.black, onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _day = picked.day; _month = picked.month; _year = picked.year;
      });
    }
  }

  void _confirm() {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name and phone')),
      );
      return;
    }
    final dob = _useCalendar
        ? _selectedDate
        : DateTime(_year, _month, _day.clamp(1, _daysInMonth(_year, _month)));
    final updated = Customer(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: widget.customer.email,
      gender: _gender,
      dob: _formatDob(dob),
      avatarAsset: widget.customer.avatarAsset,
      vehicles: widget.customer.vehicles,
    );
    Navigator.pop(context, updated);
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // full black background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (no icon)
                    const Text('Edit Profile Details',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 22),

                    // Name
                    const _FieldLabel('Name'),
                    TextField(
                      controller: _name,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: _dec(hint: 'Full name'),
                    ),
                    const SizedBox(height: 18),

                    // Phone
                    const _FieldLabel('Phone Number'),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: _dec(hint: '012-345 6789'),
                    ),
                    const SizedBox(height: 18),

                    // DOB
                    const _FieldLabel('Date of Birth'),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Calendar'),
                          selected: _useCalendar,
                          showCheckmark: false, // no icon
                          onSelected: (_) => setState(() => _useCalendar = true),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Dropdowns'),
                          selected: !_useCalendar,
                          showCheckmark: false, // no icon
                          onSelected: (_) => setState(() => _useCalendar = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_useCalendar)
                      _calendarSummaryCard()
                    else
                      _dropdownDateResponsive(),

                    const SizedBox(height: 18),

                    // Gender
                    const _FieldLabel('Gender'),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      isExpanded: true,
                      icon: const SizedBox.shrink(), // hide default arrow
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                      decoration: _dec(),
                    ),

                    const SizedBox(height: 28),

                    // Confirm
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Confirm', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Cancel
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Calendar summary (no icons)
  Widget _calendarSummaryCard() {
    final pretty =
        '${_selectedDate.day} ${_months[_selectedDate.month - 1]} ${_selectedDate.year}';
    final raw = _formatDob(_selectedDate);
    return Container(
      decoration: _panelDecoration(),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pretty, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(raw, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
          TextButton(
            onPressed: _pickCalendar,
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  // Responsive Dropdown DOB (no arrows)
  Widget _dropdownDateResponsive() {
    final maxDay = _daysInMonth(_year, _month);
    if (_day > maxDay) _day = maxDay;

    final dayField = DropdownButtonFormField<int>(
      value: _day,
      isExpanded: true,
      icon: const SizedBox.shrink(),
      items: List.generate(maxDay, (i) => i + 1)
          .map((d) => DropdownMenuItem(value: d, child: Text(d.toString())))
          .toList(),
      onChanged: (v) => setState(() => _day = v ?? _day),
      decoration: _dec(hint: 'Day'),
    );

    final monthField = DropdownButtonFormField<int>(
      value: _month,
      isExpanded: true,
      icon: const SizedBox.shrink(),
      items: List.generate(12, (i) => i + 1)
          .map((m) => DropdownMenuItem(value: m, child: Text(_months[m - 1])))
          .toList(),
      onChanged: (v) => setState(() => _month = v ?? _month),
      decoration: _dec(hint: 'Month'),
    );

    final yearField = DropdownButtonFormField<int>(
      value: _year,
      isExpanded: true,
      icon: const SizedBox.shrink(),
      items: List.generate(120, (i) => DateTime.now().year - i)
          .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
          .toList(),
      onChanged: (v) => setState(() => _year = v ?? _year),
      decoration: _dec(hint: 'Year'),
    );

    return LayoutBuilder(builder: (context, c) {
      final narrow = c.maxWidth < 380;
      if (narrow) {
        return Column(
          children: [
            dayField,
            const SizedBox(height: 12),
            monthField,
            const SizedBox(height: 12),
            yearField,
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: dayField),
          const SizedBox(width: 12),
          Expanded(child: monthField),
          const SizedBox(width: 12),
          Expanded(child: yearField),
        ],
      );
    });
  }

  // Styles
  InputDecoration _dec({String? hint}) => InputDecoration(
    hintText: hint,
    isDense: false,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFB5B5B5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFB5B5B5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black), // black focus
    ),
  );

  BoxDecoration _panelDecoration() => BoxDecoration(
    color: const Color(0xFFF3F4F6),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFB5B5B5)),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  );
}
