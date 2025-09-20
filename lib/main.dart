import 'package:flutter/material.dart';
import 'package:provider/provider.dart';            // add this
import 'Screen/login_page.dart';
import 'Screen/main_dashboard.dart';
import 'state/work_order_store.dart';// add this
import 'state/mechanic_store.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkOrderStore()..fetch()),
        ChangeNotifierProvider(create: (_) => MechanicStore()..fetch()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Workshop Management',
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginPage(),

          // from dashboard you can navigate into JobModule/WorkOrder screens
        },
      ),
    );
  }
}
