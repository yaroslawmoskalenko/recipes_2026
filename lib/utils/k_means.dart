import 'dart:convert';
import 'dart:math';
import 'dart:io';

/// Robust K-Means Clustering for Recipe Ingredients
/// Compatible with Dart/Flutter
class RobustKMeansClustering {
  int k;
  int maxIterations;
  bool useJaccardDistance;
  bool useKMeansPlusPlus;

  List<List<double>> _centroids = [];
  Map<int, Map<int, List<double>>> _clusters = {};

  RobustKMeansClustering({
    this.k = 5,
    this.maxIterations = 100,
    this.useJaccardDistance = true,
    this.useKMeansPlusPlus = true,
  });

  /// Jaccard distance between two binary vectors
  double _jaccardDistance(List<double> vectorA, List<double> vectorB) {
    int intersection = 0;
    int union = 0;

    for (int i = 0; i < vectorA.length; i++) {
      if (vectorA[i] == 1 && vectorB[i] == 1) {
        intersection++;
        union++;
      } else if (vectorA[i] == 1 || vectorB[i] == 1) {
        union++;
      }
    }

    if (union == 0) return 1.0;
    return 1 - (intersection / union);
  }

  /// Euclidean distance (fallback)
  double _euclideanDistance(List<double> vectorA, List<double> vectorB) {
    double sum = 0;
    for (int i = 0; i < vectorA.length; i++) {
      double diff = vectorA[i] - vectorB[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  /// Calculate distance using selected metric
  double _calculateDistance(List<double> vectorA, List<double> vectorB) {
    if (useJaccardDistance) {
      return _jaccardDistance(vectorA, vectorB);
    }
    return _euclideanDistance(vectorA, vectorB);
  }

  /// Convert recipe ingredients to binary feature vector
  List<double> _recipeToVector(
    List<int> ingredients,
    List<int> selectedIngredients,
  ) {
    final Set<int> ingredientsSet = ingredients.toSet();
    final List<double> vector = [];

    for (int ingId in selectedIngredients) {
      vector.add(ingredientsSet.contains(ingId) ? 1.0 : 0.0);
    }

    return vector;
  }

  /// K-Means++ initialization
  List<List<double>> _initCentroidsPlusPlus(Map<int, List<double>> vectors) {
    final List<int> recipeIds = vectors.keys.toList();
    final Random random = Random();

    // Step 1: Choose first centroid randomly
    final List<List<double>> centroids = [];
    final int firstIdx = random.nextInt(recipeIds.length);
    centroids.add(vectors[recipeIds[firstIdx]]!);

    final Set<int> centroidIndices = {recipeIds[firstIdx]};

    // Step 2: Choose remaining centroids
    for (int i = 1; i < k; i++) {
      final Map<int, double> distances = {};
      double maxDistance = 0;

      for (int recipeId in recipeIds) {
        if (centroidIndices.contains(recipeId)) continue;

        final List<double> vector = vectors[recipeId]!;
        double minDistToCentroid = double.infinity;

        for (List<double> centroid in centroids) {
          double dist = _calculateDistance(vector, centroid);
          if (dist < minDistToCentroid) {
            minDistToCentroid = dist;
          }
        }

        distances[recipeId] = minDistToCentroid * minDistToCentroid;
        if (distances[recipeId]! > maxDistance) {
          maxDistance = distances[recipeId]!;
        }
      }

      // Select next centroid with probability proportional to distance
      double rand = random.nextDouble() * maxDistance;
      double cumulative = 0;
      int? selected;

      for (MapEntry<int, double> entry in distances.entries) {
        cumulative += entry.value;
        if (cumulative >= rand) {
          selected = entry.key;
          break;
        }
      }

      if (selected == null && distances.isNotEmpty) {
        selected = distances.keys.first;
      }

      if (selected != null) {
        centroids.add(vectors[selected]!);
        centroidIndices.add(selected);
      }
    }

    return centroids;
  }

  /// Random initialization (fallback)
  List<List<double>> _initCentroidsRandom(Map<int, List<double>> vectors) {
    final List<int> recipeIds = vectors.keys.toList();
    final Random random = Random();
    recipeIds.shuffle(random);

    final List<List<double>> centroids = [];
    for (int i = 0; i < k && i < recipeIds.length; i++) {
      centroids.add(vectors[recipeIds[i]]!);
    }

    // If not enough recipes, duplicate existing centroids
    while (centroids.length < k) {
      centroids.add(List.from(centroids.first));
    }

    return centroids;
  }

  /// Find closest centroid index for a vector
  int _findClosestCentroid(List<double> vector) {
    double minDistance = double.infinity;
    int bestCentroid = 0;

    for (int c = 0; c < _centroids.length; c++) {
      double distance = _calculateDistance(vector, _centroids[c]);
      if (distance < minDistance) {
        minDistance = distance;
        bestCentroid = c;
      }
    }

    return bestCentroid;
  }

  /// Calculate mean vector for a cluster
  List<double>? _calculateCentroid(List<List<double>> vectors) {
    if (vectors.isEmpty) return null;

    final int featureCount = vectors[0].length;
    final List<double> newCentroid = List.filled(featureCount, 0.0);

    for (List<double> vector in vectors) {
      for (int i = 0; i < featureCount; i++) {
        newCentroid[i] += vector[i];
      }
    }

    for (int i = 0; i < featureCount; i++) {
      newCentroid[i] /= vectors.length;
    }

    return newCentroid;
  }

  /// Check if two centroids are different
  bool _centroidsDifferent(List<double>? centroidA, List<double>? centroidB) {
    if (centroidA == null || centroidB == null) return true;
    if (centroidA.length != centroidB.length) return true;

    for (int i = 0; i < centroidA.length; i++) {
      if ((centroidA[i] - centroidB[i]).abs() > 0.0001) {
        return true;
      }
    }
    return false;
  }

  /// Handle empty clusters by moving recipes from largest cluster
  Map<int, Map<int, List<double>>> _handleEmptyClusters(
    Map<int, Map<int, List<double>>> clusters,
    Map<int, List<double>> vectors,
  ) {
    Map<int, Map<int, List<double>>> result = Map.from(clusters);

    for (int c = 0; c < k; c++) {
      if (result[c]!.isEmpty) {
        // Find the largest cluster
        int largestCluster = 0;
        int largestSize = 0;

        for (int i = 0; i < k; i++) {
          int size = result[i]!.length;
          if (size > largestSize) {
            largestSize = size;
            largestCluster = i;
          }
        }

        if (largestSize > 1) {
          // Find recipe farthest from its centroid in the largest cluster
          int? farthestRecipe;
          double maxDistance = -1;

          for (MapEntry<int, List<double>> entry
              in result[largestCluster]!.entries) {
            double distance = _calculateDistance(
              entry.value,
              _centroids[largestCluster],
            );
            if (distance > maxDistance) {
              maxDistance = distance;
              farthestRecipe = entry.key;
            }
          }

          if (farthestRecipe != null) {
            // Move it to empty cluster
            result[c]![farthestRecipe] =
                result[largestCluster]![farthestRecipe]!;
            result[largestCluster]!.remove(farthestRecipe);
          }
        }
      }
    }

    return result;
  }

  /// Train the K-Means model
  Map<int, int> train(
    Map<int, Map<String, dynamic>> recipes,
    List<int> selectedIngredients,
    Function(String)? onProgress,
  ) {
    onProgress?.call("Converting recipes to vectors...");

    final Map<int, List<double>> vectors = {};
    int vectorsCount = 0;

    for (MapEntry<int, Map<String, dynamic>> entry in recipes.entries) {
      final int recipeId = entry.key;
      final List<int> ingredients = List<int>.from(
        entry.value['ingredients_ids'],
      );

      final List<double> vector = _recipeToVector(
        ingredients,
        selectedIngredients,
      );

      // Check if vector has any 1's
      bool hasIngredient = vector.any((val) => val == 1);

      if (hasIngredient) {
        vectors[recipeId] = vector;
        vectorsCount++;
      } else {
        vectors[recipeId] = vector;
      }
    }

    onProgress?.call("Total recipes: ${vectors.length}");
    onProgress?.call("Feature dimension: ${selectedIngredients.length}");
    onProgress?.call(
      "Using ${useJaccardDistance ? "Jaccard" : "Euclidean"} distance",
    );
    onProgress?.call(
      "Using ${useKMeansPlusPlus ? "K-Means++" : "Random"} initialization",
    );

    // Initialize centroids
    if (useKMeansPlusPlus) {
      _centroids = _initCentroidsPlusPlus(vectors);
    } else {
      _centroids = _initCentroidsRandom(vectors);
    }

    bool changed = true;
    int iteration = 0;

    while (changed && iteration < maxIterations) {
      changed = false;
      Map<int, Map<int, List<double>>> newClusters = {};
      for (int c = 0; c < k; c++) {
        newClusters[c] = {};
      }

      // Assign each vector to the nearest centroid
      for (MapEntry<int, List<double>> entry in vectors.entries) {
        int clusterId = _findClosestCentroid(entry.value);
        newClusters[clusterId]![entry.key] = entry.value;
      }

      // Handle empty clusters
      newClusters = _handleEmptyClusters(newClusters, vectors);

      // Recalculate centroids
      List<List<double>> newCentroids = [];
      bool centroidsChanged = false;

      for (int c = 0; c < k; c++) {
        List<double>? newCentroid = _calculateCentroid(
          newClusters[c]!.values.toList(),
        );

        if (newCentroid == null) {
          newCentroids.add(_centroids[c]);
        } else {
          newCentroids.add(newCentroid);
        }

        if (_centroidsDifferent(_centroids[c], newCentroid)) {
          centroidsChanged = true;
        }
      }

      if (centroidsChanged) {
        changed = true;
        _centroids = newCentroids;
      }

      _clusters = newClusters;
      iteration++;

      // Build status string
      String status = "Iteration $iteration: ";
      for (int c = 0; c < k; c++) {
        status += "C$c=${_clusters[c]!.length} ";
      }
      onProgress?.call(status);
    }

    onProgress?.call("Training completed in $iteration iterations");

    // Build assignments
    final Map<int, int> assignments = {};
    for (int c = 0; c < k; c++) {
      for (int recipeId in _clusters[c]!.keys) {
        assignments[recipeId] = c;
      }
    }

    return assignments;
  }

  /// Get cluster statistics
  Map<int, int> getClusterStats() {
    final Map<int, int> stats = {};
    for (int c = 0; c < k; c++) {
      stats[c] = _clusters[c]?.length ?? 0;
    }
    return stats;
  }

  /// Get centroids
  List<List<double>> getCentroids() {
    return _centroids;
  }
}

/// Helper functions
class ClusteringHelper {
  /// Load JSON file
  static dynamic loadJsonFile(String path) {
    final file = File(path);
    final content = file.readAsStringSync();
    return jsonDecode(content);
  }

  /// Save JSON file
  static void saveJsonFile(String path, dynamic data) {
    final file = File(path);
    final encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(data));
  }

  /// Extract all unique ingredient IDs from recipes
  static List<int> getAllIngredientIds(List<Map<String, dynamic>> recipes) {
    final Set<int> allIds = {};

    for (var recipe in recipes) {
      if (recipe.containsKey('ingredients_ids')) {
        final List<int> ids = List<int>.from(recipe['ingredients_ids']);
        allIds.addAll(ids);
      }
    }

    return allIds.toList();
  }

  /// Count frequency of each ingredient across all recipes
  static Map<int, int> countIngredientFrequency(
    List<Map<String, dynamic>> recipes,
  ) {
    final Map<int, int> frequency = {};

    for (var recipe in recipes) {
      if (recipe.containsKey('ingredients_ids')) {
        final List<int> ids = List<int>.from(recipe['ingredients_ids']);
        final Set<int> uniqueIds = ids.toSet();

        for (int ingId in uniqueIds) {
          frequency[ingId] = (frequency[ingId] ?? 0) + 1;
        }
      }
    }

    return frequency;
  }

  /// Select top N most frequent ingredients
  static List<int> selectTopIngredients(Map<int, int> frequency, int topN) {
    final entries = frequency.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    final List<int> result = [];
    for (int i = 0; i < topN && i < entries.length; i++) {
      result.add(entries[i].key);
    }

    return result;
  }

  /// Filter ingredients by mapping
  static List<int> filterByIngredientMapping(
    List<int> ingredientIds,
    Map<int, String> ingredientMapping,
  ) {
    return ingredientIds
        .where((id) => ingredientMapping.containsKey(id))
        .toList();
  }

  /// Diagnose clustering issues
  static void diagnoseClustering(
    Map<int, Map<String, dynamic>> recipes,
    List<int> selectedIngredients,
  ) {
    print("\n=== DIAGNOSIS ===\n");

    // Check recipe size distribution
    final List<int> sizes = [];
    for (var recipe in recipes.values) {
      sizes.add(recipe['ingredients_ids'].length);
    }

    final double avgSize = sizes.reduce((a, b) => a + b) / sizes.length;
    final int minSize = sizes.reduce((a, b) => a < b ? a : b);
    final int maxSize = sizes.reduce((a, b) => a > b ? a : b);

    print("Recipe ingredient count:");
    print("  Average: ${avgSize.toStringAsFixed(1)}");
    print("  Min: $minSize");
    print("  Max: $maxSize");

    if (avgSize < 3) {
      print("  ⚠️  WARNING: Recipes have very few ingredients.");
    }

    // Check selected ingredients coverage
    int recipesWithSelected = 0;
    final Set<int> selectedSet = selectedIngredients.toSet();

    for (var recipe in recipes.values) {
      final List<int> ingredients = List<int>.from(recipe['ingredients_ids']);
      bool hasSelected = ingredients.any((ing) => selectedSet.contains(ing));
      if (hasSelected) recipesWithSelected++;
    }

    final double coveragePercent = recipesWithSelected / recipes.length * 100;
    print("\nSelected ingredients coverage:");
    print(
      "  Recipes with at least one selected ingredient: $recipesWithSelected (${coveragePercent.toStringAsFixed(1)}%)",
    );

    if (coveragePercent < 50) {
      print("  ⚠️  WARNING: Low coverage. Increase top ingredients count.");
    }

    // Recommendations
    print("\n=== RECOMMENDATIONS ===\n");

    if (avgSize < 3) {
      print("1. Increase 'topIngredientsCount' to include more ingredients");
    }

    if (coveragePercent < 50) {
      print("2. Increase 'topIngredientsCount' (try 500 or 800)");
    }

    print("3. Try different K values (3, 5, 8, 10, 15)");
    print("4. Use Jaccard distance (better for binary data)");
    print("5. Use K-Means++ initialization");
  }

  /// Index recipes by ID
  static Map<int, Map<String, dynamic>> indexRecipesById(
    List<Map<String, dynamic>> recipes,
  ) {
    final Map<int, Map<String, dynamic>> indexed = {};
    for (var recipe in recipes) {
      indexed[recipe['id']] = recipe;
    }
    return indexed;
  }
}

/// Main function
void main() async {
  print("========================================");
  print("ROBUST K-MEANS CLUSTERING FOR DART");
  print("========================================\n");

  // Configuration
  final String recipesFile = 'recipes.json';
  final String ingredientsMapFile = 'ingredients_map.json';
  final String outputFile = 'recipes_with_clusters.json';

  // Parameters to try
  final List<int> kValuesToTry = [3, 5, 8, 10, 15];
  final List<int> topIngredientsOptions = [100, 200, 300, 500, 800];

  // Load data
  if (!File(recipesFile).existsSync()) {
    print("Error: '$recipesFile' not found.");
    return;
  }

  final List<dynamic> recipesData = ClusteringHelper.loadJsonFile(recipesFile);
  final List<Map<String, dynamic>> recipesList =
      recipesData.map((e) => Map<String, dynamic>.from(e)).toList();

  print("Loaded ${recipesList.length} recipes");

  // Load ingredient mapping (optional)
  Map<int, String> ingredientMapping = {};
  if (File(ingredientsMapFile).existsSync()) {
    final Map<String, dynamic> mappingData = ClusteringHelper.loadJsonFile(
      ingredientsMapFile,
    );
    ingredientMapping = Map<int, String>.fromIterable(
      mappingData.keys,
      key: (k) => int.parse(k),
      value: (k) => mappingData[k].toString(),
    );
    print("Loaded ${ingredientMapping.length} ingredient names");
  }

  // Get all ingredients and their frequencies
  final Map<int, int> frequency = ClusteringHelper.countIngredientFrequency(
    recipesList,
  );
  final List<int> allIngredients = frequency.keys.toList();

  // Sort by frequency
  allIngredients.sort((a, b) => frequency[b]!.compareTo(frequency[a]!));

  print("Total unique ingredients: ${allIngredients.length}");

  // Index recipes by ID
  final Map<int, Map<String, dynamic>> recipes =
      ClusteringHelper.indexRecipesById(recipesList);

  bool success = false;
  Map<int, int>? bestAssignments;
  Map<String, dynamic>? bestConfig;

  // Try different configurations
  for (int topN in topIngredientsOptions) {
    if (topN > allIngredients.length) topN = allIngredients.length;

    final List<int> selectedIngredients = allIngredients.sublist(0, topN);

    print("\n--- Trying top $topN ingredients ---");

    // Diagnose before training
    ClusteringHelper.diagnoseClustering(recipes, selectedIngredients);

    for (int k in kValuesToTry) {
      if (k > recipes.length / 2) continue;

      print("\n--- Training with K = $k ---");

      final kmeans = RobustKMeansClustering(
        k: k,
        maxIterations: 100,
        useJaccardDistance: true,
        useKMeansPlusPlus: true,
      );

      final assignments = kmeans.train(recipes, selectedIngredients, (msg) {
        print("  $msg");
      });

      final stats = kmeans.getClusterStats();

      int nonEmptyClusters = 0;
      int maxClusterSize = 0;
      int minClusterSize = 999999999;

      for (int size in stats.values) {
        if (size > 0) {
          nonEmptyClusters++;
          maxClusterSize = maxClusterSize > size ? maxClusterSize : size;
          minClusterSize = minClusterSize < size ? minClusterSize : size;
        }
      }

      double ratio = maxClusterSize / (minClusterSize > 0 ? minClusterSize : 1);

      print("\n  Result:");
      print("    Non-empty clusters: $nonEmptyClusters / $k");
      print("    Max cluster size: $maxClusterSize");
      print("    Min cluster size: $minClusterSize");
      print("    Size ratio (max/min): ${ratio.toStringAsFixed(2)}");

      // Success criteria
      if (nonEmptyClusters >= 2 && ratio < 10) {
        success = true;
        bestAssignments = assignments;
        bestConfig = {'topN': topN, 'k': k};
        break;
      }
    }

    if (success) break;
  }

  // Fallback clustering if needed
  if (!success) {
    print("\n=== USING FALLBACK CLUSTERING ===");
    print("K-Means failed, using ingredient-based clustering...");

    bestAssignments = {};
    final List<int> topIngredients = allIngredients.sublist(0, 8);

    for (var recipe in recipes.entries) {
      final int recipeId = recipe.key;
      final List<int> ingredients = List<int>.from(
        recipe.value['ingredients_ids'],
      );

      int? bestMatch;
      int bestCount = 0;

      for (int idx = 0; idx < topIngredients.length; idx++) {
        int count =
            ingredients.where((ing) => ing == topIngredients[idx]).length;
        if (count > bestCount) {
          bestCount = count;
          bestMatch = idx;
        }
      }

      bestAssignments![recipeId] =
          bestMatch ?? (recipeId % topIngredients.length);
    }

    bestConfig = {'topN': 'fallback', 'k': 8};
  }

  // Add cluster_id to recipes
  print("\n=== FINAL OUTPUT ===");
  print(
    "Using configuration: top ${bestConfig!['topN']} ingredients, K = ${bestConfig['k']}",
  );

  final List<Map<String, dynamic>> resultRecipes = [];
  for (var recipe in recipesList) {
    final int recipeId = recipe['id'];
    recipe['cluster_id'] = bestAssignments![recipeId] ?? 0;
    resultRecipes.add(recipe);
  }

  // Save results
  ClusteringHelper.saveJsonFile(outputFile, resultRecipes);
  print("\nResults saved to '$outputFile'");

  // Show final cluster distribution
  final Map<int, int> finalStats = {};
  for (var recipe in resultRecipes) {
    final int cid = recipe['cluster_id'];
    finalStats[cid] = (finalStats[cid] ?? 0) + 1;
  }

  print("\nFinal cluster distribution:");
  for (var entry in finalStats.entries) {
    final double percent = entry.value / resultRecipes.length * 100;
    print(
      "  Cluster ${entry.key}: ${entry.value} recipes (${percent.toStringAsFixed(1)}%)",
    );
  }

  print("\nDone!");
}
