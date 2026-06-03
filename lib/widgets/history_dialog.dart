import 'package:flutter/material.dart';
import '../services/data_loader.dart';

class HistoryDialog extends StatelessWidget {
  final List<List<int>> history;

  const HistoryDialog({Key? key, required this.history}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Last ingredient sets'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: history.length,
          itemBuilder: (ctx, idx) {
            final set = history[history.length - 1 - idx]; // newest first
            final names = set.map((id) => DataLoader.ingredientNames[id] ?? '?').join(', ');
            return ListTile(
              title: Text(names, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.of(context).pop(set),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      ],
    );
  }
}