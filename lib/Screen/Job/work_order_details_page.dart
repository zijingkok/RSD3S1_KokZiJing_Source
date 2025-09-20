import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/work_order_store.dart';
import '../../state/mechanic_store.dart';
import '../../Models/work_order.dart';
import '../../Models/mechanic.dart';
import 'widgets/assign_work_order_sheet.dart'; // adjust path if needed

class WorkOrderDetailsPage extends StatefulWidget {
  const WorkOrderDetailsPage({super.key, required this.workOrder});
  final WorkOrder workOrder;

  @override
  State<WorkOrderDetailsPage> createState() => _WorkOrderDetailsPageState();
}

class _WorkOrderDetailsPageState extends State<WorkOrderDetailsPage> {
  late TextEditingController _notesCtrl;
  late WorkOrderStatus _statusLocal;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.workOrder.notes ?? '');
    _statusLocal = widget.workOrder.status;
    // ensure fresh data available soon
    Future.microtask(() => context.read<WorkOrderStore>().fetch());
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

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

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final woStore   = context.watch<WorkOrderStore>();
    final mechStore = context.watch<MechanicStore>();

    // show freshest version from store if present
    final wo = woStore.byId(widget.workOrder.workOrderId) ?? widget.workOrder;
    final mechanic = mechStore.byId(wo.assignedMechanicId);
    final isUnassigned = (wo.assignedMechanicId == null) ||
        (wo.assignedMechanicId!.trim().isEmpty) ||
        (mechanic == null) || (mechanic.active == false);

    return Scaffold(
      appBar: AppBar(
        title: Text(wo.title.isNotEmpty ? wo.title : wo.code),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
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
                  style: TextStyle(color: _statusColor(wo.status), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<WorkOrderStore>().fetch(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            _SectionCard(
              title: 'Basic',
              children: [
                _KV('Code', wo.code),
                _KV('Title', wo.title.isNotEmpty ? wo.title : '—'),
                _KV('Priority', wo.priority.name),
              ],
            ),
            _SectionCard(
              title: 'Schedule',
              children: [
                _KV('Scheduled Start', _fmtDateTime(wo.scheduledStart)),
                if (wo.estimatedHours != null)
                  _KV('Est. Hours', wo.estimatedHours!.toStringAsFixed(2)),
              ],
            ),
            _SectionCard(
              title: 'Assignment',
              children: [// Always show who’s assigned (or “-”)
                _KV('Mechanic', (mechStore.byId(wo.assignedMechanicId)?.name) ?? '-'),
                const SizedBox(height: 8),

// Buttons by STATUS (not by isUnassigned):
                if (wo.status == WorkOrderStatus.unassigned) ...[
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
                              await context.read<WorkOrderStore>()
                                  .assign(wo.workOrderId, result.mechanicId, result.start);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Assigned')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            final newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            await context.read<WorkOrderStore>().reschedule(wo.workOrderId, newStart);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Rescheduled')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ] else if (wo.status == WorkOrderStatus.accepted || wo.status == WorkOrderStatus.onHold) ...[
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
                              await context.read<WorkOrderStore>()
                                  .assign(wo.workOrderId, result.mechanicId, result.start);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reassigned')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            final newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            await context.read<WorkOrderStore>().reschedule(wo.workOrderId, newStart);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Rescheduled')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // In Progress / Completed → display only (no buttons)
                  const SizedBox.shrink(),
                ]

              ],
            ),
            _SectionCard(
              title: 'Status',
              children: [
                if (wo.status == WorkOrderStatus.completed)
                // Read-only chip when completed
                  InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Status',
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Completed', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else
                // Editable for non-completed
                  DropdownButtonFormField<WorkOrderStatus>(
                    value: _statusLocal,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: 'Status',
                    ),
                    items: WorkOrderStatus.values.map((s) {
                      final label = () {
                        switch (s) {
                          case WorkOrderStatus.accepted:   return 'Accepted';
                          case WorkOrderStatus.inProgress: return 'In Progress';
                          case WorkOrderStatus.onHold:     return 'On Hold';
                          case WorkOrderStatus.completed:  return 'Completed';
                          case WorkOrderStatus.unassigned: return 'Unassigned';
                        }
                      }();
                      return DropdownMenuItem(value: s, child: Text(label));
                    }).toList(),
                    onChanged: (s) async {
                      if (s == null) return;
                      setState(() => _statusLocal = s);
                      await context.read<WorkOrderStore>().setStatus(wo.workOrderId, s);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Status updated')),
                        );
                      }
                    },
                  ),
              ],
            ),
            _SectionCard(
              title: 'Notes',
              children: [
                TextFormField(
                  controller: _notesCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Add notes…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Notes'),
                    onPressed: () async {
                      await context.read<WorkOrderStore>().setNotes(wo.workOrderId, _notesCtrl.text.trim());
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes saved')));
                      }
                    },
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v, {super.key});
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(k, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
