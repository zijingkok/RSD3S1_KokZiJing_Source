import 'package:flutter/material.dart';

import '../../Models/customer.dart';
import '../../models/interaction.dart';
import '../../services/interaction_service.dart';

class CustomerHistoryPage extends StatefulWidget {
  final Customer customer;
  const CustomerHistoryPage({super.key, required this.customer});

  @override
  State<CustomerHistoryPage> createState() => _CustomerHistoryPageState();
}

class _CustomerHistoryPageState extends State<CustomerHistoryPage> {
  bool _loading = true;
  String? _error;
  List<Interaction> _items = const [];

  // Date filter (inclusive)
  DateTimeRange? _range;

  String get _customerId => widget.customer.id;

  // Brand palette (UI only)
  static const _bg = Color(0xFFF5F7FA);
  static const _ink = Color(0xFF1D2A32);
  static const _muted = Color(0xFF6A7A88);
  static const _card = Colors.white;
  static const _primary = Color(0xFF1E88E5);
  static const _primaryDark = Color(0xFF1565C0);
  static const _stroke = Color(0xFFE6ECF1);

  @override
  void initState() {
    super.initState();
    _load();
  }

  ThemeData _localTheme(BuildContext context) {
    final base = Theme.of(context);
    final text = base.textTheme;
    final tunedText = text
        .copyWith(
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.3),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    )
        .apply(bodyColor: _ink, displayColor: _ink);

    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: _bg,
      textTheme: tunedText,
      colorScheme:
      base.colorScheme.copyWith(primary: _primary, secondary: _primary),
      dividerColor: _stroke,
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _ink,
        contentTextStyle: tunedText.bodyMedium?.copyWith(color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _bg,
        foregroundColor: _ink,
        titleTextStyle: tunedText.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
        centerTitle: false,
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await InteractionService.instance
          .listByCustomerWithStaff(_customerId);
      if (!mounted) return;
      setState(() {
        _items = rows
            .map((e) => Interaction.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ---------- Filtering ----------
  bool _inRange(DateTime d) {
    if (_range == null) return true;
    final start =
    DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
    final end = DateTime(_range!.end.year, _range!.end.month, _range!.end.day,
        23, 59, 59, 999);
    return (d.isAtSameMomentAs(start) ||
        d.isAtSameMomentAs(end) ||
        (d.isAfter(start) && d.isBefore(end)));
  }

  String _rangeLabel() {
    if (_range == null) return 'All time';
    String fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
    return '${fmt(_range!.start)} – ${fmt(_range!.end)}';
  }

  Future<void> _pickRange() async {
    // Open the custom, branded date-range sheet
    final res = await showModalBottomSheet<_RangeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DateRangeSheet(
        from: _range?.start,
        to: _range?.end,
        primary: _primary,
        primaryDark: _primaryDark,
        ink: _ink,
        stroke: _stroke,
        muted: _muted,
      ),
    );

    if (res == null) return;
    setState(() {
      if (res.from == null && res.to == null) {
        _range = null;
      } else {
        final from = res.from ?? res.to!;
        final to = res.to ?? res.from!;
        _range = DateTimeRange(start: from, end: to);
      }
    });
  }

  void _clearRange() => setState(() => _range = null);

  // ---------- Create / Edit ----------
  Future<void> _logNewInteraction() async {
    final created = await showModalBottomSheet<Interaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetShell(
        child: _InteractionEditor(
          title: 'Log New Interaction',
          initial: Interaction(
            id: '',
            customerId: widget.customer.id,
            staffId: null,
            channel: 'WhatsApp',
            description: '',
            interactionDate: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );

    if (created != null) {
      try {
        final savedMap =
        await InteractionService.instance.insertWithStaff(created);
        final saved = Interaction.fromJson(savedMap);
        if (!mounted) return;
        setState(() => _items.insert(0, saved));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interaction added successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _openEdit(int index) async {
    final updated = await showModalBottomSheet<Interaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetShell(
        child: _InteractionEditor(
          title: 'Edit Interaction',
          initial: _items[index],
        ),
      ),
    );

    if (updated != null) {
      try {
        final savedMap = await InteractionService.instance
            .updateWithStaff(_items[index].id, updated);
        final saved = Interaction.fromJson(savedMap);
        if (!mounted) return;
        setState(() => _items[index] = saved);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interaction updated successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const panelRadius = 22.0;

    final filtered = _items.where((i) => _inRange(i.interactionDate)).toList();

    return Theme(
      data: _localTheme(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.customer.fullName),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(panelRadius),
                border: Border.all(color: _stroke),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 22,
                      offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF90CAF9), Color(0xFF1E88E5)],
                            ),
                          ),
                          child:
                          const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.customer.fullName,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text('Communication history',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: _muted,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1),

                  // Filter row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FilterPill(
                            icon: Icons.filter_list,
                            label: _rangeLabel(),
                            onTap: _pickRange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_range != null)
                          _SmallActionPill(
                            icon: Icons.clear,
                            label: 'Clear',
                            onTap: _clearRange,
                          ),
                      ],
                    ),
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error: $_error',
                          style: const TextStyle(color: Colors.red)),
                    )
                  else if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 14),
                        itemBuilder: (_, i) => _HistoryCard(
                          item: filtered[i],
                          onEdit: () => _openEdit(
                              _items.indexOf(filtered[i])),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: _PrimaryButton.icon(
                            icon: Icons.add,
                            label: 'Log New Interaction',
                            onPressed: _logNewInteraction,
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- Reusable Bits ---------- */

class _PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  const _PrimaryButton(
      {super.key, required this.onPressed, required this.label})
      : icon = null;
  const _PrimaryButton.icon(
      {super.key, required this.onPressed, required this.label, required this.icon});

  static const _primary = _CustomerHistoryPageState._primary;
  static const _primaryDark = _CustomerHistoryPageState._primaryDark;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ],
    );

    return AnimatedScale(
      scale: onPressed == null ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [_primary, _primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 6))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FilterPill(
      {required this.icon, required this.label, required this.onTap});

  static const _stroke = _CustomerHistoryPageState._stroke;
  static const _ink = _CustomerHistoryPageState._ink;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(side: BorderSide(color: _stroke)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: _ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallActionPill(
      {required this.icon, required this.label, required this.onTap});

  static const _ink = _CustomerHistoryPageState._ink;
  static const _stroke = _CustomerHistoryPageState._stroke;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FB),
      shape: const StadiumBorder(side: BorderSide(color: _stroke)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: _ink),
              const SizedBox(width: 6),
              Text(label,
                  style:
                  const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- Cards (bigger + time on next row) ---------- */

class _HistoryCard extends StatelessWidget {
  final Interaction item;
  final VoidCallback onEdit;
  const _HistoryCard({required this.item, required this.onEdit});

  static const _ink = _CustomerHistoryPageState._ink;
  static const _muted = _CustomerHistoryPageState._muted;
  static const _stroke = _CustomerHistoryPageState._stroke;

  String _staffName(Interaction i) {
    final n = i.staff?.fullName ?? '';
    return n.trim().isEmpty ? 'Unassigned' : n;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _stroke),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date/time stacked + channel + edit
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date + time stacked (no truncation)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateOnly(item.interactionDate),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeOnly(item.interactionDate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _muted,
                        height: 1.2,
                        letterSpacing: .2,
                      ),
                    ),
                  ],
                ),
              ),
              _Chip(text: item.channel),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Edit',
                style: IconButton.styleFrom(padding: const EdgeInsets.all(6)),
                icon: const Icon(Icons.edit_outlined, color: _ink),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text('Description',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                  height: 1.2,
                  letterSpacing: .2)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Text(
              '“${item.description}”',
              style: const TextStyle(fontSize: 15.5, height: 1.45),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 18, color: _muted),
              const SizedBox(width: 6),
              Text('Staff: ',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _muted)),
              Expanded(
                child: Text(
                  _staffName(item),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateOnly(DateTime dt) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _timeOnly(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '$h:$m $ampm';
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1565C0),
          letterSpacing: .2,
        ),
      ),
    );
  }
}

