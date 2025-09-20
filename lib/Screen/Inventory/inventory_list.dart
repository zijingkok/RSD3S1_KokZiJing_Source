import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../Models/Inventory_models/parts.dart';
import '../../services/Inventory_services/inventory_service.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

enum StockFilter { all, inStock, lowStock }

class _InventoryListScreenState extends State<InventoryListScreen> {
  // ---- Shared palette (match other modules) ----
  static const _bg = Color(0xFFF5F7FA);
  static const _ink = Color(0xFF1D2A32);
  static const _muted = Color(0xFF6A7A88);
  static const _card = Colors.white;
  static const _stroke = Color(0xFFE6ECF1);
  static const _primary = Color(0xFF1E88E5);
  static const _primaryDark = Color(0xFF1565C0);

  final TextEditingController _search = TextEditingController();
  StockFilter _filter = StockFilter.all;
  final _inventoryService = InventoryService();

  List<Part> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadParts();
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: _muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    );
  }

  Future<void> _loadParts() async {
    try {
      final parts = await _inventoryService.fetchParts();
      setState(() {
        _items = parts;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching parts: $e');
      setState(() => _loading = false);
    }
  }

  // Open scanner and filter by scanned code
  Future<void> _scanAndFilter() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _BarcodeScannerPage()),
    );
    if (code == null || code.isEmpty) return;
    _search.text = code;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((e) {
      final q = _search.text.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty || e.name.toLowerCase().contains(q) || e.number.toLowerCase().contains(q);
      final matchesFilter = switch (_filter) {
        StockFilter.all => true,
        StockFilter.inStock => !e.lowStock,
        StockFilter.lowStock => e.lowStock,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    return Theme(
      data: _localTheme(context),
      child: RefreshIndicator(
        onRefresh: _loadParts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + kBottomNavigationBarHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header panel
              // Back button row (only if we can pop)
              if (Navigator.of(context).canPop()) ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _stroke),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0F000000), blurRadius: 22, offset: Offset(0, 10)),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF90CAF9), Color(0xFF1E88E5)],
                          ),
                        ),
                        child: const Icon(Icons.view_list_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inventory List',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('Search, filter, and scan parts',
                                style: TextStyle(fontSize: 14, color: _muted, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Search
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by part name or number...',
                ),
              ),
              const SizedBox(height: 8),

              // Scan barcode button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan barcode'),
                  onPressed: _scanAndFilter,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: _stroke),
                    foregroundColor: _ink,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter pills
              Wrap(
                spacing: 10,
                children: [
                  _FilterPill(
                    label: 'All',
                    selected: _filter == StockFilter.all,
                    onTap: () => setState(() => _filter = StockFilter.all),
                  ),
                  _FilterPill(
                    label: 'In Stock',
                    selected: _filter == StockFilter.inStock,
                    onTap: () => setState(() => _filter = StockFilter.inStock),
                  ),
                  _FilterPill(
                    label: 'Low Stock',
                    selected: _filter == StockFilter.lowStock,
                    onTap: () => setState(() => _filter = StockFilter.lowStock),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _card,
                    border: Border.all(color: _stroke),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_outlined, color: _muted, size: 40),
                      SizedBox(height: 8),
                      Text('No parts found',
                          style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
                      SizedBox(height: 2),
                      Text('Try a different search or filter', style: TextStyle(color: _muted)),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _InventoryCard(item: filtered[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- Scanner page (kept simple; styled app bar) ---------- */

class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage({super.key});

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;
    final value = codes.first.rawValue ?? '';
    if (value.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(controller: _controller, onDetect: _onDetect),
    );
  }
}

/* ---------- UI bits ---------- */

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selBg = _InventoryListScreenState._ink;
    const selFg = Colors.white;
    const unSelBg = Color(0xFFF3F4F6);
    const unSelFg = _InventoryListScreenState._ink;
    const stroke = _InventoryListScreenState._stroke;

    return Material(
      color: selected ? selBg : unSelBg,
      shape: StadiumBorder(side: BorderSide(color: selected ? selBg : stroke)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: selected ? selFg : unSelFg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Part item;
  const _InventoryCard({required this.item});

  static const _stroke = _InventoryListScreenState._stroke;
  static const _ink = _InventoryListScreenState._ink;
  static const _muted = _InventoryListScreenState._muted;
  static const _primary = _InventoryListScreenState._primary;
  static const _primaryDark = _InventoryListScreenState._primaryDark;

  @override
  Widget build(BuildContext context) {
    final dotColor = item.lowStock ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _stroke),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(item.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
              ),
              Icon(Icons.circle, size: 10, color: dotColor),
            ],
          ),
          const SizedBox(height: 4),
          Text('Part #: ${item.number}', style: const TextStyle(fontSize: 12.5, color: _muted)),
          const SizedBox(height: 8),

          // Stock + location
          Row(
            children: [
              Text('Stock: ${item.stockQuantity}', style: const TextStyle(fontSize: 14, color: _ink)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(item.location,
                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: _ink)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.show_chart, size: 18),
                  label: const Text('Usage History'),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/usage', arguments: item);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: _stroke),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PrimaryButton.icon(
                  icon: Icons.add,
                  label: 'Add Stock',
                  onPressed: () {
                    Navigator.of(context).pushNamed('/request', arguments: {
                      'source': 'parts',
                      'part': item,
                      'location': item.location,
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ---------- Shared primary gradient button ---------- */

class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  const _PrimaryButton({required this.onPressed, required this.label}) : icon = null;
  const _PrimaryButton.icon({required this.onPressed, required this.label, required this.icon});

  static const _primary = _InventoryListScreenState._primary;
  static const _primaryDark = _InventoryListScreenState._primaryDark;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );

    return Container(
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
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(child: child), // <-- show label & icon
          ),
        ),
      ),
    );
  }
}

