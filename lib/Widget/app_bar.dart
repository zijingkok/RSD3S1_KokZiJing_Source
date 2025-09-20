import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Screen/login_page.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  const AppTopBar({super.key, this.title});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Make the logo noticeably bigger; scale a bit on wide screens
    final double logoH = MediaQuery.of(context).size.width >= 600 ? 44 : 36;

    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1D2A32),
      elevation: 0,
      centerTitle: false,
      titleSpacing: 12,
      title: Row(
        children: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'signout') _signOut(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
            tooltip: 'Menu',
            child: Row(
              children: [
                // Bigger app logo
                SizedBox(
                  height: logoH,
                  child: Image.asset(
                    'assets/images/GodlikeLogo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported_outlined, size: 24),
                  ),
                ),
                if ((title ?? '').trim().isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(
                    title!.trim(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D2A32),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'signout') _signOut(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
            tooltip: 'Account',
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE5E7EB),
              child: Icon(Icons.person_outline, color: Color(0xFF6A7A88), size: 18),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
