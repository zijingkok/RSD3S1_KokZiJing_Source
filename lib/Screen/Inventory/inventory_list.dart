import 'package:flutter/material.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

enum StockFilter { all, inStock, lowStock }

class _InventoryListScreenState extends State<InventoryListScreen> {
  final TextEditingController _search = TextEditingController();
  StockFilter _filter = StockFilter.all;

  final _items = <_InvItem>[
    _InvItem(
      name: 'Brake Pads - Front',
      partNo: 'BP-12345-001',
      stock: 24,
      location: 'Warehouse A - Shelf 4B',
      lowStock: false,
    ),
    _InvItem(
      name: 'Air Filter',
      partNo: 'AF-99881-221',
      stock: 3,
      location: 'Warehouse B - Rack 2',
      lowStock: true,
    ),
    _InvItem(
      name: 'Engine Oil 5W-30',
      partNo: 'EO-5W30-4L',
      stock: 56,
      location: 'Warehouse C - Bay 1',
      lowStock: false,
    ),
    _InvItem(
      name: 'Brake Pads - Front',
      partNo: 'BP-12345-001',
      stock: 24,
      location: 'Warehouse A - Shelf 4B',
      lowStock: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(width: 1, color: Color(0xFFB5B5B5));

    final filtered = _items.where((e) {
      final q = _search.text.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.partNo.toLowerCase().contains(q);
      final matchesFilter = switch (_filter) {
        StockFilter.all => true,
        StockFilter.inStock => !e.lowStock,
        StockFilter.lowStock => e.lowStock,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16, 16, 16, 16 + kBottomNavigationBarHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row (inline back button + title)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 4),
              const Text(
                'Inventory',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search bar
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by part name or number...',
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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

          // Filter chips row
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

          // Items list
          for (final item in filtered) ...[
            _InventoryCard(item: item, border: border),
            const SizedBox(height: 12),
          ],
        ],
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
          border: Border.all(
            color: selected ? selBg : const Color(0xFFB5B5B5),
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 14,
              color: selected ? selFg : unSelFg,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final _InvItem item;
  final BorderSide border;

  const _InventoryCard({
    required this.item,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = item.lowStock ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF);

    return Card(
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
            // Title + status dot
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TitleBlock(name: item.name, partNo: item.partNo),
                ),
                const SizedBox(width: 8),
                Icon(Icons.circle, size: 10, color: dotColor),
              ],
            ),
            const SizedBox(height: 8),

            // Stock + location
            Row(
              children: [
                Text('Stock: ${item.stock}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(item.location,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Colors.black87)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Buttons row
            Row(
              children: [



                //Go to part Usage History
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.show_chart, size: 18),
                    label: const Text('Usage History'),
                    onPressed: () => Navigator.of(context).pushNamed('/usage'),           //Go to part Usage History
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


                //Go to Request Page
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Request More'),
                    onPressed: () => Navigator.of(context).pushNamed('/request'),          //Go to Request Page
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

class _TitleBlock extends StatelessWidget {
  final String name;
  final String partNo;
  const _TitleBlock({required this.name, required this.partNo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('Part #:$partNo',
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _InvItem {
  final String name;
  final String partNo;
  final int stock;
  final String location;
  final bool lowStock;

  const _InvItem({
    required this.name,
    required this.partNo,
    required this.stock,
    required this.location,
    required this.lowStock,
  });
}
