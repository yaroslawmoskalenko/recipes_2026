import '../models/recipe.dart';
import 'data_loader.dart';

class SearchService {
  /// Returns list of recipe IDs sorted by relevance (number of common ingredients)
  static List<int> findRecipesByIngredients(List<int> userIngredients, int limit) {
    if (userIngredients.isEmpty) return [];
    
    final Map<int, int> matchCount = {};
    final Map<int, Recipe> compact = DataLoader.compactRecipes;
    
    for (var recipe in compact.values) {
      int count = 0;
      for (int ing in userIngredients) {
        if (recipe.ingredientsIds.contains(ing)) count++;
      }
      if (count > 0) {
        matchCount[recipe.id] = count;
      }
    }
    
    // Sort by match count descending
    final sortedIds = matchCount.keys.toList();
    sortedIds.sort((a, b) => matchCount[b]!.compareTo(matchCount[a]!));
    
    return sortedIds.take(limit).toList();
  }
  
  /// Get recipes from the same cluster (excluding already selected ids)
  static List<int> getRecipesFromCluster(int clusterId, List<int> excludeIds, int limit) {
    final Map<int, Recipe> compact = DataLoader.compactRecipes;
    final List<int> sameCluster = [];
    
    for (var recipe in compact.values) {
      if (recipe.clusterId == clusterId && !excludeIds.contains(recipe.id)) {
        sameCluster.add(recipe.id);
      }
    }
    
    // Optionally sort by some relevance? We'll sort by number of common ingredients later in UI.
    return sameCluster.take(limit).toList();
  }
  
  /// Recommend top recipes: first direct matches, then fill from cluster of the best match.
  static List<int> recommendRecipes(List<int> userIngredients, int desiredCount) {
    if (userIngredients.isEmpty) return [];
    
    // Step 1: direct matches sorted by match count
    List<int> direct = findRecipesByIngredients(userIngredients, desiredCount);
    
    if (direct.length >= desiredCount) {
      return direct.sublist(0, desiredCount);
    }
    
    // Step 2: need more – take cluster of the best match (first in direct list)
    if (direct.isNotEmpty) {
      int bestRecipeId = direct.first;
      Recipe? bestRecipe = DataLoader.compactRecipes[bestRecipeId];
      if (bestRecipe != null && bestRecipe.clusterId != -1) {
        List<int> fromCluster = getRecipesFromCluster(bestRecipe.clusterId, direct, desiredCount - direct.length);
        direct.addAll(fromCluster);
      }
    }
    
    // Still not enough? Possibly add random popular recipes? We'll just return what we have.
    return direct.take(desiredCount).toList();
  }
}