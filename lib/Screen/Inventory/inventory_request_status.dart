import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProcurementRequestsScreen extends StatefulWidget {
  const ProcurementRequestsScreen({super.key});

  @override
  State<ProcurementRequestsScreen> createState() => _ProcurementRequestsScreenState();
}

enum ReqStatus { all, pending, approved, ordered }

class _ProcurementRequestsScreenState extends State<ProcurementRequestsScreen> {
  ReqStatus _filter = ReqStatus.all;

  final _requests = <_Request>[
    _Request(
      id: 'PR-2025-001',
      itemName: 'Bearing Set',
      qty: 25,
      date: DateTime(2025, 1, 15),
      highPriority: true,
      status: ReqStatus.pending,
    ),
    _Request(
      id: 'PR-2025-002',
      itemName: 'Brake Pads - Front',
      qty: 12,
      date: DateTime(2025, 1, 12),
      highPriority: false,
      status: ReqStatus.approved,
    ),
    _Request(
      id: 'PR-2025-003',
      itemName: 'Air Filter',
      qty: 50,
      date: DateTime(2025, 1, 5),
      highPriority: true,
      status: ReqStatus.ordered,
    ),
    _Request(
      id: 'PR-2025-004',
      itemName: 'Bearing Set',
      qty: 25,
      date: DateTime(2025, 1, 15),
      highPriority: true,
      status: ReqStatus.pending,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(width: 1, color: Color(0xFFB5B5B5));
    final filtered = _requests.where((r) {
      switch (_filter) {
        case ReqStatus.all:      return true;
        case ReqStatus.pending:  return r.status == ReqStatus.pending;
        case ReqStatus.approved: return r.status == ReqStatus.approved;
        case ReqStatus.ordered:  return r.status == ReqStatus.ordered;
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + kBottomNavigationBarHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 4),
              const Text('Procurement Requests',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),

          // Filters
          Wrap(
            spacing: 10,
            children: [
              _FilterPill(
                label: 'All',
                selected: _filter == ReqStatus.all,
                onTap: () => setState(() => _filter = ReqStatus.all),
              ),
              _FilterPill(
                label: 'Pending',
                selected: _filter == ReqStatus.pending,
                onTap: () => setState(() => _filter = ReqStatus.pending),
              ),
              _FilterPill(
                label: 'Approved',
                selected: _filter == ReqStatus.approved,
                onTap: () => setState(() => _filter = ReqStatus.approved),
              ),
              _FilterPill(
                label: 'Ordered',
                selected: _filter == ReqStatus.ordered,
                onTap: () => setState(() => _filter = ReqStatus.ordered),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cards
          for (final r in filtered) ...[
            _RequestCard(req: r, border: border),
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
          border: Border.all(color: selected ? selBg : const Color(0xFFB5B5B5)),
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

class _RequestCard extends StatelessWidget {
  final _Request req;
  final BorderSide border;
  const _RequestCard({required this.req, required this.border});

  @override
  Widget build(BuildContext context) {
    //Database intergration------------------------------------------------------------
    final df = DateFormat('MMM d, yyyy');
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: ID + status badge
            Row(
              children: [
                Expanded(
                  child: Text('Request ID: ${req.id}',
                      style: const TextStyle(
                        fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600,
                      )),
                ),
                _StatusBadge(status: req.status),
              ],
            ),
            const SizedBox(height: 8),

            Text(req.itemName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Qty + date (stack)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qty: ${req.qty} Units',
                        style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(df.format(req.date),
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
                const Spacer(),
                Text(req.highPriority ? 'High Priority' : 'Normal Priority',
                    style: const TextStyle(
                      fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
    //Database intergration------------------------------------------------------------
  }
}

class _StatusBadge extends StatelessWidget {
  final ReqStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;

    switch (status) {
      case ReqStatus.pending:
        label = 'Pending';
        color = const Color(0xFF7C3AED); // purple
        break;
      case ReqStatus.approved:
        label = 'Approved';
        color = const Color(0xFF16A34A); // green
        break;
      case ReqStatus.ordered:
        label = 'Ordered';
        color = const Color(0xFF2563EB); // blue
        break;
      case ReqStatus.all:
        label = '';
        color = Colors.transparent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Request {
  final String id;
  final String itemName;
  final int qty;
  final DateTime date;
  final bool highPriority;
  final ReqStatus status;

  _Request({
    required this.id,
    required this.itemName,
    required this.qty,
    required this.date,
    required this.highPriority,
    required this.status,
  });
}
