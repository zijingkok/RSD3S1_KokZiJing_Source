import 'package:flutter/material.dart';

class InventoryRequestScreen extends StatefulWidget {
  const InventoryRequestScreen({super.key});

  @override
  State<InventoryRequestScreen> createState() => _InventoryRequestScreenState();
}

enum ReqPriority { low, medium, high }

class _InventoryRequestScreenState extends State<InventoryRequestScreen> {
  final _codeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  //Database intergration------------------------------------------------------------
  final List<String> _parts = const [
    'Brake Pads - Front',
    'Air Filter',
    'Engine Oil 5W-30 (4L)',
    'Spark Plug',
  ];

  //Database intergration------------------------------------------------------------

  String? _selectedPart = 'Brake Pads - Front';
  int _qty = 1;
  ReqPriority _priority = ReqPriority.medium;


  //Database intergration------------------------------------------------------------
  @override
  void dispose() {
    _codeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(width: 1, color: Color(0xFFB5B5B5));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16, 16, 16, 16 + kBottomNavigationBarHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inline back + title (since your shell has its own AppBar with logo)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 4),
              const Text(
                'New Request',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),


          //Database intergration------------------------------------------------------------
          const Text('Select Part',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedPart,
            items: _parts
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() => _selectedPart = v),
            decoration: InputDecoration(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
            ),
          ),

          //Database intergration------------------------------------------------------------
          const SizedBox(height: 12),

          TextField(
            controller: _codeCtrl,
            decoration: InputDecoration(
              hintText: 'Enter Code',
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Quantity Needed',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            children: [
              _SquareIconButton(
                icon: Icons.remove,
                onTap: () => setState(() {
                  if (_qty > 1) _qty--;
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border.color, width: 1),
                    color: Colors.white,
                  ),
                  child: Text(
                    '$_qty',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _SquareIconButton(
                icon: Icons.add,
                onTap: () => setState(() => _qty++),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Priority Level',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PriorityPill(
                  label: 'Low',
                  selected: _priority == ReqPriority.low,
                  onTap: () => setState(() => _priority = ReqPriority.low),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PriorityPill(
                  label: 'Medium',
                  selected: _priority == ReqPriority.medium,
                  onTap: () => setState(() => _priority = ReqPriority.medium),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PriorityPill(
                  label: 'High',
                  selected: _priority == ReqPriority.high,
                  onTap: () => setState(() => _priority = ReqPriority.high),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Notes/Justification',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesCtrl,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Provide details about why this part is needed....',
              alignLabelWithHint: true,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: border,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Summary card
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              side: border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Summary',
                      style:
                      TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _kv('Part:', _selectedPart ?? 'Not selected'),
                  const SizedBox(height: 6),
                  _kv('Quantity:', '$_qty'),
                  const SizedBox(height: 6),
                  _kv('Priority:', _priorityLabel(_priority)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Submit / Cancel
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: handle submit
                // ScaffoldMessenger.of(context).showSnackBar(
                //   const SnackBar(content: Text('Request submitted')),
                // );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Submit Request',
                  style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: Color(0xFFB5B5B5)),
                foregroundColor: Colors.black87,
              ),
              child: const Text('Cancel',
                  style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  static String _priorityLabel(ReqPriority p) {
    switch (p) {
      case ReqPriority.low:
        return 'Low';
      case ReqPriority.medium:
        return 'Medium';
      case ReqPriority.high:
        return 'High';
    }
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        SizedBox(
          width: 90,
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

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFB5B5B5), width: 1),
        ),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PriorityPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.white : const Color(0xFFF3F4F6);
    final dotColor = selected ? Colors.black87 : const Color(0xFFBDBDBD);
    final border = selected ? Colors.black87 : const Color(0xFFB5B5B5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 10, color: dotColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
