import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/work_order_store.dart';
import '../../state/mechanic_store.dart';
import '../../Models/work_order.dart';
import 'widgets/assign_work_order_sheet.dart';
import '../../Models/mechanic.dart';

class JobTaskTab extends StatefulWidget {
  const JobTaskTab({super.key});

  @override
  State<JobTaskTab> createState() => _JobTaskTabState();
}

class _JobTaskTabState extends State<JobTaskTab> {
  WorkOrderStatus? _filter; // null = all
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;


  // status + search filter
  List<WorkOrder> _applyFilter(List<WorkOrder> items) {
    var result = items;

    if (_filter != null) {
      result = result.where((wo) => wo.status == _filter).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      final mechStore = context.read<MechanicStore>();

      result = result.where((wo) {
        final mechanic = mechStore.byId(wo.assignedMechanicId);
        final mechName = mechanic?.name.toLowerCase() ?? "";

        return (wo.title.toLowerCase().contains(query)) ||
            (wo.code.toLowerCase().contains(query)) ||
            (mechName.contains(query));
      }).toList();
    }

    // 🔎 filter by selected date
    if (_selectedDate != null) {
      result = result.where((wo) {
        if (wo.scheduledStart == null) return false;
        final d = wo.scheduledStart!;
        return d.year == _selectedDate!.year &&
            d.month == _selectedDate!.month &&
            d.day == _selectedDate!.day;
      }).toList();
    }

    return result;
  }


  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<WorkOrderStore>().fetch());
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkOrderStore>();
    final items = store.workOrders;

    if (store.loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _applyFilter(store.workOrders);

    return Column(
      children: [
        // 🔎 Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title, code, mechanic...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.date_range),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              if (_selectedDate != null) // show clear only when active
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _selectedDate = null),
                ),
            ],
          ),
        ),


        _buildFilterBar(),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<WorkOrderStore>().fetch(),
            child: filtered.isEmpty
                ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(child: Text('No work orders for this filter.')),
              ],
            )
                : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _WorkOrderTile(wo: filtered[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(label: "All", active: _filter == null, onTap: () => setState(() => _filter = null)),
            _FilterChip(
              label: "Unassigned",
              color: Colors.redAccent,
              active: _filter == WorkOrderStatus.unassigned,
              onTap: () => setState(() => _filter = WorkOrderStatus.unassigned),
            ),
            _FilterChip(
              label: "Accepted",
              color: Colors.blueAccent,
              active: _filter == WorkOrderStatus.accepted,
              onTap: () => setState(() => _filter = WorkOrderStatus.accepted),
            ),
            _FilterChip(
              label: "In Progress",
              color: Colors.orange,
              active: _filter == WorkOrderStatus.inProgress,
              onTap: () => setState(() => _filter = WorkOrderStatus.inProgress),
            ),
            _FilterChip(
              label: "On Hold",
              color: Colors.grey,
              active: _filter == WorkOrderStatus.onHold,
              onTap: () => setState(() => _filter = WorkOrderStatus.onHold),
            ),
            _FilterChip(
              label: "Completed",
              color: Colors.green,
              active: _filter == WorkOrderStatus.completed,
              onTap: () => setState(() => _filter = WorkOrderStatus.completed),
            ),

          ],
        ),
      ),
    );
  }
}

class _WorkOrderTile extends StatelessWidget {
  const _WorkOrderTile({required this.wo});
  final WorkOrder wo;

  Color _statusColor(WorkOrderStatus s) {
    switch (s) {
      case WorkOrderStatus.accepted:   return Colors.blueAccent;
      case WorkOrderStatus.inProgress: return Colors.orange;
      case WorkOrderStatus.onHold:     return Colors.grey;
      case WorkOrderStatus.completed:  return Colors.green;
      case WorkOrderStatus.unassigned: return Colors.redAccent;
    }
  }

  String _statusText(WorkOrderStatus s) {
    switch (s) {
      case WorkOrderStatus.accepted:   return 'Accepted';
      case WorkOrderStatus.inProgress: return 'In Progress';
      case WorkOrderStatus.onHold:     return 'On Hold';
      case WorkOrderStatus.completed:  return 'Completed';
      case WorkOrderStatus.unassigned: return 'Unassigned';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store     = context.read<WorkOrderStore>();
    final mechStore = context.watch<MechanicStore>();
    final mechanic  = mechStore.byId(wo.assignedMechanicId);

    final bool isUnassigned =
        (wo.assignedMechanicId == null) ||
            (wo.assignedMechanicId!.trim().isEmpty) ||
            (mechanic == null) ||
            (mechanic.active == false);

    final dt = wo.scheduledStart;
    final timeLabel = dt == null
        ? '—'
        : '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    wo.title.isNotEmpty ? wo.title : wo.code,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: _statusColor(wo.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _statusText(wo.status),
                      style: TextStyle(color: _statusColor(wo.status)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Code: ${wo.code}'),
            Text('Schedule: $timeLabel'),
            Text('Mechanic: ${isUnassigned ? "-" : mechanic!.name}'),
            const SizedBox(height: 8),

            // buttons based on status (kept same as original)
            if (isUnassigned) ...[
              // Assign + Reschedule
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Assign'),
                      onPressed: () async {
                        final result = await showModalBottomSheet<AssignWorkOrderResult>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AssignWorkOrderSheet(
                            initialMechanicId: null,
                            initialStart: wo.scheduledStart,
                          ),
                        );
                        if (result != null) {
                          await store.assign(wo.workOrderId, result.mechanicId, result.start);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Assigned')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: const Text('Reschedule'),
                      onPressed: () async {
                        final now  = DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: wo.scheduledStart ?? now,
                          firstDate: now.subtract(const Duration(days: 1)),
                          lastDate:  now.add(const Duration(days: 365)),
                        );
                        if (date == null) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: (wo.scheduledStart ?? now).hour,
                            minute: (wo.scheduledStart ?? now).minute,
                          ),
                        );
                        if (time == null) return;
                        final newStart = DateTime(
                          date.year, date.month, date.day, time.hour, time.minute,
                        );
                        await store.reschedule(wo.workOrderId, newStart);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rescheduled')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],

            if (!isUnassigned && (wo.status == WorkOrderStatus.accepted || wo.status == WorkOrderStatus.onHold)) ...[
              // Reassign + Reschedule
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Reassign'),
                      onPressed: () async {
                        final result = await showModalBottomSheet<AssignWorkOrderResult>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AssignWorkOrderSheet(
                            initialMechanicId: wo.assignedMechanicId,
                            initialStart: wo.scheduledStart,
                          ),
                        );
                        if (result != null) {
                          await store.assign(wo.workOrderId, result.mechanicId, result.start);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reassigned')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: const Text('Reschedule'),
                      onPressed: () async {
                        final now  = DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: wo.scheduledStart ?? now,
                          firstDate: now.subtract(const Duration(days: 1)),
                          lastDate:  now.add(const Duration(days: 365)),
                        );
                        if (date == null) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: (wo.scheduledStart ?? now).hour,
                            minute: (wo.scheduledStart ?? now).minute,
                          ),
                        );
                        if (time == null) return;
                        final newStart = DateTime(
                          date.year, date.month, date.day, time.hour, time.minute,
                        );
                        await store.reschedule(wo.workOrderId, newStart);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rescheduled')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        selectedColor: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.2),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
