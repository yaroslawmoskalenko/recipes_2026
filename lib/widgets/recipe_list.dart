import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/data_loader.dart';
import '../services/search_service.dart';
import '../utils/constants.dart';
import 'dart:math';

class RecipeList extends StatefulWidget {
  final List<int> userIngredients;
  final Function(List<int>)?
  onFillIngredients; // callback to fill ingredients from recipe

  const RecipeList({
    Key? key,
    required this.userIngredients,
    this.onFillIngredients,
  }) : super(key: key);

  @override
  State<RecipeList> createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  List<Recipe> _recipes = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void didUpdateWidget(covariant RecipeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userIngredients != widget.userIngredients) {
      _search();
    }
  }

  // Future<void> _search() async {
  //   setState(() => _loading = true);
  //   final ids = widget.userIngredients;
  //   List<int> recommendedIds = [];
  //   if (ids.isEmpty) {
  //     recommendedIds = await _getRandomRecipes();
  //   } else {
  //     recommendedIds = SearchService.recommendRecipes(ids, AppConstants.maxRecommendations);
  //     if (recommendedIds.length < AppConstants.minRecommendations) {
  //       final extra = await _getRandomRecipes(AppConstants.minRecommendations - recommendedIds.length);
  //       recommendedIds.addAll(extra);
  //       recommendedIds = recommendedIds.toSet().toList();
  //     }
  //   }
  //   final fullMap = DataLoader.fullRecipes;
  //   final List<Recipe> recipes = [];
  //   for (int rid in recommendedIds) {
  //     if (fullMap.containsKey(rid)) {
  //       final compact = DataLoader.compactRecipes[rid];
  //       recipes.add(Recipe(
  //         id: rid,
  //         title: fullMap[rid]!.title,
  //         description: fullMap[rid]!.description,
  //         ingredientsIds: compact?.ingredientsIds ?? [],
  //         clusterId: compact?.clusterId ?? -1,
  //       ));
  //     }
  //   }
  //   setState(() {
  //     _recipes = recipes;
  //     _loading = false;
  //   });
  // }

  Future<void> _search() async {
    setState(() => _loading = true);
    final ids = widget.userIngredients;
    List<int> recommendedIds = [];
    if (ids.isEmpty) {
      recommendedIds = await _getRandomRecipes();
    } else {
      recommendedIds = SearchService.recommendRecipes(
        ids,
        AppConstants.maxRecommendations,
      );
      if (recommendedIds.length < AppConstants.minRecommendations) {
        final extra = await _getRandomRecipes(
          AppConstants.minRecommendations - recommendedIds.length,
        );
        recommendedIds.addAll(extra);
        recommendedIds = recommendedIds.toSet().toList();
      }
    }
    final fullMap = DataLoader.fullRecipes;
    final List<Recipe> recipes = [];
    for (int rid in recommendedIds) {
      if (fullMap.containsKey(rid)) {
        final compact = DataLoader.compactRecipes[rid];
        recipes.add(
          Recipe(
            id: rid,
            title: fullMap[rid]!.title,
            description: fullMap[rid]!.description,
            ingredientsIds: compact?.ingredientsIds ?? [],
            clusterId: compact?.clusterId ?? -1,
          ),
        );
      }
    }

    // --- Remove duplicates by title+description string comparison ---
    final uniqueRecipes = <Recipe>[];
    final seenKeys = <String>{};
    for (final recipe in recipes) {
      final key = '${recipe.title}|${recipe.description}';
      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        uniqueRecipes.add(recipe);
      }
    }


    setState(() {
      _recipes = uniqueRecipes; // use uniqueRecipes instead of recipes
      _loading = false;
    });
  }

  Future<List<int>> _getRandomRecipes([int? count]) async {
    final allIds = DataLoader.compactRecipes.keys.toList();
    if (allIds.isEmpty) return [];
    final random = Random();
    count ??= AppConstants.randomRecipesCount;
    count = count.clamp(0, allIds.length);
    final shuffled = List<int>.from(allIds)..shuffle(random);
    return shuffled.take(count).toList();
  }

  void _onRecipeTap(Recipe recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Fill ingredients?'),
            content: Text(
              'Do you want to replace current ingredients with those from "${recipe.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Yes'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      if (widget.onFillIngredients != null) {
        widget.onFillIngredients!(recipe.ingredientsIds);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_recipes.isEmpty) {
      return const Center(
        child: Text(
          'No recipes found. Try adding ingredients or use random recipes.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Text(
            'Recipes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recipes.length,
            itemBuilder: (ctx, idx) {
              final r = _recipes[idx];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(r.title),
                  subtitle: Text(
                    r.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _onRecipeTap(r),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
