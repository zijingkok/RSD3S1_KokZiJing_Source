import 'package:flutter/material.dart';
import 'inventory_dashboard.dart';
import 'inventory_list.dart';
import 'inventory_part_usage.dart';
import 'inventory_request.dart';
import 'inventory_request_status.dart';

class InventoryModule extends StatelessWidget {
  const InventoryModule({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/dashboard',
      onGenerateRoute: (settings) {
        late Widget page;

        switch (settings.name) {
          case '/list':
            page = const InventoryListScreen();
            break;

          case '/request':
          // Extract the Part argument from the route settings
            page = const InventoryRequestScreen();
            break;

          case '/usage':
            page = const PartUsageHistoryScreen();
            break;

          case '/status':
            page = const ProcurementRequestsScreen();
            break;

          case '/dashboard':
          default:
            page = const InventoryDashboard();
            break;
        }

        return MaterialPageRoute(
          builder: (_) => page,
          settings: settings,
        );
      },
    );
  }
}