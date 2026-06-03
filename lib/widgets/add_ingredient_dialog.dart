import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class AddIngredientDialog extends StatefulWidget {
  final List<Ingredient> ingredients;

  const AddIngredientDialog({Key? key, required this.ingredients}) : super(key: key);

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  final TextEditingController _controller = TextEditingController();
  late List<Ingredient> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.ingredients;
  }

  void _filter(String query) {
    setState(() {
      _filtered = widget.ingredients.where((i) => i.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select an ingredient'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: 'Search...'),
              onChanged: _filter,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length,
                itemBuilder: (ctx, idx) {
                  final ing = _filtered[idx];
                  return ListTile(
                    title: Text(ing.name),
                    onTap: () => Navigator.of(context).pop(ing.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      ],
    );
  }
}