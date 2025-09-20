import 'package:flutter/material.dart';
import '../../Models/Inventory_models/parts.dart';
import '../../services/Inventory_services/procurement_service.dart';

class InventoryRequestScreen extends StatefulWidget {
  const InventoryRequestScreen({super.key});

  @override
  State<InventoryRequestScreen> createState() => _InventoryRequestScreenState();
}

// Brand blues (same as your other primary buttons)
const _brandBlue = Color(0xFF1E88E5);
const _brandBlueDark = Color(0xFF1565C0);

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double radius;
  const _GradientButton({
    required this.label,
    this.icon,
    required this.onPressed,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_brandBlue, _brandBlueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ReqPriority { low, medium, high }

class _InventoryRequestScreenState extends State<InventoryRequestScreen> {
  // UI controllers
  final _notesCtrl = TextEditingController();

  // Services
  final _service = ProcurementService();

  // Data fetched from service (must include: part_id, part_name, part_number, location, stock_quantity)
  List<Map<String, dynamic>> _parts = [];
  List<String> _locations = [];

  // Form state
  String? _selectedLocationID; // dropdown #1
  String? _selectedPartId;     // dropdown #2
  int _qty = 1;
  ReqPriority _priority = ReqPriority.medium;

  // Loading / submit
  bool _loading = true;
  bool _submitting = false;

  // Prefill (from Parts list → Request More)
  bool _didReadArgs = false;
  bool _shouldPrefill = false;
  Part? _prefillPart;
  String? _prefillLocation;

  // ---- THEME ----
  static const _bg = Color(0xFFF5F7FA);
  static const _ink = Color(0xFF1D2A32);
  static const _muted = Color(0xFF6A7A88);
  static const _stroke = Color(0xFFB5B5B5);

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  ThemeData _pageTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: _bg,
      colorScheme: base.colorScheme.copyWith(
        primary: _ink,   // kill purple
        secondary: _ink, // kill purple
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
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
          borderSide: const BorderSide(color: _ink, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _loadParts() async {
    try {
      final parts = await _service.fetchParts();
      final locs = parts
          .map((p) => (p['location'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;
      setState(() {
        _parts = parts;
        _locations = locs;
        _loading = false;
      });

      if (_shouldPrefill) _applyPrefillIfAny();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // Read route args once and only prefill if source == 'parts'
  void _readArgsOnceIfNeeded() {
    if (_didReadArgs) return;
    _didReadArgs = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final src = args['source'];
        if (src == 'parts') {
          _shouldPrefill = true;
          final maybePart = args['part'];
          final maybeLoc = args['location'];
          if (maybePart is Part) _prefillPart = maybePart;
          if (maybeLoc is String && maybeLoc.isNotEmpty) {
            _prefillLocation = maybeLoc;
          }
        }
      }
      if (!_loading && _shouldPrefill) _applyPrefillIfAny();
    });
  }

  void _applyPrefillIfAny() {
    if (!_shouldPrefill) return;

    final loc = _prefillLocation ?? _prefillPart?.location;
    String? partId;

    if (_prefillPart != null) {
      final match = _parts.firstWhere(
            (p) =>
        p['part_id'] == _prefillPart!.id ||
            (p['part_number'] == _prefillPart!.number &&
                _prefillPart!.number.isNotEmpty) ||
            (p['part_name'] == _prefillPart!.name &&
                (loc == null || p['location'] == loc)),
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        partId = match['part_id'] as String?;
      }
    }

    setState(() {
      if (loc != null && loc.isNotEmpty && _locations.contains(loc)) {
        _selectedLocationID = loc;
      } else if (_locations.isNotEmpty && _selectedLocationID == null) {
        _selectedLocationID = _locations.first;
      }

      if (partId != null) {
        final belongs = _parts.any(
              (p) =>
          p['part_id'] == partId &&
              (_selectedLocationID == null ||
                  p['location'] == _selectedLocationID),
        );
        _selectedPartId = belongs ? partId : null;
      }
    });

    _prefillPart = null;
    _prefillLocation = null;
    _shouldPrefill = false;
  }

  String get _selectedPartName {
    for (final p in _parts) {
      if (p['part_id'] == _selectedPartId) {
        final name = p['part_name'] as String? ?? 'Unknown';
        final loc = p['location'] as String? ?? '';
        final stock = (p['stock_quantity'] ?? 0).toString();
        return loc.isEmpty
            ? '$name (Stock: $stock)'
            : '$name — [$loc] (Stock: $stock)';
      }
    }
    return 'Not selected';
  }

  String _priorityLabel(ReqPriority p) {
    switch (p) {
      case ReqPriority.low:
        return 'Low';
      case ReqPriority.medium:
        return 'Normal';
      case ReqPriority.high:
        return 'Urgent';
    }
  }

  @override
  Widget build(BuildContext context) {
    _readArgsOnceIfNeeded();

    if (_loading) {
      return Theme(
        data: _pageTheme(context),
        child: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final filteredParts = (_selectedLocationID == null || _selectedLocationID!.isEmpty)
        ? <Map<String, dynamic>>[]
        : _parts.where((p) => (p['location'] ?? '') == _selectedLocationID).toList();

    return Theme(
      data: _pageTheme(context),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16, 12, 16, 16 + kBottomNavigationBarHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Back row (kept) ----
                if (Navigator.of(context).canPop()) ...[
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: _ink),
                        onPressed: () => Navigator.maybePop(context),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'New Stock Request',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // ---- Card container with form fields ----
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _stroke),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Location',
                            style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedLocationID,
                          isExpanded: true,
                          items: _locations
                              .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedLocationID = v;
                              _selectedPartId = null;
                            });
                          },
                          validator: (v) =>
                          (v == null || v.isEmpty) ? 'Please select a location' : null,
                          decoration: const InputDecoration(labelText: 'Location'),
                        ),
                        const SizedBox(height: 14),

                        const Text('Select Part',
                            style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedPartId,
                          isExpanded: true,
                          items: filteredParts.map((p) {
                            final name = p['part_name'] as String? ?? 'Unknown';
                            final loc = p['location'] as String? ?? '';
                            final stock = (p['stock_quantity'] ?? 0).toString();
                            final label = loc.isEmpty
                                ? '$name (Stock: $stock)'
                                : '$name — [$loc] (Stock: $stock)';
                            return DropdownMenuItem(
                              value: p['part_id'] as String,
                              child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedPartId = v),
                          validator: (v) =>
                          (v == null || v.isEmpty) ? 'Please select a part' : null,
                          decoration: const InputDecoration(labelText: 'Part'),
                        ),
                        const SizedBox(height: 16),

                        const Text('Quantity Needed',
                            style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _SquareIconButton(
                              icon: Icons.remove,
                              onTap: () => setState(() {
                                if (_qty > 1) _qty--;
                              }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _stroke, width: 1),
                                  color: Colors.white,
                                ),
                                child: Text(
                                  '$_qty',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _SquareIconButton(
                              icon: Icons.add,
                              onTap: () => setState(() => _qty++),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Text('Priority Level',
                            style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _PriorityPill(
                                label: 'Low',
                                selected: _priority == ReqPriority.low,
                                onTap: () => setState(() => _priority = ReqPriority.low),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PriorityPill(
                                label: 'Mid',
                                selected: _priority == ReqPriority.medium,
                                onTap: () => setState(() => _priority = ReqPriority.medium),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PriorityPill(
                                label: 'High',
                                selected: _priority == ReqPriority.high,
                                onTap: () => setState(() => _priority = ReqPriority.high),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Text('Notes / Justification',
                            style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _notesCtrl,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            hintText: 'Provide details about why this part is needed...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ---- Summary card ----
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _stroke),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Request Summary',
                            style: TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        _kv('Location:', _selectedLocationID ?? 'Not selected'),
                        const SizedBox(height: 6),
                        _kv('Part:', _selectedPartName),
                        const SizedBox(height: 6),
                        _kv('Quantity:', '$_qty'),
                        const SizedBox(height: 6),
                        _kv('Priority:', _priorityLabel(_priority)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ---- Submit ----
                SizedBox(
                  width: double.infinity,
                  child: _GradientButton(
                    label: _submitting ? 'Submitting...' : 'Submit Request',
                    icon: Icons.send_rounded,
                    onPressed: (_selectedPartId == null || _submitting) ? null : _onSubmit,
                  ),
                ),

                const SizedBox(height: 10),

                // ---- Cancel ----
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _stroke),
                      foregroundColor: _ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: _ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 14),
              const Text('Confirm Submission?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _stroke),
                        foregroundColor: _ink,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _submitting = true);
    try {
      await _service.createRequest(
        partId: _selectedPartId!,
        quantity: _qty,
        priority: _priorityLabel(_priority),
        notes: _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted')),
      );
      Navigator.maybePop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(k, style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Text(v, style: const TextStyle(fontSize: 14, color: _ink))),
      ],
    );
  }
}

/* ---------- Small UI helpers ---------- */

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _InventoryRequestScreenState._stroke, width: 1),
        ),
        child: Icon(icon, color: _InventoryRequestScreenState._ink),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityPill({
    required this.label,
    required this.selected,
    required this.onTap,


  });


  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.white : const Color(0xFFF3F4F6);
    final dotColor = selected ? _InventoryRequestScreenState._ink : const Color(0xFFBDBDBD);
    final border = selected ? _InventoryRequestScreenState._ink : _InventoryRequestScreenState._stroke;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 10, color: dotColor),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _InventoryRequestScreenState._ink,
                )),
          ],
        ),
      ),
    );
  }
}
