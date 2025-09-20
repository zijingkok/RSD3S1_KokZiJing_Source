import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Models/Inventory_models/procurement_request_item.dart';
import '../../services/Inventory_services/procurement_service.dart';

class ProcurementRequestsScreen extends StatefulWidget {
  const ProcurementRequestsScreen({super.key});

  @override
  State<ProcurementRequestsScreen> createState() => _ProcurementRequestsScreenState();
}

enum ReqStatus { all, pending, approved, arrived }

const _ink = Color(0xFF1D2A32);
const _muted = Color(0xFF6A7A88);
const _chipBg = Color(0xFFF3F4F6);
const _stroke = Color(0xFFB5B5B5);

class _ProcurementRequestsScreenState extends State<ProcurementRequestsScreen> {
  ReqStatus _filter = ReqStatus.all;
  final _service = ProcurementService();

  // Shared palette to match the rest of your app
  static const _ink = Color(0xFF1D2A32);
  static const _muted = Color(0xFF6A7A88);
  static const _stroke = Color(0xFFB5B5B5);
  static const _chipBg = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(width: 1, color: _stroke);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + kBottomNavigationBarHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + Title (same header pattern you used)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.maybePop(context),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Procurement Requests',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Filter chips
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
                    label: 'Arrived',
                    selected: _filter == ReqStatus.arrived,
                    onTap: () => setState(() => _filter = ReqStatus.arrived),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Realtime list
              Expanded(
                child: StreamBuilder<List<ProcurementRequest>>(
                  stream: _service.streamRequests(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final all = snapshot.data ?? const <ProcurementRequest>[];

                    final items = all.where((r) {
                      switch (_filter) {
                        case ReqStatus.all:
                          return true;
                        case ReqStatus.pending:
                          return r.status.toLowerCase() == 'pending';
                        case ReqStatus.approved:
                          return r.status.toLowerCase() == 'approved';
                        case ReqStatus.arrived:
                        // accept both "arrived" and "ordered" if your data used that earlier
                          final s = r.status.toLowerCase();
                          return s == 'arrived' || s == 'ordered';
                      }
                    }).toList()
                      ..sort((a, b) => b.requestDate.compareTo(a.requestDate));

                    if (items.isEmpty) {
                      return const Center(child: Text('No requests found.'));
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final r = items[i];
                        return _RequestCard(
                          req: r,
                          border: border,
                          onStatusChange: (newStatus) async {
                            try {
                              await _service.updateStatus(
                                requestId: r.id,
                                status: newStatus,
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update: $e')),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* --------------------------------- UI bits --------------------------------- */

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
    const selBg = _ProcurementRequestsScreenState._ink;
    const selFg = Colors.white;
    const unSelBg = _ProcurementRequestsScreenState._chipBg;
    const unSelFg = _ProcurementRequestsScreenState._ink;
    const stroke = _ProcurementRequestsScreenState._stroke;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selBg : unSelBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? selBg : stroke),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: selected ? selFg : unSelFg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}


class _RequestCard extends StatelessWidget {
  final ProcurementRequest req;
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
            // Top row: ID + status + menu
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Request ID: ${req.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusBadge(statusText: req.status),
                const SizedBox(width: 4),

              ],
            ),
            const SizedBox(height: 8),

            Text(
              req.partName ?? 'Unknown Part',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
            ),
            const SizedBox(height: 6),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Qty + date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qty: ${req.quantity} Units',
                      style: const TextStyle(fontSize: 14, color: _ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      df.format(req.requestDate),
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  req.highPriority ? 'Urgent' : (req.priority.isEmpty ? 'Normal' : req.priority),
                  style: const TextStyle(fontSize: 13, color: _ink, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String statusText; // pending / approved / arrived
  const _StatusBadge({required this.statusText});

  @override
  Widget build(BuildContext context) {
    final s = statusText.toLowerCase();
    late final String label;
    late final Color textColor;
    late final Color bgColor;
    late final Color borderColor;

    // Muted pill style to match the rest of your chips
    if (s == 'pending') {
      label = 'Pending';
      textColor = const Color(0xFF92400E);
      bgColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFF3D9C2);
    } else if (s == 'approved') {
      label = 'Approved';
      textColor = const Color(0xFF065F46);
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFB7F0DA);
    } else if (s == 'arrived' || s == 'ordered') {
      label = 'Arrived';
      textColor = const Color(0xFF1D4ED8);
      bgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFBFDBFE);
    } else {
      label = statusText;
      textColor = const Color(0xFF374151);
      bgColor = const Color(0xFFF3F4F6);
      borderColor = const Color(0xFFE5E7EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
