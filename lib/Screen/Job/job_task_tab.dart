import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/work_order_store.dart';
import '../../state/mechanic_store.dart';
import '../../Models/work_order.dart';
import 'work_order_details_page.dart';
import '../../Models/mechanic.dart';

class JobTaskTab extends StatefulWidget {
  const JobTaskTab({super.key});

  @override
  State<JobTaskTab> createState() => _JobTaskTabState();
}

enum TimeRange { all, today, next7, thisWeek, thisMonth, customRange }

/// Coerce various backend shapes into DateTime:
/// - DateTime -> itself
/// - int (epoch micros/millis/secs heuristic) -> DateTime
/// - String (ISO-8601) -> DateTime.tryParse
DateTime? _asDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) {
    final parsed = DateTime.tryParse(v);
    if (parsed != null) return parsed;
  }
  if (v is int) {
    final n = v;
    if (n > 9_000_000_000_000_000) { // > ~285 years in micros: already micros
      return DateTime.fromMicrosecondsSinceEpoch(n);
    } else if (n > 9_000_000_000_000) { // > ~285 years in millis: treat as millis
      return DateTime.fromMillisecondsSinceEpoch(n);
    } else if (n > 9_000_000_000) { // > year 2286 in secs: unlikely but handle
      return DateTime.fromMillisecondsSinceEpoch(n);
    } else if (n > 1_000_000_000) { // epoch seconds (common)
      return DateTime.fromMillisecondsSinceEpoch(n * 1000);
    } else {
      // very small ints aren’t valid epochs; ignore
      return null;
    }
  }
  return null;
}

class _JobTaskTabState extends State<JobTaskTab> {
  WorkOrderStatus? _filter; // null = all
  final TextEditingController _searchController = TextEditingController();

  // Time window
  TimeRange _range = TimeRange.all;
  DateTimeRange? _selectedRange; // used only when _range == customRange

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

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _atStartOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _atEndOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  ({DateTime? start, DateTime? end}) _currentBounds() {
    final now = DateTime.now();
    switch (_range) {
      case TimeRange.all:
        return (start: null, end: null);
      case TimeRange.today:
        final s = _atStartOfDay(now);
        return (start: s, end: _atEndOfDay(s));
      case TimeRange.next7:
        final s = _atStartOfDay(now);
        final e = _atEndOfDay(s.add(const Duration(days: 6)));
        return (start: s, end: e);
      case TimeRange.thisWeek:
        final weekday = now.weekday; // 1=Mon..7=Sun
        final monday = _atStartOfDay(now.subtract(Duration(days: weekday - 1)));
        final sunday = _atEndOfDay(monday.add(const Duration(days: 6)));
        return (start: monday, end: sunday);
      case TimeRange.thisMonth:
        final first = DateTime(now.year, now.month, 1);
        final last = DateTime(now.year, now.month + 1, 0);
        return (start: _atStartOfDay(first), end: _atEndOfDay(last));
      case TimeRange.customRange:
        if (_selectedRange == null) return (start: null, end: null);
        final s = _atStartOfDay(_selectedRange!.start);
        final e = _atEndOfDay(_selectedRange!.end);
        return (start: s, end: e);
    }
  }

  /// status + search + mechanic + time-window filter
  List<WorkOrder> _applyFilter(List<WorkOrder> items) {
    var result = items;

    // status
    if (_filter != null) {
      result = result.where((wo) => wo.status == _filter).toList();
    }

    // search (title | code | mechanic)
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      final mechStore = context.read<MechanicStore>();
      result = result.where((wo) {
        final mechanic = mechStore.byId(wo.assignedMechanicId);
        final mechName = mechanic?.name.toLowerCase() ?? "";
        return (wo.title.toLowerCase().contains(query)) ||
            (wo.code.toLowerCase().contains(query))  ||
            (mechName.contains(query));
      }).toList();
    }