/* ---------- Editor (validation + staff) ---------- */

class _InteractionEditor extends StatefulWidget {
  final String title;
  final Interaction initial;
  const _InteractionEditor({required this.title, required this.initial});

  @override
  State<_InteractionEditor> createState() => _InteractionEditorState();
}

class _InteractionEditorState extends State<_InteractionEditor> {
  // Form + validation
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  String? _dateError;

  // Fields
  late TextEditingController _descCtrl;
  late DateTime _dt;
  String? _channel = 'WhatsApp';

  // Staff picker state
  List<Map<String, String>> _staffOpts = const [];
  String? _staffId; // null = Unassigned
  bool _staffLoading = true;

  static const _ink = _CustomerHistoryPageState._ink;
  static const _muted = _CustomerHistoryPageState._muted;
  static const _stroke = _CustomerHistoryPageState._stroke;
  static const _primary = _CustomerHistoryPageState._primary;
  static const _primaryDark = _CustomerHistoryPageState._primaryDark;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.initial.description);
    _dt = widget.initial.interactionDate;
    _channel = widget.initial.channel;
    _staffId = widget.initial.staffId;

    () async {
      try {
        final opts = await InteractionService.instance.fetchStaffOptions();
        if (!mounted) return;
        setState(() {
          _staffOpts = opts;
          _staffLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _staffLoading = false);
      }
    }();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  InputDecoration _bwInput(String label) => InputDecoration(
    labelText: label,
    labelStyle:
    const TextStyle(color: _ink, fontWeight: FontWeight.w600),
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _stroke, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _stroke, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primary, width: 1.5),
    ),
  );

  Widget _staffField() {
    if (_staffLoading) {
      return InputDecorator(
        decoration: _bwInput('Staff-in-charge'),
        child: const Text('Loading staff...'),
      );
    }

    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
      ..._staffOpts.map(
            (e) => DropdownMenuItem<String?>(
          value: e['staff_id'],
          child: Text(e['full_name'] ?? ''),
        ),
      ),
    ];

    return DropdownButtonFormField<String?>(
      value: _staffId,
      isExpanded: true,
      items: items,
      onChanged: (v) => setState(() => _staffId = v),
      decoration: _bwInput('Staff-in-charge'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.86;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(height: 12),

          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [_primary, _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),

          // Content scroll
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: LayoutBuilder(
                  builder: (context, cts) {
                    final isWide = cts.maxWidth >= 480;
                    final dateCard = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DateFieldCard(dateTime: _dt, onTap: _pickDateTime),
                        if (_dateError != null)
                          Padding(
                            padding:
                            const EdgeInsets.only(top: 6, left: 6),
                            child: Text(_dateError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12.5)),
                          ),
                      ],
                    );

                    final channelField = DropdownButtonFormField<String>(
                      value: _channel,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                            value: 'WhatsApp', child: Text('WhatsApp')),
                        DropdownMenuItem(value: 'Call', child: Text('Call')),
                        DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                        DropdownMenuItem(
                            value: 'Email', child: Text('Email')),
                        DropdownMenuItem(
                            value: 'In-person', child: Text('In-person')),
                      ],
                      onChanged: (v) => setState(() => _channel = v),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Please select channel'
                          : null,
                      decoration: _bwInput('Communicate via'),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isWide)
                          Row(children: [
                            Expanded(child: dateCard),
                            const SizedBox(width: 10),
                            Expanded(child: channelField),
                          ])
                        else ...[
                          dateCard,
                          const SizedBox(height: 10),
                          channelField,
                        ],
                        const SizedBox(height: 12),
                        _staffField(),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descCtrl,
                          minLines: 5,
                          maxLines: 10,
                          decoration: _bwInput('Description'),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return 'Please enter description';
                            if (s.length < 3) {
                              return 'Description is too short';
                            }
                            return null;
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // Sticky actions
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              children: [
                Expanded(
                    child: _SoftButton(
                        label: 'Cancel',
                        onTap: () => Navigator.pop(context))),
                const SizedBox(width: 10),
                Expanded(
                    child:
                    _PrimaryButton(onPressed: _onSave, label: 'Save')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final d = await showDatePicker(
      context: context,
      initialDate: _dt.isAfter(now) ? today : _dt,
      firstDate: DateTime(2000),
      lastDate: today,
      builder: (ctx, child) {
        final theme = Theme.of(ctx);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme
                .copyWith(primary: _primary, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dt.isAfter(now) ? now : _dt),
      builder: (ctx, child) {
        final theme = Theme.of(ctx);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme
                .copyWith(primary: _primary, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (t == null) return;

    final picked = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() {
      if (picked.isAfter(DateTime.now())) {
        _dateError = 'Interaction time cannot be in the future';
        _dt = now;
      } else {
        _dateError = null;
        _dt = picked;
      }
    });
  }

  void _onSave() {
    setState(() => _submitted = true);

    final now = DateTime.now();
    if (_dt.isAfter(now)) {
      _dateError = 'Interaction time cannot be in the future';
    } else {
      _dateError = null;
    }

    if (!(_formKey.currentState?.validate() ?? false) ||
        _dateError != null) {
      return;
    }

    final desc = _descCtrl.text.trim();

    Navigator.pop(
      context,
      Interaction(
        id: widget.initial.id,
        customerId: widget.initial.customerId,
        staffId: _staffId,
        channel: _channel ?? 'WhatsApp',
        description: desc,
        interactionDate: _dt,
        createdAt: widget.initial.createdAt,
      ),
    );
  }
}

/* ---------- Date card ---------- */

class _DateFieldCard extends StatelessWidget {
  final DateTime dateTime;
  final VoidCallback onTap;
  const _DateFieldCard({required this.dateTime, required this.onTap});

  static const _ink = _CustomerHistoryPageState._ink;
  static const _stroke = _CustomerHistoryPageState._stroke;
  static const _primary = _CustomerHistoryPageState._primary;

  String _formatLong(DateTime dt) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  •  $h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _stroke),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBDEFB)),
                ),
                child:
                const Icon(Icons.event, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date & time',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    const SizedBox(height: 2),
                    Text(_formatLong(dateTime),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    const Text('Tap to change',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: _ink),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- Soft button ---------- */

class _SoftButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SoftButton({required this.label, required this.onTap});

  static const _ink = _CustomerHistoryPageState._ink;
  static const _stroke = _CustomerHistoryPageState._stroke;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FB),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _stroke),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'Cancel',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- Bottom sheet container (UI-only) ---------- */

