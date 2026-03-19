# NOTE: The updateGoal method needs to be added to app_provider.dart
# It's called from goals_screen.dart
# Add this after the insertGoal call in app_provider.dart:

  Future<void> updateGoal(int id, Map<String, dynamic> updates) async {
    await _db.updateGoal(id, updates);
    notifyListeners();
  }
