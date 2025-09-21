import 'package:flutter/material.dart';

import '../../Models/customer.dart';
import '../../services/customer_service.dart';
import 'crm_edit_profile.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;
  const CustomerDetailPage({super.key, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late Customer _customer;

  bool _vehLoading = true;
  String? _vehError;
  List<Vehicle> _vehicles = const [];

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
    _customer = widget.customer;
    _loadVehicles();
  }

  String _fmtIc(String? raw) {
    if (raw == null) return '-';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12) return raw;
    final p1 = digits.substring(0, 6);
    final p2 = digits.substring(6, 8);
    final p3 = digits.substring(8, 12);
    return '$p1-$p2-$p3';
  }

  String _fmtPhone(String? raw) {
    if (raw == null) return '-';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return raw;

    if (digits.length == 10 || digits.length == 11) {
      final p1 = digits.substring(0, 3);
      final p2 = digits.substring(3, 7);
      final p3 = digits.substring(7);
      return '$p1-$p2 $p3';
    }

    if (digits.length == 9 || digits.length == 10) {
      final p1 = digits.substring(0, 2);
      final p2 = digits.substring(2, 6);
      final p3 = digits.substring(6);
      return '$p1-$p2 $p3';
    }

    if (digits.length > 7) {
      final p1 = digits.substring(0, 3);
      final p2 = digits.substring(3, 7);
      final p3 = digits.substring(7);
      return '$p1-$p2 $p3';
    }

    return raw;
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _vehLoading = true;
      _vehError = null;
    });
    try {
      final list = await VehicleService().listByCustomer(_customer.id);
      if (!mounted) return;
      setState(() {
        _vehicles = list;
        _vehLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _vehError = e.toString();
        _vehLoading = false;
      });
    }
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
    );
  }

  Future<void> _onEdit() async {
    final edited = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (_) => EditCustomerPage(customer: _customer),
      ),
    );

    if (!mounted || edited == null) return;

    try {
      final saved = await CustomerService.instance.update(edited.id, edited);
      if (!mounted) return;
      setState(() => _customer = saved);
      _loadVehicles();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const panelRadius = 24.0;

    return Theme(
      data: _localTheme(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer Detail'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF90CAF9), _primary],
                  ),
                ),
              ),
              Container(
                transform: Matrix4.translationValues(0, -36, 0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(panelRadius),
                  border: const Border.fromBorderSide(BorderSide(color: _stroke)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _PositionedAvatar(),
                      const SizedBox(height: 12),
                      Text(
                        _customer.fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      if ((_customer.phone ?? '').isNotEmpty || (_customer.email ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          [
                            if ((_customer.phone ?? '').isNotEmpty) _fmtPhone(_customer.phone),
                            if ((_customer.email ?? '').isNotEmpty) _customer.email!,
                          ].join(' • '),
                          style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 22),
                      _InfoRow(
                        leftLabel: 'IC Number',
                        leftValue: _fmtIc(_customer.icNo),
                        rightLabel: 'Gender',
                        rightValue: _customer.gender ?? '-',
                        muted: _muted,
                      ),
                      const SizedBox(height: 16),
                      _InfoRow.full(
                        label: 'Address',
                        value: _customer.address ?? '-',
                        muted: _muted,
                      ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Registered Vehicle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 10),
                      if (_vehLoading)
                        const _ShimmerRow()
                      else if (_vehError != null)
                        _EmptyStateCard(
                          icon: Icons.error_outline,
                          title: 'Could not load vehicles',
                          subtitle: _vehError!,
                          borderColor: _stroke,
                          muted: _muted,
                        )
                      else if (_vehicles.isEmpty)
                          _EmptyStateCard(
                            icon: Icons.directions_car_filled_outlined,
                            title: 'No vehicles registered',
                            subtitle: 'This Customer has not register any vehicle yet',
                            borderColor: _stroke,
                            muted: _muted,
                          )
                        else
                          Column(
                            children: _vehicles.map((v) => _VehicleTile(v: v)).toList(),
                          ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: _PrimaryButton(
                          label: 'Edit Profile',
                          onPressed: _onEdit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PositionedAvatar extends StatelessWidget {
  const _PositionedAvatar();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -64),
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFFF1F4F8),
          border: const Border.fromBorderSide(BorderSide(color: _CustomerDetailPageState._stroke)),
          boxShadow: const [
            BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.person, size: 56, color: _CustomerDetailPageState._ink),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final Color muted;

  const _InfoRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.muted,
  });

  const _InfoRow.full({
    super.key,
    required String label,
    required String value,
    required this.muted,
  })  : leftLabel = label,
        leftValue = value,
        rightLabel = '',
        rightValue = '';

  @override
  Widget build(BuildContext context) {
    Text _label(String s) => Text(
      s,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: muted, letterSpacing: .2),
    );
    Text _value(String s) => Text(
      s.isEmpty ? '-' : s,
      style: const TextStyle(fontSize: 16, color: _CustomerDetailPageState._ink, height: 1.35),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label(leftLabel),
            const SizedBox(height: 6),
            _value(leftValue),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: (rightLabel.isEmpty && rightValue.isEmpty)
              ? const SizedBox.shrink()
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(rightLabel),
              const SizedBox(height: 6),
              _value(rightValue),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color borderColor;
  final Color muted;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: _CustomerDetailPageState._ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12.5, color: muted)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const _PrimaryButton({required this.onPressed, required this.label});

  static const _primary = _CustomerDetailPageState._primary;
  static const _primaryDark = _CustomerDetailPageState._primaryDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: onPressed == null ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
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

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _CustomerDetailPageState._stroke),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: const Text('Loading vehicles...', style: TextStyle(color: _CustomerDetailPageState._muted)),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  final Vehicle v;
  const _VehicleTile({required this.v});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _CustomerDetailPageState._stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _CustomerDetailPageState._stroke),
            ),
            child: const Icon(Icons.directions_car_filled, color: _CustomerDetailPageState._ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                v.plateNumber.isEmpty ? 'Unknown plate' : v.plateNumber,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if ((v.make ?? '').isNotEmpty) v.make!,
                  if ((v.model ?? '').isNotEmpty) v.model!,
                  if (v.year != null) '${v.year}',
                ].join(' • '),
                style: const TextStyle(fontSize: 13.5, color: _CustomerDetailPageState._muted),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