    // time window (using coerced DateTime)
    final bounds = _currentBounds();
    if (bounds.start != null && bounds.end != null) {
      result = result.where((wo) {
        final dt = _asDateTime((wo as dynamic).scheduledStart);
        if (dt == null) return false;
        return !dt.isBefore(bounds.start!) && !dt.isAfter(bounds.end!);
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
        // Search + time window popup
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search by title, code, mechanic…',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.search, size: 18),
                    prefixIconConstraints: BoxConstraints(minWidth: 36, minHeight: 36),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 36, height: 36,
                child: PopupMenuButton<String>(
                  tooltip: 'Time window',
                  iconSize: 24,
                  icon: const Icon(Icons.date_range),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'all',      child: Text('All')),
                    PopupMenuItem(value: 'today',    child: Text('Today')),
                    PopupMenuItem(value: 'next7',    child: Text('Next 7 days')),
                    PopupMenuItem(value: 'thisWeek', child: Text('This week')),
                    PopupMenuItem(value: 'thisMonth',child: Text('This month')),
                    PopupMenuItem(value: 'pick',     child: Text('Pick a range…')),
                  ],
                  onSelected: (v) async {
                    switch (v) {
                      case 'all':
                        setState(() { _range = TimeRange.all; _selectedRange = null; });
                        break;
                      case 'today':
                        setState(() { _range = TimeRange.today; _selectedRange = null; });
                        break;
                      case 'next7':
                        setState(() { _range = TimeRange.next7; _selectedRange = null; });
                        break;
                      case 'thisWeek':
                        setState(() { _range = TimeRange.thisWeek; _selectedRange = null; });
                        break;
                      case 'thisMonth':
                        setState(() { _range = TimeRange.thisMonth; _selectedRange = null; });
                        break;
                      case 'pick':
                        final now = DateTime.now();
                        final initialStart = _selectedRange?.start ?? now;
                        final initialEnd   = _selectedRange?.end   ?? now.add(const Duration(days: 6));
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
                        );
                        if (picked != null) {
                          setState(() { _range = TimeRange.customRange; _selectedRange = picked; });
                        }
                        break;
                    }
                  },
                ),
              ),
              if (_range == TimeRange.customRange && _selectedRange != null) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 36, height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 24,
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() { _range = TimeRange.all; _selectedRange = null; }),
                    tooltip: 'Clear range',
                  ),
                ),
              ],
            ],
          ),
        ),

        _buildFilterBar(),

        // Active range chip (clearable)
        if (_range != TimeRange.all)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Wrap(
              spacing: 6, runSpacing: 4,
              children: [
                InputChip(
                  label: Text(
                    _range == TimeRange.customRange && _selectedRange != null
                        ? '${_ymd(_selectedRange!.start)} → ${_ymd(_selectedRange!.end)}'
                        : ({
                      TimeRange.today:    'Today',
                      TimeRange.next7:    'Next 7 days',
                      TimeRange.thisWeek: 'This week',
                      TimeRange.thisMonth:'This month',
                    }[_range] ?? 'All'),
                  ),
                  onDeleted: () => setState(() { _range = TimeRange.all; _selectedRange = null; }),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),



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
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
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
              label: "Scheduled",
              color: Colors.blueAccent,
              active: _filter == WorkOrderStatus.scheduled,
              onTap: () => setState(() => _filter = WorkOrderStatus.scheduled),
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

    // group by date using coerced DateTime
    final buckets = <DateTime?, List<WorkOrder>>{};
    for (final wo in items) {
      final dt = _asDateTime((wo as dynamic).scheduledStart);
      final key = dt == null ? null : DateTime(dt.year, dt.month, dt.day);
      (buckets[key] ??= []).add(wo);
    }

    final keys = buckets.keys.toList()
      ..sort((a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });

    for (final k in keys) {
      final list = buckets[k]!;
      list.sort((a, b) {
        final da = _asDateTime((a as dynamic).scheduledStart);
        final db = _asDateTime((b as dynamic).scheduledStart);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    }

    final children = <Widget>[];
    for (final k in keys) {
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

      for (final wo in buckets[k]!) {
        final t = _asDateTime((wo as dynamic).scheduledStart);
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    t == null ? '— —' : _fmtTime(t),
                    style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                ),
                Expanded(child: tileBuilder(wo)),
              ],
            ),
          ),
        );
        children.add(const SizedBox(height: 8));
      }
    }

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
      case WorkOrderStatus.scheduled:   return Colors.blueAccent;
      case WorkOrderStatus.inProgress: return Colors.orange;
      case WorkOrderStatus.onHold:     return Colors.grey;
      case WorkOrderStatus.completed:  return Colors.green;
      case WorkOrderStatus.unassigned: return Colors.redAccent;
    }
  }

  String _statusText(WorkOrderStatus s) {
    switch (s) {
      case WorkOrderStatus.scheduled:   return 'Scheduled';
      case WorkOrderStatus.inProgress: return 'In Progress';
      case WorkOrderStatus.onHold:     return 'On Hold';
      case WorkOrderStatus.completed:  return 'Completed';
      case WorkOrderStatus.unassigned: return 'Unassigned';
    }
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WorkOrderDetailsPage(workOrder: wo)),
          );
        },
        leading: Container(
          width: 10, height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: _statusColor(wo.status), shape: BoxShape.circle),
        ),
        title: Text(
          wo.title.isNotEmpty ? wo.title : wo.code,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
