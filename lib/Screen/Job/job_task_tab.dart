import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/work_order_store.dart';
import '../../state/mechanic_store.dart';
import '../../Models/work_order.dart';
import 'widgets/assign_work_order_sheet.dart';
import 'work_order_details_page.dart';
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

  String _fmtDate(DateTime d) {
    final wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];
    final m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1];
    return '$wd, ${d.day} $m ${d.year}';
  }

  String _fmtTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Groups by calendar date (local), returns (dateKey -> sorted list)
  Map<DateTime?, List<WorkOrder>> _groupByDate(List<WorkOrder> input) {
    final map = <DateTime?, List<WorkOrder>>{};
    for (final wo in input) {
      final dt = wo.scheduledStart;
      final key = dt == null ? null : DateTime(dt.year, dt.month, dt.day);
      (map[key] ??= []).add(wo);
    }
    // sort each bucket by time
    for (final e in map.entries) {
      e.value.sort((a, b) {
        final da = a.scheduledStart;
        final db = b.scheduledStart;
        if (da == null && db == null) return 0;
        if (da == null) return 1; // nulls last inside a dated bucket (rare)
        if (db == null) return -1;
        return da.compareTo(db);
      });
    }
    return map;
  }



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
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.search, size: 18),
                    prefixIconConstraints: BoxConstraints(minWidth: 36, minHeight: 36),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                  width: 36, height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 28,
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
                    }, // your existing date picker method
                    tooltip: 'Filter date',
                  ),
              ),
              if (_selectedDate != null) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 36, height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 28,
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _selectedDate = null),
                    tooltip: 'Clear date',
                  ),
                ),
              ]
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
                : _AgendaList(items: filtered, tileBuilder: (wo) => _WorkOrderTile(wo: wo)),

    ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
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

class _AgendaList extends StatelessWidget {
  const _AgendaList({required this.items, required this.tileBuilder});
  final List<WorkOrder> items;
  final Widget Function(WorkOrder) tileBuilder;

  String _fmtDate(DateTime d) {
    final wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];
    final m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1];
    return '$wd, ${d.day} $m ${d.year}';
  }

  String _fmtTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: Text('No work orders for this filter.')),
        ],
      );
    }

    // group by date
    final buckets = <DateTime?, List<WorkOrder>>{};
    for (final wo in items) {
      final dt = wo.scheduledStart;
      final key = dt == null ? null : DateTime(dt.year, dt.month, dt.day);
      (buckets[key] ??= []).add(wo);
    }

    // sort days ascending; null (no schedule) at the end
    final keys = buckets.keys.toList()
      ..sort((a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });

    // sort items inside each day by time
    for (final k in keys) {
      final list = buckets[k]!;
      list.sort((a, b) {
        final da = a.scheduledStart;
        final db = b.scheduledStart;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    }

    // flatten into a single ListView with section headers
    final children = <Widget>[];
    for (final k in keys) {
      // header
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Row(
            children: [
              Icon(Icons.event, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                k == null ? 'No schedule' : _fmtDate(k),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      );

      // items
      for (final wo in buckets[k]!) {
        final t = wo.scheduledStart;
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // time column
                SizedBox(
                  width: 64,
                  child: Text(
                    t == null ? '— —' : _fmtTime(t),
                    style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                ),
                // card
                Expanded(child: tileBuilder(wo)),
              ],
            ),
          ),
        );
        children.add(const SizedBox(height: 8));
      }
    }

    // wrap in Refresh-friendly scroll
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
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

  String _fmtTime(DateTime? dt) {
    if (dt == null) return '—';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';

  }

  @override
  Widget build(BuildContext context) {
    final mechStore = context.watch<MechanicStore>();
    final mechanic  = mechStore.byId(wo.assignedMechanicId);

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        trailing: Row(
          mainAxisSize: MainAxisSize.min, //  keeps it tight
          children: [
            const Icon(Icons.arrow_forward_ios, size: 15)
          ],
        ),

        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WorkOrderDetailsPage(workOrder: wo)),
          );
        },

        //  Status dot on the LEFT
        leading: Container(
          width: 10, height: 10,
          margin: const EdgeInsets.only(top: 6), // align with title baseline
          decoration: BoxDecoration(color: _statusColor(wo.status), shape: BoxShape.circle),
        ),

        //  Title in the middle
        title: Text(
          wo.title.isNotEmpty ? wo.title : wo.code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        //  Schedule on the RIGHT (replaces status text)


        // Subtitle without schedule (to save space)
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code + Status on one compact row
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Code: ${wo.code}', style: const TextStyle(fontSize: 12)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('•  ', style: TextStyle(fontSize: 12)),
                      Text(
                        _statusText(wo.status),
                        style: TextStyle(
                          fontSize: 12,
                          color: _statusColor(wo.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text('Mechanic: ${mechanic?.name ?? '-'}', style: const TextStyle(fontSize: 12)),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 15)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        selected: active,
        selectedColor: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.15),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
