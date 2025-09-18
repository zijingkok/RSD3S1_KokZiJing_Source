import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/procurement_service.dart';

class ProcurementRequestsScreen extends StatefulWidget {
  const ProcurementRequestsScreen({super.key});

  @override
  State<ProcurementRequestsScreen> createState() => _ProcurementRequestsScreenState();
}

enum ReqStatus { all, pending, approved, ordered }

class _ProcurementRequestsScreenState extends State<ProcurementRequestsScreen> {
  ReqStatus _filter = ReqStatus.all;

  final _service = ProcurementService();
  List<ProcurementRequestItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final list = await _service.fetchRequests();
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading requests: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(width: 1, color: Color(0xFFB5B5B5));

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // client-side filter by status
    final filtered = _items.where((r) {
      switch (_filter) {
        case ReqStatus.all:
          return true;
        case ReqStatus.pending:
          return r.status.toLowerCase() == 'pending';
        case ReqStatus.approved:
          return r.status.toLowerCase() == 'approved';
        case ReqStatus.ordered:
          return r.status.toLowerCase() == 'ordered';
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              _RequestCard(req: r, border: border, onStatusChange: (newStatus) async {
                try {
                  await _service.updateStatus(requestId: r.id, status: newStatus);
                  _loadRequests(); // refresh
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')),
                  );
                }
              }),
              const SizedBox(height: 12),
            ],
          ],
        ),
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
  final ProcurementRequestItem req;
  final BorderSide border;
  final Future<void> Function(String newStatus) onStatusChange;

  const _RequestCard({
    required this.req,
    required this.border,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: Text(
                    'Request ID: ${req.id.substring(0, 8)}', // show short id
                    style: const TextStyle(
                      fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StatusBadge(statusText: req.status),
              ],
            ),
            const SizedBox(height: 8),

            Text(req.partName,
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
                Text(req.highPriority ? 'High Priority' : req.priority,
                    style: const TextStyle(
                      fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600,
                    )),
              ],
            ),
            const SizedBox(height: 12),

            // Quick actions (optional)

          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String statusText; // 'Pending' | 'Approved' | 'Ordered'
  const _StatusBadge({required this.statusText});

  @override
  Widget build(BuildContext context) {
    final s = statusText.toLowerCase();
    late final String label;
    late final Color color;

    if (s == 'pending') {
      label = 'Pending';
      color = const Color(0xFF7C3AED); // purple
    } else if (s == 'approved') {
      label = 'Approved';
      color = const Color(0xFF16A34A); // green
    } else if (s == 'ordered') {
      label = 'Ordered';
      color = const Color(0xFF2563EB); // blue
    } else {
      label = statusText;
      color = const Color(0xFF9CA3AF);
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
