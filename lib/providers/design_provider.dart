import 'package:flutter/foundation.dart';
import 'package:see_for_designs/models/design_model.dart';
import 'package:see_for_designs/services/database_service.dart';

class DesignProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<DesignModel> _designs = [];

  List<DesignModel> get designs => _designs;

  Future<void> loadDesigns() async {
    _designs = await _databaseService.getAllDesigns();
    notifyListeners();
  }

  Future<void> addDesign(DesignModel design) async {
    // Check for duplicate title
    final existing = await _databaseService.getDesignsByTitle(design.title);
    if (existing.isNotEmpty) {
      // Duplicate handling will be done in the UI via DuplicateDialog
      // We'll just add the new design with a modified title? Actually the dialog decides.
      // For now, we'll throw an exception to indicate duplicate.
      throw DuplicateDesignException(existing.first, design);
    }
    await _databaseService.insertDesign(design);
    _designs.add(design);
    notifyListeners();
  }

  Future<void> updateDesign(DesignModel design) async {
    await _databaseService.updateDesign(design);
    final index = _designs.indexWhere((d) => d.id == design.id);
    if (index != -1) {
      _designs[index] = design;
      notifyListeners();
    }
  }

  Future<void> moveToTrash(String id) async {
    final design = _designs.firstWhere((d) => d.id == id);
    final updated = design.copyWith(isTrashed: true);
    await _databaseService.updateDesign(updated);
    _designs[_designs.indexWhere((d) => d.id == id)] = updated;
    notifyListeners();
  }

  Future<void> restoreDesign(String id) async {
    final design = _designs.firstWhere((d) => d.id == id);
    final updated = design.copyWith(isTrashed: false);
    await _databaseService.updateDesign(updated);
    _designs[_designs.indexWhere((d) => d.id == id)] = updated;
    notifyListeners();
  }

  Future<void> deleteDesignPermanently(String id) async {
    await _databaseService.deleteDesign(id);
    _designs.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  Future<void> replaceDesign(DesignModel existing, DesignModel incoming) async {
    // Delete existing, insert incoming
    await _databaseService.deleteDesign(existing.id);
    await _databaseService.insertDesign(incoming);
    _designs.removeWhere((d) => d.id == existing.id);
    _designs.add(incoming);
    notifyListeners();
  }

  Future<void> keepBoth(DesignModel existing, DesignModel incoming) async {
    // Insert incoming with a modified title to avoid duplicate
    final newTitle = '${incoming.title} (1)';
    final newDesign = incoming.copyWith(title: newTitle);
    await _databaseService.insertDesign(newDesign);
    _designs.add(newDesign);
    notifyListeners();
  }
}

class DuplicateDesignException implements Exception {
  final DesignModel existing;
  final DesignModel incoming;
  DuplicateDesignException(this.existing, this.incoming);
}
