// lib/CRM/crm_dashboard.dart
import 'package:flutter/material.dart';
import '../../Models/customer.dart';
import '../../services/customer_service.dart';

import 'crm_customer_detail.dart';
import 'crm_add_customer.dart';
import 'crm_history.dart';

class CrmDashboard extends StatefulWidget {
  const CrmDashboard({super.key});

  @override
  State<CrmDashboard> createState() => _CrmDashboardState();
}

enum _ListFilter { all, recentAdded, recentUpdated }

class _CrmDashboardState extends State<CrmDashboard> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _ListFilter _filter = _ListFilter.all;
  bool _loading = true;
  String? _error;
  List<Customer> _customers = const [];

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
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text;
    if (q != _query) {
      setState(() => _query = q);
      _load();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        contentTextStyle: tuned.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: _muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: _stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: _stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }

  String _filterString(_ListFilter f) {
    switch (f) {
      case _ListFilter.recentAdded:
        return 'added';
      case _ListFilter.recentUpdated:
        return 'updated';
      case _ListFilter.all:
      default:
        return 'all';
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await CustomerService.instance.fetchCustomers(
        query: _query,
        filter: _filterString(_filter),
        recentDays: 7,
      );
      if (!mounted) return;
      setState(() {
        _customers = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _localTheme(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('Customer Dashboard')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + kBottomNavigationBarHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TotalCustomersCard(
                  countText: _loading ? '—' : _customers.length.toString(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search by name, phone, or IC',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                _FilterRow(
                  value: _filter,
                  onChanged: (f) {
                    if (f != _filter) {
                      setState(() => _filter = f);
                      _load();
                    }
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Customer List',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    _PrimaryButton.icon(
                      icon: Icons.add_rounded,
                      label: 'Customer',
                      onPressed: () async {
                        final draft = await Navigator.push<Customer?>(
                          context,
                          MaterialPageRoute(builder: (_) => const AddCustomerPage()),
                        );
                        if (draft != null) {
                          try {
                            await CustomerService.instance.insert(draft);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added ${draft.fullName}')),
                            );
                            await _load();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Insert failed: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_error != null) ...[
                  Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                ] else if (_loading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (_customers.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No customers found')),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _customers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final c = _customers[i];
                      return _CustomerTile(
                        customer: c,
                        onHistory: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerHistoryPage(customer: c),
                            ),
                          );
                        },
                        onDetails: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailPage(customer: c),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  const _PrimaryButton({super.key, required this.onPressed, required this.label}) : icon = null;
  const _PrimaryButton.icon({super.key, required this.onPressed, required this.label, required this.icon});

  static const _primary = _CrmDashboardState._primary;
  static const _primaryDark = _CrmDashboardState._primaryDark;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          const SizedBox(width: 2),
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ],
    );

    return AnimatedScale(
      scale: onPressed == null ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [_primary, _primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalCustomersCard extends StatelessWidget {
  final String countText;
  const _TotalCustomersCard({required this.countText});

  static const _card = _CrmDashboardState._card;
  static const _stroke = _CrmDashboardState._stroke;
  static const _muted = _CrmDashboardState._muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(BorderSide(color: _stroke)),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 22, offset: Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF90CAF9), Color(0xFF1E88E5)],
                ),
              ),
              child: const Icon(Icons.people_alt, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total customers', style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(countText, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phone formatter used in the list tiles
String _fmtPhone(String? raw) {
  if (raw == null) return '-';
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 9) return raw;

  // Mobile 10/11 digits: 3-4 <space> rest, e.g. 012-3456 789(0)
  if (digits.length == 10 || digits.length == 11) {
    final p1 = digits.substring(0, 3);
    final p2 = digits.substring(3, 7);
    final p3 = digits.substring(7);
    return '$p1-$p2 $p3';
  }

  // Landline 9/10 digits: 2-4 <space> rest, e.g. 03-1234 5678
  if (digits.length == 9 || digits.length == 10) {
    final p1 = digits.substring(0, 2);
    final p2 = digits.substring(2, 6);
    final p3 = digits.substring(6);
    return '$p1-$p2 $p3';
  }

  // Fallback pattern for other lengths
  if (digits.length > 7) {
    final p1 = digits.substring(0, 3);
    final p2 = digits.substring(3, 7);
    final p3 = digits.substring(7);
    return '$p1-$p2 $p3';
  }

  return raw;
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onHistory;
  final VoidCallback onDetails;

  const _CustomerTile({
    required this.customer,
    required this.onHistory,
    required this.onDetails,
  });

  static const _stroke = _CrmDashboardState._stroke;
  static const _muted = _CrmDashboardState._muted;
  static const _ink = _CrmDashboardState._ink;
  static const _primary = _CrmDashboardState._primary;
  static const _primaryDark = _CrmDashboardState._primaryDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border.fromBorderSide(BorderSide(color: _stroke)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person, color: _ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(_fmtPhone(customer.phone), style: TextStyle(fontSize: 13, color: _muted)),
                ],
              ),
            ),
          ),
          _pillButton('History', onHistory),
          const SizedBox(width: 8),
          _pillButton('Details', onDetails, gradient: const [_primary, _primaryDark]),
        ],
      ),
    );
  }

  Widget _pillButton(String label, VoidCallback onTap, {List<Color>? gradient}) {
    final bool isPrimary = gradient != null;
    final child = Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isPrimary ? Colors.white : _ink,
      ),
    );

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: isPrimary ? LinearGradient(colors: gradient) : null,
      color: isPrimary ? null : const Color(0xFFF7F9FB),
      border: isPrimary ? null : const Border.fromBorderSide(BorderSide(color: _stroke)),
      boxShadow: isPrimary ? const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))] : null,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _ListFilter value;
  final ValueChanged<_ListFilter> onChanged;
  const _FilterRow({required this.value, required this.onChanged});

  static const _stroke = _CrmDashboardState._stroke;
  static const _ink = _CrmDashboardState._ink;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _seg('All', value == _ListFilter.all, () => onChanged(_ListFilter.all)),
        const SizedBox(width: 10),
        _seg('Recently added', value == _ListFilter.recentAdded, () => onChanged(_ListFilter.recentAdded)),
        const SizedBox(width: 10),
        _seg('Recently updated', value == _ListFilter.recentUpdated, () => onChanged(_ListFilter.recentUpdated)),
      ],
    );
  }

  Widget _seg(String text, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? const Color(0xFF26323A) : Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: selected ? const Color(0xFF26323A) : _stroke),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _ink,
            ),
          ),
        ),
      ),
    );
  }
}
