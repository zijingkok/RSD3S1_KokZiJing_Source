import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:workshop_management/Models/Inventory_models/part_usage_event.dart';
import '../../Models/Inventory_models/parts.dart';
import '../../services/Inventory_services/part_usage_service.dart';

class PartUsageHistoryScreen extends StatefulWidget {
  const PartUsageHistoryScreen({super.key});

  @override
  State<PartUsageHistoryScreen> createState() => _PartUsageHistoryScreenState();
}

enum UsageFilter { all, thisMonth, last30 }

class _PartUsageHistoryScreenState extends State<PartUsageHistoryScreen> {
  UsageFilter _filter = UsageFilter.all;
  final _usageService = PartUsageService();

  List<PartUsageEvent> _events = [];
  bool _loading = true;
  int totalIn = 0;
  int totalOut = 0;
  int currentStock = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final part = ModalRoute.of(context)!.settings.arguments as Part;
    _loadUsage(part.id, part.stockQuantity);
  }

  Future<void> _loadUsage(String partId, int stock) async {
    setState(() => _loading = true);
    try {
      final events = await _usageService.fetchUsageHistory(partId);
      final summary = await _usageService.fetchUsageSummary(partId);

      setState(() {
        _events = events.cast<PartUsageEvent>();
        totalIn = summary['in'] ?? 0;
        totalOut = summary['out'] ?? 0;
        currentStock = stock;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error loading usage history: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final last30Start = now.subtract(const Duration(days: 30));
    final monthStart = DateTime(now.year, now.month, 1);

    final filtered = _events.where((e) {
      return switch (_filter) {
        UsageFilter.all => true,
        UsageFilter.thisMonth => e.dateTime.isAfter(monthStart),
        UsageFilter.last30 => e.dateTime.isAfter(last30Start),
      };
    }).toList();

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
              const Text(
                'Part Usage History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Part name + number
          Text(
            ModalRoute.of(context)!.settings.arguments is Part
                ? (ModalRoute.of(context)!.settings.arguments as Part).name
                : '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            ModalRoute.of(context)!.settings.arguments is Part
                ? "Part #: ${(ModalRoute.of(context)!.settings.arguments as Part).number}"
                : '',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),

          // KPIs
          Row(
            children: [
              Expanded(
                child: _KpiWideCard(label: 'CURRENT STOCK', value: '$currentStock Units'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(label: 'TOTAL OUT', value: '$totalIn'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Filters
          Wrap(
            spacing: 10,
            children: [
              _FilterPill(
                label: 'All',
                selected: _filter == UsageFilter.all,
                onTap: () => setState(() => _filter = UsageFilter.all),
              ),
              _FilterPill(
                label: 'This Month',
                selected: _filter == UsageFilter.thisMonth,
                onTap: () => setState(() => _filter = UsageFilter.thisMonth),
              ),
              _FilterPill(
                label: 'Last 30 Days',
                selected: _filter == UsageFilter.last30,
                onTap: () => setState(() => _filter = UsageFilter.last30),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Events
          for (final e in filtered) ...[
            _UsageCard(event: e),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  const _KpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 1, color: Color(0xFFB5B5B5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54,
                )),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}

class _KpiWideCard extends StatelessWidget {
  final String label;
  final String value;
  const _KpiWideCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 1, color: Color(0xFFB5B5B5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54,
                )),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    this.onTap,
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

// Change _UsageCard signature
class _UsageCard extends StatelessWidget {
  final PartUsageEvent event;   // ✅ use real model now
  const _UsageCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final border = const BorderSide(width: 1, color: Color(0xFFB5B5B5));
    final date = DateFormat("MMM d, yyyy").format(event.dateTime);
    final time = DateFormat("hh.mm a").format(event.dateTime);

    // Badge colors
    final isOut = event.deltaUnits < 0;
    final badgeBg = isOut ? const Color(0xFF7C3AED) : const Color(0xFF16A34A);
    final badgeText = '${isOut ? '' : '-'}${event.deltaUnits} Units';

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
            // Top row: date/time + delta badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date,
                          style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(time,
                          style: const TextStyle(
                            fontSize: 12, color: Colors.black54,
                          )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            _kv('Work Order', event.workOrder),
            const SizedBox(height: 6),
            _kv('Mechanic', event.mechanic),
            const SizedBox(height: 6),
            _kv('Department', event.department),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(k,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ),
        Expanded(
          child: Text(v,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
      ],
    );
  }
}



