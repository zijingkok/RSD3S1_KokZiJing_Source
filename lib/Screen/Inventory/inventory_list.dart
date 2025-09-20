import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../Models/parts.dart';
import '../../services/inventory_service.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

enum StockFilter { all, inStock, lowStock }

class _InventoryListScreenState extends State<InventoryListScreen> {
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

  // 🔹 Open scanner and filter by scanned code
  Future<void> _scanAndFilter() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _BarcodeScannerPage()),
    );

    if (code == null || code.isEmpty) return;

    // Fill search with the scanned code and refresh results.
    // Here we assume your barcode equals Part.number; adjust if you store a separate barcode field.
    _search.text = code;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(width: 1, color: Color(0xFFB5B5B5));

    final filtered = _items.where((e) {
      final q = _search.text.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
              e.name.toLowerCase().contains(q) ||
              e.number.toLowerCase().contains(q); // <- match on number (barcode)
      final matchesFilter = switch (_filter) {
        StockFilter.all => true,
        StockFilter.inStock => !e.lowStock,
        StockFilter.lowStock => e.lowStock,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadParts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + kBottomNavigationBarHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 4),
                const Text('Inventory List',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),

            // Search bar
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by part name or number...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 🔹 Scan barcode button (below search bar)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan barcode'),
                onPressed: _scanAndFilter,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFFB5B5B5)),
                  foregroundColor: Colors.black87,
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

            // List
            for (final item in filtered) ...[
              _InventoryCard(item: item, border: border),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

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
      body: MobileScanner(
        controller: _controller,
        onDetect: _onDetect,
      ),
    );
  }
}



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
    final selBg = Colors.black87;
    final selFg = Colors.white;
    final unSelBg = const Color(0xFFF3F4F6);
    final unSelFg = Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selBg : unSelBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? selBg : const Color(0xFFB5B5B5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? selFg : unSelFg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Part item;
  final BorderSide border;

  const _InventoryCard({required this.item, required this.border});

  @override
  Widget build(BuildContext context) {
    final dotColor = item.lowStock
        ? const Color(0xFFDC2626) // red = low stock
        : const Color(0xFF9CA3AF); // grey = ok

    return Card(
      shape: RoundedRectangleBorder(
        side: border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Part name + status dot
            Row(
              children: [
                Expanded(
                  child: Text(item.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                Icon(Icons.circle, size: 10, color: dotColor),
              ],
            ),
            const SizedBox(height: 4),
            Text("Part #: ${item.number}",
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),

            // Stock + location
            Row(
              children: [
                Text('Stock: ${item.stockQuantity}',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(item.location,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 🔹 Buttons row
            Row(
              children: [
                // Usage History button
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.show_chart, size: 18),
                    label: const Text('Usage History'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/usage',
                        arguments: item, // pass the part to usage page
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: border.color),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Request More button
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Request More'),



                    // In your parts list screen
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/request',
                        arguments: {
                          'source': 'parts',
                          'part': item,               // Part
                          'location': item.location,  // optional
                        },
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
