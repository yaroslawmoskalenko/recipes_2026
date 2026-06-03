class Recipe {
  final int id;
  final String title;
  final String description;
  final List<int> ingredientsIds;
  final int clusterId;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredientsIds,
    required this.clusterId,
  });

  factory Recipe.fromShortJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      title: json['recipe_title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      ingredientsIds: List<int>.from(json['ingredients_ids'] ?? []),
      clusterId: json['cluster_id'] as int? ?? -1,
    );
  }

  // For recipes_short.json (full) – we need only title and description
  factory Recipe.fromFullJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      title: json['recipe_title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      ingredientsIds: [], // not used from full json
      clusterId: -1,
    );
  }
}