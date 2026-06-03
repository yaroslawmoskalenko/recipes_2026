import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/recipe.dart';
import '../models/ingredient.dart';

class DataLoader {
  // Full recipes (for display)
  static Map<int, Recipe> _fullRecipes = {};
  // Compact recipes (for fast search)
  static Map<int, Recipe> _compactRecipes = {};
  // Ingredient id -> name
  static Map<int, String> _ingredientNames = {};
  // Ingredient name -> id
  static Map<String, int> _ingredientIds = {};

  static bool get isLoaded => _compactRecipes.isNotEmpty;

  static Future<void> loadAllData() async {
    await _loadFullRecipes();
    await _loadCompactRecipes();
    await _loadIngredients();
  }

  static Future<void> _loadFullRecipes() async {
    final String jsonString = await rootBundle.loadString('assets/recipes_short.json');
    final List<dynamic> list = json.decode(jsonString);
    for (var item in list) {
      final recipe = Recipe.fromFullJson(item);
      _fullRecipes[recipe.id] = recipe;
    }
  }

  static Future<void> _loadCompactRecipes() async {
    final String jsonString = await rootBundle.loadString('assets/recipes_with_clusters.json');
    final List<dynamic> list = json.decode(jsonString);
    for (var item in list) {
      final recipe = Recipe.fromShortJson(item);
      _compactRecipes[recipe.id] = recipe;
    }
  }

  static Future<void> _loadIngredients() async {
    final String revJson = await rootBundle.loadString('assets/ingredients_rev_short.json');
    final Map<String, dynamic> revMap = json.decode(revJson);
    revMap.forEach((key, value) {
      int id = int.parse(key);
      String name = value.toString();
      _ingredientNames[id] = name;
      _ingredientIds[name] = id;
    });
  }

  static Map<int, Recipe> get fullRecipes => _fullRecipes;
  static Map<int, Recipe> get compactRecipes => _compactRecipes;
  static Map<int, String> get ingredientNames => _ingredientNames;
  static Map<String, int> get ingredientIds => _ingredientIds;

  static List<Ingredient> getAllIngredients() {
    return _ingredientNames.entries.map((e) => Ingredient(id: e.key, name: e.value)).toList();
  }
}