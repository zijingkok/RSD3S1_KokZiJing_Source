import 'package:flutter/material.dart';
import 'Screen/login_page.dart';
import 'Screen/main_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(

    url: 'https://vkfdwthcqjbqilooadrq.supabase.co',
    anonKey: 'sb_secret_OnYJCo8ezEIB3vRcWnFj4g_B6iE4LD2',
  );

  runApp(const MyApp());
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
