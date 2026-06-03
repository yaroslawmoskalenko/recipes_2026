class Ingredient {
  final int id;
  final String name;

  Ingredient({required this.id, required this.name});

  factory Ingredient.fromJson(Map<String, dynamic> json, int id) {
    // For ingredients_rev_short.json: key is id as string, value is name
    return Ingredient(id: id, name: json[id.toString()] as String);
  }

  Map<String, dynamic> toJson() => {id.toString(): name};
}