import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/data_loader.dart';
import 'widgets/tag_list.dart';
import 'widgets/recipe_list.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey.shade200,
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: DataLoader.loadAllData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error loading data: ${snapshot.error}'),
              ),
            );
          }
          return const MainScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<int> _selectedIngredients = [];

  // final GlobalKey<RecipeListState> _recipeListKey =
  //     GlobalKey<RecipeListState>();

  void _fillIngredientsFromRecipe(List<int> ingredients) {
    setState(() {
      _selectedIngredients = ingredients;
    });
    // Force recipe list to refresh (it will via didUpdateWidget)
  }

  void _randomRecipesOnly() {
    setState(() {
      _selectedIngredients = [];
    });
    // trigger search in RecipeList (empty ingredients leads to random)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: Text('About'),
                      content: Text(AppConstants.infoText),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TagList(
              selectedIngredients: _selectedIngredients,
              onChanged: (newList) {
                setState(() {
                  _selectedIngredients = newList;
                });
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: RecipeList(
              // key: _recipeListKey,
              key: ValueKey(_selectedIngredients.hashCode),
              userIngredients: _selectedIngredients,
              onFillIngredients: _fillIngredientsFromRecipe,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _randomRecipesOnly,
              icon: const Icon(Icons.shuffle),
              label: const Text('Random Recipes (clear ingredients)'),
            ),
          ),
        ],
      ),
    );
  }
}
