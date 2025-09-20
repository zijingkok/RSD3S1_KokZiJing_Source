import 'package:flutter/foundation.dart';
import '../Models/mechanic.dart';
import '../services/mechanic_service.dart';

class MechanicStore extends ChangeNotifier {
  final _svc = MechanicService();
  List<Mechanic> mechanics = [];
  bool loading = false;

  Future<void> fetch() async {
    loading = true;
    notifyListeners();
    try {
      mechanics = await _svc.fetchMechanics();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Helper: get mechanic name by id (UUID → full_name).
  String? nameFor(String? mechanicId) {
    if (mechanicId == null) return null;
    try {
      return mechanics.firstWhere((m) => m.id == mechanicId).name;
    } catch (_) {
      return null; // return null if no match
    }
  }

  Mechanic? byId(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    try { return mechanics.firstWhere((m) => m.id == id); } catch (_) { return null; }
  }
}


