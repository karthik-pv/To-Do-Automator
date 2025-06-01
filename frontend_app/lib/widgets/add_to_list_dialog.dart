import 'package:flutter/material.dart';
import '../models/task_list.dart';

class AddToListDialog extends StatefulWidget {
  final List<TaskList> lists;

  const AddToListDialog({super.key, required this.lists});

  @override
  State<AddToListDialog> createState() => _AddToListDialogState();
}

class _AddToListDialogState extends State<AddToListDialog> {
  final Set<String> _selectedListIds = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Lists'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.lists.length,
          itemBuilder: (context, index) {
            final list = widget.lists[index];
            final isSelected = _selectedListIds.contains(list.id);
            
            return CheckboxListTile(
              title: Text(list.name),
              subtitle: Text('${list.name} list'),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedListIds.add(list.id);
                  } else {
                    _selectedListIds.remove(list.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedListIds.isEmpty 
              ? null 
              : () => Navigator.pop(context, _selectedListIds.toList()),
          child: const Text('Add'),
        ),
      ],
    );
  }
} 