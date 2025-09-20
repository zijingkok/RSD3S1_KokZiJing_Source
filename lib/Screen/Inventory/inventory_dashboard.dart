import 'package:flutter/material.dart';

import '../../Models/inventory_summary.dart';
import '../../services/inventory_service.dart';

class InventoryDashboard extends StatefulWidget {
  const InventoryDashboard({super.key});

  @override
  State<InventoryDashboard> createState() => _InventoryDashboardState();
}

class _InventoryDashboardState extends State<InventoryDashboard> {
  late final InventoryService _service;
  late final Stream<InventorySummary> _summaryStream;

  // Brand palette (UI only – same as other screens)
  static const _bg = Color(0xFFF5F7FA);
  static const _ink = Color(0xFF1D2A32);
  static const _muted = Color(0xFF6A7A88);
  static const _card = Colors.white;
  static const _stroke = Color(0xFFE6ECF1);
  static const _primary = Color(0xFF1E88E5);
  static const _primaryDark = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _service = InventoryService();
    _summaryStream = _service.streamInventorySummary();
  }

  ThemeData _localTheme(BuildContext context) {
    final base = Theme.of(context);
    final tuned = base.textTheme
        .copyWith(
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.3),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    )
        .apply(bodyColor: _ink, displayColor: _ink);
    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: _bg,
      textTheme: tuned,
      colorScheme: base.colorScheme.copyWith(primary: _primary, secondary: _primary),
      dividerColor: _stroke,
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        contentTextStyle: tuned.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _localTheme(context),
      child: StreamBuilder<InventorySummary>(
        stream: _summaryStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data available.'));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + kBottomNavigationBarHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card (consistent with CRM header panel)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _stroke),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 10)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
                        child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Inventory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text('Realtime stock & procurement',
                                style: TextStyle(fontSize: 14, color: _muted, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Overview cards in a grid-like flow
                _OverviewGrid(
                  children: [
                    _OverviewTile(
                      icon: Icons.maps_home_work_outlined,
                      title: 'Total Stocked Parts',
                      value: data.totalStockedParts.toString(),
                      hint: 'Across all locations',
                    ),
                    _OverviewTile(
                      icon: Icons.warning_amber_outlined,
                      title: 'Low Stock Alerts',
                      value: data.lowStockAlerts.toString(),
                      hint: 'Needs attention',
                    ),
                    _OverviewTile(
                      icon: Icons.pending_actions_outlined,
                      title: 'Pending Procurement',
                      value: data.pendingProcurement.toString(),
                      hint: 'Awaiting approval',
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),

                // Action rows
                _ActionRow(
                  icon: Icons.view_list_outlined,
                  title: 'View Inventory List',
                  subtitle: 'Browse all parts and stock levels',
                  onTap: () => Navigator.of(context).pushNamed('/list'),
                ),
                const SizedBox(height: 10),
                _ActionRow(
                  icon: Icons.playlist_add_outlined,
                  title: 'Request Stock',
                  subtitle: 'Add on spare parts',
                  onTap: () => Navigator.of(context).pushNamed('/request'),
                ),
                const SizedBox(height: 10),
                _ActionRow(
                  icon: Icons.fact_check_outlined,
                  title: 'Pending Procurement',
                  subtitle: 'Check request status',
                  onTap: () => Navigator.of(context).pushNamed('/status'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ---------- Overview grid + tiles (same card style) ---------- */

class _OverviewGrid extends StatelessWidget {
  final List<Widget> children;
  const _OverviewGrid({required this.children});

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    // Simple responsive 1–2 column flow
    final w = MediaQuery.of(context).size.width;
    final isTwoCol = w >= 680;

    if (isTwoCol) {
      return Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: children
            .map((c) => SizedBox(
          width: (w - 16 * 2 - _gap) / 2, // padding*2 + spacing
          child: c,
        ))
            .toList(),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          children[i],
        ],
      ],
    );
  }
}

class _OverviewTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String hint;

  static const _card = _InventoryDashboardState._card;
  static const _stroke = _InventoryDashboardState._stroke;
  static const _ink = _InventoryDashboardState._ink;
  static const _muted = _InventoryDashboardState._muted;

  const _OverviewTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _stroke),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _stroke),
            ),
            child: Icon(icon, color: _ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 2),
                Text(hint, style: const TextStyle(fontSize: 12.5, color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- Action rows (consistent look & ripple) ---------- */

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const _card = _InventoryDashboardState._card;
  static const _stroke = _InventoryDashboardState._stroke;
  static const _ink = _InventoryDashboardState._ink;
  static const _muted = _InventoryDashboardState._muted;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _card,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _stroke),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _stroke),
                ),
                child: Icon(icon, size: 24, color: _ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: _muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}
