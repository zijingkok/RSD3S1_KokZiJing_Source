import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const AppTopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: Row(
        children: [
          // Logo placeholder
          SizedBox(
            height: 28,
            child: Image.asset(
              'assets/logo.png', // replace with your asset
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text(
                'godlike\nworkshop',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE5E7EB), // grey dot
          ),
        ),
      ],
      foregroundColor: Colors.black,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
