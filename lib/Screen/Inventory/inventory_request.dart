import 'package:flutter/material.dart';
import '../../Models/parts.dart';
import '../../services/procurement_service.dart';

class InventoryRequestScreen extends StatefulWidget {
  const InventoryRequestScreen({super.key});

  @override
  State<InventoryRequestScreen> createState() => _InventoryRequestScreenState();
}

enum ReqPriority { low, medium, high }

class _InventoryRequestScreenState extends State<InventoryRequestScreen> {
  final _codeCtrl = TextEditingController();   // UI-only (not stored unless you add a column)
  final _notesCtrl = TextEditingController();

  final _service = ProcurementService();

  // Data fetched from service (must include: part_id, part_name, part_number, location, stock_quantity)
  List<Map<String, dynamic>> _parts = [];

  // Distinct locations from _parts.location
  List<String> _locations = [];

  String? _selectedLocation;   // dropdown #1
  String? _selectedPartId;     // dropdown #2
  int _qty = 1;
  ReqPriority _priority = ReqPriority.medium;
  bool _loading = true;
  bool _submitting = false;

  // ---- Prefill (only when coming from parts list) ----
  bool _didReadArgs = false;
  bool _shouldPrefill = false;
  Part? _prefillPart;
  String? _prefillLocation;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadParts() async {
    try {
      final parts = await _service.fetchParts(); // <-- ensure this returns location & stock_quantity
      final locs = parts
          .map((p) => (p['location'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _parts = parts;
        _locations = locs;
        _loading = false;
      });

      if (_shouldPrefill) _applyPrefillIfAny();
    } catch (e) {
      debugPrint("Error loading parts: $e");
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
          final maybeLoc  = args['location'];
          if (maybePart is Part) _prefillPart = maybePart;
          if (maybeLoc is String && maybeLoc.isNotEmpty) _prefillLocation = maybeLoc;
        }
      }
      if (!_loading && _shouldPrefill) _applyPrefillIfAny();
    });
  }

  // Apply prefill only once after _parts is available
  void _applyPrefillIfAny() {
    if (!_shouldPrefill) return;

    // Prefer explicit location from args; else from Part model
    final loc = _prefillLocation ?? _prefillPart?.location;
    String? partId;

    if (_prefillPart != null) {
      // Find the matching part_id from fetched list by id, or fallbacks by number/name (scoped by location if provided)
      final match = _parts.firstWhere(
            (p) =>
        p['part_id'] == _prefillPart!.id ||
            (p['part_number'] == _prefillPart!.number && _prefillPart!.number.isNotEmpty) ||
            (p['part_name'] == _prefillPart!.name && (loc == null || p['location'] == loc)),
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        partId = match['part_id'] as String?;
      }
    }

    setState(() {
      // Set location first so Part dropdown filters correctly
      if (loc != null && loc.isNotEmpty && _locations.contains(loc)) {
        _selectedLocation = loc;
      } else if (_locations.isNotEmpty && _selectedLocation == null) {
        // Optional fallback to first location if nothing provided
        _selectedLocation = _locations.first;
      }

      // Only preselect the part if it belongs to the selected location
      if (partId != null) {
        final belongs = _parts.any((p) =>
        p['part_id'] == partId &&
            (_selectedLocation == null || p['location'] == _selectedLocation));
        _selectedPartId = belongs ? partId : null;
      }
    });

    // Clear after applying so rebuilds don't re-run it
    _prefillPart = null;
    _prefillLocation = null;
    _shouldPrefill = false;
  }

  String get _selectedPartName {
    for (final p in _parts) {
      if (p['part_id'] == _selectedPartId) {
        final name = p['part_name'] as String? ?? 'Unknown';
        final loc  = p['location'] as String? ?? '';
        final stock = (p['stock_quantity'] ?? 0).toString();
        return loc.isEmpty ? '$name (Stock: $stock)' : '$name — [$loc] (Stock: $stock)';
      }
    }
    return 'Not selected';
  }

  String _priorityLabel(ReqPriority p) {
    switch (p) {
      case ReqPriority.low:
        return 'Low';
      case ReqPriority.medium:
        return 'Normal'; // map Medium -> Normal to match DB default
      case ReqPriority.high:
        return 'Urgent';
    }
  }

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(width: 1, color: Color(0xFFB5B5B5));

    // Read args exactly once on first build
    _readArgsOnceIfNeeded();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter parts by selected location
    final filteredParts = (_selectedLocation == null || _selectedLocation!.isEmpty)
        ? <Map<String, dynamic>>[]
        : _parts.where((p) => (p['location'] ?? '') == _selectedLocation).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + kBottomNavigationBarHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 4),
              const Text('New Request',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),

          // Select Location
          const Text('Select Location', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedLocation,
            isExpanded: true,
            items: _locations
                .map((loc) => DropdownMenuItem(
              value: loc,
              child: Text(loc),
            ))
                .toList(),
            onChanged: (v) {
              setState(() {
                _selectedLocation = v;
                _selectedPartId = null; // reset part when location changes
              });
            },
            validator: (v) => (v == null || v.isEmpty) ? 'Please select a location' : null,
            decoration: InputDecoration(
              labelText: 'Location',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Select Part (filtered by location)
          const Text('Select Part', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedPartId,
            isExpanded: true,
            items: filteredParts.map((p) {
              final name = p['part_name'] as String? ?? 'Unknown';
              final loc  = p['location'] as String? ?? '';
              final stock = (p['stock_quantity'] ?? 0).toString();
              final label = loc.isEmpty ? '$name (Stock: $stock)'
                  : '$name — [$loc] (Stock: $stock)';
              return DropdownMenuItem(
                value: p['part_id'] as String,
                child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedPartId = v),
            validator: (v) => (v == null || v.isEmpty) ? 'Please select a part' : null,
            decoration: InputDecoration(
              labelText: 'Part',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Optional reference code (UI only)
          TextField(
            controller: _codeCtrl,
            decoration: InputDecoration(
              hintText: 'Enter Reference Code (optional)',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quantity
          const Text('Quantity Needed', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            children: [
              _SquareIconButton(
                icon: Icons.remove,
                onTap: () => setState(() { if (_qty > 1) _qty--; }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border.color, width: 1),
                    color: Colors.white,
                  ),
                  child: Text('$_qty',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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

          // Priority
          const Text('Priority Level', style: TextStyle(fontSize: 13, color: Colors.black54)),
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
                  label: 'Medium',
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

          // Notes
          const Text('Notes/Justification', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesCtrl,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Provide details about why this part is needed...',
              alignLabelWithHint: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Summary card
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              side: border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Summary',
                      style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _kv('Location:', _selectedLocation ?? 'Not selected'),
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

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedPartId == null || _submitting)
                  ? null
                  : () async {
                setState(() => _submitting = true);
                try {
                  await _service.createRequest(
                    partId: _selectedPartId!,           // part already implies location
                    quantity: _qty,
                    priority: _priorityLabel(_priority),
                    notes: _notesCtrl.text,             // ignored unless you add 'notes' column
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request submitted')),
                    );
                    Navigator.maybePop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _submitting = false);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _submitting ? 'Submitting...' : 'Submit Request',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Cancel
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Color(0xFFB5B5B5)),
                foregroundColor: Colors.black87,
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(k, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ),
        Expanded(
          child: Text(v, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
      ],
    );
  }
}

// ---- Small UI helpers ----

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
          border: Border.all(color: const Color(0xFFB5B5B5), width: 1),
        ),
        child: Icon(icon, color: Colors.black87),
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
    final dotColor = selected ? Colors.black87 : const Color(0xFFBDBDBD);
    final border = selected ? Colors.black87 : const Color(0xFFB5B5B5);

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
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
