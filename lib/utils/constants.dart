library constants;

class AppConstants {
  static const String appTitle = 'Yaroslav Moskalenko - Recipes 2026';
  static const String infoText = '''
Yaroslav Moskalenko - Recipes 2026
Web application for recipe recommendation based on ingredients.
Uses optimized hybrid search and preliminary K-Means clustering, where each recipe is assigned a cluster ID.
Data is stored in JSON files (lightweight and fast for prototyping).
History of last 7 ingredient sets is saved locally.
''';
  
  static const int maxRecommendations = 9;
  static const int minRecommendations = 7;
  static const int historyCapacity = 7;
  static const int randomIngredientsMin = 5;
  static const int randomIngredientsMax = 10;
  static const int randomRecipesCount = 8; // between 7-9, we use 8
}
