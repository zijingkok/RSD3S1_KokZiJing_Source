import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Same palette used across your CRM pages
  static const _ink = Color(0xFF1D2A32);
  static const _muted = Color(0xFF6A7A88);
  static const _stroke = Color(0xFFE6ECF1);
  static const _primary = Color(0xFF1E88E5);
  static const _primaryDark = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final items = <BottomNavigationBarItem>[
      _item(Icons.dashboard_outlined, 'Dashboard', 0),
      _item(Icons.directions_car_outlined, 'Vehicle', 1),
      _item(Icons.assignment_outlined, 'Job', 2),
      _item(Icons.people_alt_outlined, 'CRM', 3),
      _item(Icons.inventory_2_outlined, 'Inventory', 4),
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(color: _stroke),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: Theme(
            // Tighten spacing + unify label styles without touching global theme
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: _primaryDark,
              unselectedItemColor: _muted,
              selectedFontSize: 12.5,
              unselectedFontSize: 12.5,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
              showUnselectedLabels: true,
              items: items,
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _item(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      label: label,
      icon: _InactiveIcon(icon: icon),
      // When active, wrap the same icon in a soft pill highlight
      activeIcon: _ActivePillIcon(
        icon: icon,
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        iconColor: Colors.white,
      ),
    );
  }
}

/* ------- Small helpers for a polished active/inactive look ------- */

class _InactiveIcon extends StatelessWidget {
  final IconData icon;
  const _InactiveIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Icon(icon, size: 22),
    );
  }
}

class _ActivePillIcon extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final Color iconColor;
  const _ActivePillIcon({
    required this.icon,
    required this.gradient,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: iconColor),
    );
  }
}
