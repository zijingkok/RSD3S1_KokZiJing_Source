import 'package:flutter/material.dart';
import 'crm_dashboard.dart' show Customer;

class CustomerHistoryPage extends StatefulWidget {
  final Customer customer;
  const CustomerHistoryPage({super.key, required this.customer});

  @override
  State<CustomerHistoryPage> createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends State<CustomerHistoryPage> {
  final List<Interaction> _items = [
    Interaction(
      dateTime: DateTime(2025, 7, 24, 15, 45),
      channel: 'WhatsApp',
      staff: 'Godlike',
      description:
      'Confirmed service appointment for 27 July at 10am. Customer asked for early slot.',
    ),
    Interaction(
      dateTime: DateTime(2025, 7, 24, 15, 45),
      channel: 'WhatsApp',
      staff: 'Godlike',
      description:
      'Confirmed service appointment for 27 July at 10am. Customer asked for early slot.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const panelRadius = 26.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.black87.withOpacity(.08),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Rounded white panel (exact page look)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(panelRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header row with avatar + name
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: widget.customer.avatarAsset != null
                                ? AssetImage(widget.customer.avatarAsset!)
                                : const AssetImage('assets/avatar_fallback.png'),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              widget.customer.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Communication history',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 6),

                    // List of interactions
                    for (int i = 0; i < _items.length; i++) ...[
                      _HistoryCard(
                        item: _items[i],
                        onEdit: () => _openEdit(i),
                        onDelete: () => _confirmDelete(i),
                      ),
                      if (i != _items.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(height: 28),
                        ),
                    ],

                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _logNewInteraction,
                          style: OutlinedButton.styleFrom(
                            side:
                            const BorderSide(color: Color(0xFF2E4A57), width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 18),
                            shadowColor: Colors.black.withOpacity(.2),
                            elevation: 0,
                            foregroundColor: const Color(0xFF2E4A57),
                          ),
                          child: const Text(
                            'Log New Interaction',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- Actions -----

  void _logNewInteraction() async {
    final created = await showModalBottomSheet<Interaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _InteractionEditor(
          title: 'Log New Interaction',
          initial: Interaction(
            dateTime: DateTime.now(),
            channel: 'Phone',
            staff: 'Godlike',
            description: '',
          ),
        ),
      ),
    );

    if (created != null) {
      setState(() => _items.insert(0, created));
    }
  }

  void _openEdit(int index) async {
    final updated = await showModalBottomSheet<Interaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _InteractionEditor(
          title: 'Edit Interaction',
          initial: _items[index],
        ),
      ),
    );

    if (updated != null) {
      setState(() => _items[index] = updated);
    }
  }

  void _confirmDelete(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete interaction?'),
        content:
        const Text('This action cannot be undone. Do you want to proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) setState(() => _items.removeAt(index));
  }
}

// ====== Widgets ======

class _HistoryCard extends StatelessWidget {
  final Interaction item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const labelStyle =
    TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.2);
    const valueStyle =
    TextStyle(fontSize: 16, color: Colors.black87, height: 1.3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatDate(item.dateTime),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 14),

          // 2 columns: channel & staff
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _twoLines(label: 'Communicate via', value: item.channel),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _twoLines(label: 'Staff', value: item.staff),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Description', style: labelStyle),
          const SizedBox(height: 6),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F4),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Text(
              '“${item.description}”',
              style: const TextStyle(fontSize: 16, height: 1.35),
            ),
          ),

          const SizedBox(height: 10),

          // edit + delete on right
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit, color: Colors.black87),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete, color: Color(0xFFD32F2F)),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _twoLines({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year},  $h.$m $ampm';
  }
}

// ====== Editor bottom sheet (BLACK & WHITE) ======

class _InteractionEditor extends StatefulWidget {
  final String title;
  final Interaction initial;
  const _InteractionEditor({required this.title, required this.initial});

  @override
  State<_InteractionEditor> createState() => _InteractionEditorState();
}

class _InteractionEditorState extends State<_InteractionEditor> {
  late TextEditingController _descCtrl;
  late TextEditingController _staffCtrl;
  String _channel = 'Phone';
  late DateTime _dt;

  @override
  void initState() {
    super.initState();
    _channel = widget.initial.channel;
    _dt = widget.initial.dateTime;
    _descCtrl = TextEditingController(text: widget.initial.description);
    _staffCtrl = TextEditingController(text: widget.initial.staff);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _staffCtrl.dispose();
    super.dispose();
  }

  // Common black/white inputs
  InputDecoration _bwInput({String? label}) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.black87),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black87, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black87, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black, width: 1.5),
    ),
  );

  ButtonStyle get _bwOutlined => OutlinedButton.styleFrom(
    foregroundColor: Colors.black,
    side: const BorderSide(color: Colors.black, width: 1.2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
  );

  ButtonStyle get _bwElevated => ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(vertical: 14),
    elevation: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title (black)
          Row(
            children: const [
              Icon(Icons.chat_bubble_outline, color: Colors.black87),
              SizedBox(width: 8),
              Text('Log / Edit Interaction',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),

          // Date/time + Channel
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: _bwOutlined,
                  onPressed: _pickDateTime,
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(_formatDate(_dt)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _channel,
                  isExpanded: true,
                  iconEnabledColor: Colors.black87,
                  iconDisabledColor: Colors.black45,
                  items: const [
                    DropdownMenuItem(value: 'Phone', child: Text('Phone')),
                    DropdownMenuItem(value: 'WhatsApp', child: Text('WhatsApp')),
                    DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                    DropdownMenuItem(value: 'Email', child: Text('Email')),
                    DropdownMenuItem(value: 'In-person', child: Text('In-person')),
                  ],
                  onChanged: (v) => setState(() => _channel = v ?? 'Phone'),
                  decoration: _bwInput(label: 'Communicate via'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Staff
          TextField(
            controller: _staffCtrl,
            decoration: _bwInput(label: 'Staff'),
          ),
          const SizedBox(height: 10),

          // Description
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: _bwInput(label: 'Description'),
          ),
          const SizedBox(height: 12),

          // Actions (Cancel black outline, Save black filled)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: _bwOutlined,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: _bwElevated,
                  onPressed: () {
                    if (_descCtrl.text.trim().isEmpty ||
                        _staffCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill staff and description'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
                      Interaction(
                        dateTime: _dt,
                        channel: _channel,
                        staff: _staffCtrl.text.trim(),
                        description: _descCtrl.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        // ensure black accent in the dialog too
        final theme = Theme.of(ctx);
        return Theme(
          data: theme.copyWith(
            datePickerTheme: const DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              headerForegroundColor: Colors.black,
              dayForegroundColor: MaterialStatePropertyAll(Colors.black),
              weekdayStyle: TextStyle(color: Colors.black87),
              // selected day background stays black
              dayOverlayColor: MaterialStatePropertyAll(Colors.black12),
              todayForegroundColor: MaterialStatePropertyAll(Colors.black),
              rangePickerHeaderForegroundColor: Colors.black,
            ),
            colorScheme: theme.colorScheme.copyWith(
              primary: Colors.black,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dt),
      builder: (ctx, child) {
        final theme = Theme.of(ctx);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: Colors.black,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (t == null) return;

    setState(() {
      _dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h.$m $ampm';
  }
}


// ====== model ======

class Interaction {
  final DateTime dateTime;
  final String channel;
  final String staff;
  final String description;

  Interaction({
    required this.dateTime,
    required this.channel,
    required this.staff,
    required this.description,
  });
}
