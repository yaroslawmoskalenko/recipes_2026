import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/data_loader.dart';
import '../services/history_service.dart';
import 'add_ingredient_dialog.dart';
import 'history_dialog.dart';
import 'dart:math';

typedef OnTagsChanged = void Function(List<int>);

class TagList extends StatefulWidget {
  final List<int> selectedIngredients;
  final OnTagsChanged onChanged;

  const TagList({
    Key? key,
    required this.selectedIngredients,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<TagList> createState() => _TagListState();
}

class _TagListState extends State<TagList> {
  void _removeIngredient(int id) {
    final newList = List<int>.from(widget.selectedIngredients)..remove(id);
    widget.onChanged(newList);
    _saveToHistory(newList);
  }

  void _clearAll() {
    widget.onChanged([]);
    _saveToHistory([]);
  }

  Future<void> _addIngredient() async {
    final allIngredients = DataLoader.getAllIngredients();
    final selectedId = await showDialog<int>(
      context: context,
      builder: (_) => AddIngredientDialog(ingredients: allIngredients),
    );
    if (selectedId != null &&
        !widget.selectedIngredients.contains(selectedId)) {
      final newList = List<int>.from(widget.selectedIngredients)
        ..add(selectedId);
      widget.onChanged(newList);
      _saveToHistory(newList);
    }
  }

  Future<void> _randomIngredients() async {
    final allIds = DataLoader.ingredientNames.keys.toList();
    if (allIds.isEmpty) return;
    final random = Random();
    int maxVal = AppConstants.randomIngredientsMax.toInt();
    int minVal = AppConstants.randomIngredientsMin.toInt();
    int count = random.nextInt(maxVal - minVal + 1) + minVal;
    count = count.clamp(0, allIds.length);
    final shuffled = List<int>.from(allIds)..shuffle(random);
    final newList = shuffled.take(count).toList();
    widget.onChanged(newList);
    _saveToHistory(newList);
  }

  Future<void> _showHistory() async {
    final history = await HistoryService.loadHistory();
    if (history.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No history yet')));
      return;
    }
    final selectedSet = await showDialog<List<int>>(
      context: context,
      builder: (_) => HistoryDialog(history: history),
    );
    if (selectedSet != null) {
      widget.onChanged(selectedSet);
      _saveToHistory(selectedSet);
    }
  }

  void _saveToHistory(List<int> newSet) {
    HistoryService.addToHistory(newSet);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Ingredients',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _addIngredient,
                tooltip: 'Add ingredient',
              ),
              IconButton(
                icon: Icon(Icons.shuffle),
                onPressed: _randomIngredients,
                tooltip: 'Random ingredients',
              ),
              IconButton(
                icon: Icon(Icons.history),
                onPressed: _showHistory,
                tooltip: 'History',
              ),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: _clearAll,
                tooltip: 'Clear all',
              ),
            ],
          ),
        ),
        if (widget.selectedIngredients.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 12.0,
            ),
            color: Colors.grey.shade300,
            child: Text(
              'No ingredients selected. Press [+] or "random"',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children:
                widget.selectedIngredients.map((id) {
                  final name = DataLoader.ingredientNames[id] ?? 'Unknown';
                  return Chip(
                    label: Text(name),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeIngredient(id),
                  );
                }).toList(),
          ),
      ],
    );
  }
}
