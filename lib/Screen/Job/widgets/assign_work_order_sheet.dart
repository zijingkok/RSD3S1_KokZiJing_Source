
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/work_order_store.dart';
import '../../../state/mechanic_store.dart';
import '../../../Models/work_order.dart';
import '../../../Models/mechanic.dart';
import '../../../ui/crm_style.dart';

class AssignWorkOrderResult {
  final String mechanicId;
  final DateTime start;
  AssignWorkOrderResult({required this.mechanicId, required this.start});
}

class AssignWorkOrderSheet extends StatefulWidget {
  const AssignWorkOrderSheet({
    super.key,
    this.initialMechanicId,
    this.initialStart,
  });

  final String? initialMechanicId;
  final DateTime? initialStart; // if provided, window will align to this date

  @override
  State<AssignWorkOrderSheet> createState() => _AssignWorkOrderSheetState();
}

class _AssignWorkOrderSheetState extends State<AssignWorkOrderSheet> {
  String? _mechanicId;
  DateTime? _date;
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    _mechanicId = widget.initialMechanicId;
    if (widget.initialStart != null) {
      _date = DateTime(widget.initialStart!.year, widget.initialStart!.month, widget.initialStart!.day);
      _time = TimeOfDay(hour: widget.initialStart!.hour, minute: widget.initialStart!.minute);
    }
  }

  bool _isOpenStatus(WorkOrderStatus s) {
    switch (s) {
      case WorkOrderStatus.completed:
        return false;
      case WorkOrderStatus.unassigned:
      case WorkOrderStatus.scheduled:
      case WorkOrderStatus.inProgress:
      case WorkOrderStatus.onHold:
        return true;
    }
  }

  (DateTime, DateTime, int) _windowFromAnchor(DateTime anchor) {
    // Window: anchor's day (00:00) inclusive to +7 days (exclusive)
    final start = DateTime(anchor.year, anchor.month, anchor.day);
    final end = start.add(const Duration(days: 8));
    final days = end.difference(start).inDays;
    return (start, end, days);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final initial = _time ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final woStore = context.watch<WorkOrderStore>();
    final mechStore = context.watch<MechanicStore>();

    // Active mechanics only
    final mechanics = mechStore.mechanics.where((m) => m.active).toList();

    // Choose anchor for window: prefer initialStart, else today
    final anchor = widget.initialStart ?? DateTime.now();
    final (wStart, wEnd, wDays) = _windowFromAnchor(anchor);

    // Precompute planned hours per mechanic for the window to sort dropdown
    final Map<String, double> plannedHours = { for (final m in mechanics) m.id.trim(): 0.0 };
    for (final w in woStore.workOrders) {
      if (!_isOpenStatus(w.status)) continue;
      final idRaw = (w.assignedMechanicId ?? '').trim();
      if (idRaw.isEmpty) continue; // unassigned orders don't contribute to a mechanic's utilization
      final d = w.scheduledDate;
      // Include order if it falls in window; if undated, include (manager usually uses dropdown to plan ahead)
      final inWindow = d == null ? true : (!d.isBefore(wStart) && d.isBefore(wEnd));
      if (!inWindow) continue;
      final est = (w.estimatedHours ?? 0).toDouble();
      plannedHours[idRaw] = (plannedHours[idRaw] ?? 0.0) + est;
    }

    // Build scored list (utilization + free hours)
    final List<_MechanicScore> scored = [];
    for (final m in mechanics) {
      final capPerDay = (m.dailyCapacityHours).toDouble();
      final capacity = (capPerDay <= 0 ? 8.0 : capPerDay) * wDays;
      final hours = plannedHours[m.id.trim()] ?? 0.0;
      final util = capacity > 0 ? hours / capacity : 0.0;
      final free = capacity - hours;
      scored.add(_MechanicScore(m: m, utilization: util, freeHours: free));
    }

    // Sort: lowest utilization first, then highest free hours, then name
    scored.sort((a, b) {
      if (a.utilization != b.utilization) return a.utilization.compareTo(b.utilization);
      if (a.freeHours != b.freeHours) return b.freeHours.compareTo(a.freeHours);
      return a.m.name.toLowerCase().compareTo(b.m.name.toLowerCase());
    });

    // Build dropdown items
    final items = scored.map((s) {
      final pct = (s.utilization * 100).clamp(0, 999).toStringAsFixed(0);
      final free = s.freeHours.toStringAsFixed(1);
      final label = '${s.m.name} — $pct% util • ${free}h free';
      return DropdownMenuItem<String>(value: s.m.id, child: Text(label));
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 12,
              bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ListView(
              controller: controller,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Assign work order', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                // Dropdown (sorted by lowest utilization)
                InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Mechanic (lowest util shown on top)',
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _mechanicId ?? (items.isNotEmpty ? items.first.value : null),
                      items: items,
                      onChanged: (v) => setState(() => _mechanicId = v),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Date + Time pickers
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: CrmColors.primary),
                        ),
                        onPressed: _pickDate,
                        child: Text(_date == null
                            ? 'Pick Date'
                            : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: CrmColors.primary),
                        ),
                        onPressed: _pickTime,
                        child: Text(_time == null
                            ? 'Pick Time'
                            : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Confirm
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_mechanicId != null && _date != null && _time != null)
                        ? () async {
                      final dt = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
                      if (!mounted) return;
                      Navigator.of(context).pop(AssignWorkOrderResult(mechanicId: _mechanicId!, start: dt));
                    }
                        : null,
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MechanicScore {
  final Mechanic m;
  final double utilization;
  final double freeHours;
  _MechanicScore({required this.m, required this.utilization, required this.freeHours});
}
