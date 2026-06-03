import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const String _key = 'ingredient_sets_history';
  static const int _maxCapacity = 7;

  static Future<List<List<int>>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    try {
      List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((e) => List<int>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveHistory(List<List<int>> history) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = json.encode(history);
    await prefs.setString(_key, jsonString);
  }

  /// Adds a new ingredient set to history, avoiding duplicates (checks last entry)
  static Future<void> addToHistory(List<int> ingredients) async {
    if (ingredients.isEmpty) return;
    List<List<int>> history = await loadHistory();
    // Remove if same as last
    if (history.isNotEmpty && _listsEqual(history.last, ingredients)) {
      return;
    }
    history.add(ingredients);
    if (history.length > _maxCapacity) {
      history.removeAt(0);
    }
    await saveHistory(history);
  }

  static bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}