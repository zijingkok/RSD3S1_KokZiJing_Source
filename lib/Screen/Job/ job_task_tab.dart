import 'package:flutter/material.dart';

class JobTaskTab extends StatefulWidget {
  const JobTaskTab({super.key});

  @override
  State<JobTaskTab> createState() => _JobTaskTabState();
}

class _JobTaskTabState extends State<JobTaskTab> {
  // Mock data for MVP — replace with your real models / Supabase later
  final List<Map<String, dynamic>> jobs = [
    {'id':'WO-1024','vehicle':'Honda City','time':'10:30 AM','status':'Unassigned','mechanic':null},
    {'id':'WO-1019','vehicle':'Perodua X70','time':'12:00 PM','status':'In Progress','mechanic':'Ali'},
    {'id':'WO-1016','vehicle':'Honda City','time':'—','status':'Completed','mechanic':'Siti'},
  ];
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = jobs.where((j) => filter=='All' ? true : j['status']==filter).toList();
    return Column(
      children: [
        // Filters row
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: ['All','Unassigned','In Progress','Completed'].map((s){
              final selected = filter==s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected,
                  label: Text(s),
                  onSelected: (_){ setState(()=>filter=s); },
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final j = filtered[i];
              final color = switch (j['status'] as String) {
                'Unassigned' => Colors.red,
                'In Progress' => Colors.orange,
                'Completed' => Colors.green,
                _ => Colors.grey,
              };
              return Card(
                child: ListTile(
                  leading: Icon(Icons.circle, size: 12, color: color),
                  title: Text('${j['id']}  •  ${j['vehicle']}'),
                  subtitle: Text('Time: ${j['time']}   •   Mechanic: ${j['mechanic'] ?? '—'}'),
                  trailing: _trailingForStatus(j),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _trailingForStatus(Map<String, dynamic> j) {
    final status = j['status'] as String;
    if (status == 'Unassigned') {
      return ElevatedButton(
        onPressed: () async {
          final result = await showModalBottomSheet<Map<String,String>>(
            context: context,
            isScrollControlled: true,
            builder: (_) => _AssignSheet(jobId: j['id']),
          );
          if (result != null) {
            setState(() {
              j['status'] = 'In Progress';
              j['mechanic'] = result['mechanic'];
              j['time']     = result['time'];
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Assigned ${j['id']} to ${j['mechanic']}')),
            );
          }
        },
        child: const Text('Assign'),
      );
    }
    return const Icon(Icons.chevron_right);
  }
}

// Simple bottom sheet for MVP assignment
class _AssignSheet extends StatefulWidget {
  final String jobId;
  const _AssignSheet({required this.jobId});

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  String? mechanic;
  TimeOfDay? time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Assign ${widget.jobId}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Mechanic'),
            items: const ['Ali','Siti','John'].map((m)=>DropdownMenuItem(value:m, child: Text(m))).toList(),
            onChanged: (v)=> setState(()=> mechanic=v),
          ),
          const SizedBox(height: 8),
          TextFormField(
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Time'),
            controller: TextEditingController(text: time==null ? '' : time!.format(context)),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (t!=null) setState(()=> time=t);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (mechanic!=null && time!=null)
                  ? ()=> Navigator.pop(context, {'mechanic': mechanic!, 'time': time!.format(context)})
                  : null,
              child: const Text('Confirm'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
