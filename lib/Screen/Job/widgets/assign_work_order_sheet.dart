import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/mechanic_store.dart'; // <-- store that fetches from staff

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
  final DateTime? initialStart;

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

    // prefill from current values if provided
    _mechanicId = widget.initialMechanicId;
    if (widget.initialStart != null) {
      _date = DateTime(widget.initialStart!.year, widget.initialStart!.month, widget.initialStart!.day);
      _time = TimeOfDay(hour: widget.initialStart!.hour, minute: widget.initialStart!.minute);
    }


    // If mechanics haven’t loaded yet, fetch them.
    // (This is safe even if they’re already loading/loaded.)
    Future.microtask(() {
      final store = context.read<MechanicStore>();
      if (store.mechanics.isEmpty && !store.loading) {
        store.fetch();
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final mechStore = context.watch<MechanicStore>();
    final mechanics = mechStore.mechanics;

    final canConfirm = _mechanicId != null && _date != null && _time != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Assign Work Order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // MECHANIC DROPDOWN
            if (mechStore.loading && mechanics.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (mechanics.isEmpty)
              Row(
                children: [
                  const Expanded(child: Text('No mechanics found.')),
                  IconButton(
                    onPressed: () => mechStore.fetch(),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reload',
                  ),
                ],
              )
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Mechanic'),
                value: _mechanicId,
                items: mechanics
                    .map((m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(m.name),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _mechanicId = v),
              ),

            const SizedBox(height: 12),

            // DATE + TIME
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDate,
                    child: Text(_date == null
                        ? 'Pick Date'
                        : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickTime,
                    child: Text(_time == null
                        ? 'Pick Time'
                        : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // CONFIRM
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canConfirm
                    ? () {
                  final dt = DateTime(
                    _date!.year,
                    _date!.month,
                    _date!.day,
                    _time!.hour,
                    _time!.minute,
                  );
                  Navigator.pop(
                    context,
                    AssignWorkOrderResult(
                      mechanicId: _mechanicId!,
                      start: dt,
                    ),
                  );
                }
                    : null,
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