class _BottomSheetShell extends StatelessWidget {
  final Widget child;
  const _BottomSheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Container(
      color: Colors.transparent, // keep the backdrop from turning white
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: h * 0.90),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          elevation: 8,
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}

/* ---------- Custom Date Range Sheet ---------- */

class _RangeResult {
  final DateTime? from;
  final DateTime? to;
  const _RangeResult(this.from, this.to);
}

class _DateRangeSheet extends StatefulWidget {
  final DateTime? from;
  final DateTime? to;
  final Color primary, primaryDark, ink, stroke, muted;

  const _DateRangeSheet({
    required this.from,
    required this.to,
    required this.primary,
    required this.primaryDark,
    required this.ink,
    required this.stroke,
    required this.muted,
  });

  @override
  State<_DateRangeSheet> createState() => _DateRangeSheetState();
}

class _DateRangeSheetState extends State<_DateRangeSheet> {
  late DateTime? _from = widget.from;
  late DateTime? _to = widget.to;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * .9;

    return Container(
      alignment: Alignment.bottomCenter,
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [widget.primary, widget.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.filter_list,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Filter by date',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Quick ranges',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: widget.muted)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip('All time', onTap: () {
                              setState(() {
                                _from = null;
                                _to = null;
                              });
                            }),
                            _chip('Last 7 days', onTap: () {
                              final now = DateTime.now();
                              setState(() {
                                _to =
                                    DateTime(now.year, now.month, now.day);
                                _from = _to!.subtract(
                                    const Duration(days: 6));
                              });
                            }),
                            _chip('This month', onTap: () {
                              final now = DateTime.now();
                              setState(() {
                                _from = DateTime(now.year, now.month, 1);
                                _to = DateTime(now.year, now.month + 1, 0);
                              });
                            }),
                            _chip('Last month', onTap: () {
                              final now = DateTime.now();
                              final first =
                              DateTime(now.year, now.month - 1, 1);
                              final last = DateTime(now.year, now.month, 0);
                              setState(() {
                                _from = first;
                                _to = last;
                              });
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _dateCard(
                          label: 'From',
                          date: _from,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _from ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (ctx, child) {
                                final t = Theme.of(ctx);
                                return Theme(
                                  data: t.copyWith(
                                    colorScheme: t.colorScheme.copyWith(
                                        primary: widget.primary,
                                        onPrimary: Colors.white),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) setState(() => _from = picked);
                          },
                        ),
                        const SizedBox(height: 10),
                        _dateCard(
                          label: 'To',
                          date: _to,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _to ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (ctx, child) {
                                final t = Theme.of(ctx);
                                return Theme(
                                  data: t.copyWith(
                                    colorScheme: t.colorScheme.copyWith(
                                        primary: widget.primary,
                                        onPrimary: Colors.white),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) setState(() => _to = picked);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: _softButton(
                          label: 'Clear',
                          ink: widget.ink,
                          stroke: widget.stroke,
                          onTap: () => Navigator.pop(
                              context, const _RangeResult(null, null)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _primaryButton(
                          label: 'Apply',
                          primary: widget.primary,
                          primaryDark: widget.primaryDark,
                          onTap: () => Navigator.pop(
                              context, _RangeResult(_from, _to)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helpers for the sheet

  Widget _chip(String text, {required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFFF7F9FB),
      shape: StadiumBorder(side: BorderSide(color: widget.stroke)),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(text,
              style:
              const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _dateCard({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    String pretty(DateTime d) {
      const months = [
        'January','February','March','April','May','June',
        'July','August','September','October','November','December'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: widget.stroke),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Icon(Icons.event, color: widget.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.muted)),
                    const SizedBox(height: 2),
                    Text(
                      date == null ? '—' : pretty(date),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _softButton({
    required String label,
    required Color ink,
    required Color stroke,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF7F9FB),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: stroke),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(label,
                style:
                TextStyle(color: ink, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
    required Color primary,
    required Color primaryDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: [primary, primaryDark]),
        boxShadow: const [
          BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 6))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('Apply',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}
