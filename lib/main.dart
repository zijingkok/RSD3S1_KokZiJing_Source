import 'package:flutter/material.dart';
import 'Screen/login_page.dart';
import 'Screen/main_dashboard.dart';

void main() {
  runApp(const MyApp()); // 🔥 Entry point
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Flutter App',
      initialRoute: '/login', // 🔹 Start at Login first
      routes: {
        '/login': (context) => LoginPage(),
      },
    );
  }
}
