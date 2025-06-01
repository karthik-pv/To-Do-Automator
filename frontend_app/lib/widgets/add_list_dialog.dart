import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AddListDialog extends StatefulWidget {
  const AddListDialog({super.key});

  @override
  State<AddListDialog> createState() => _AddListDialogState();
}

class _AddListDialogState extends State<AddListDialog> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'list';
  int _selectedColor = 0xFF0078D4;

  final List<Map<String, dynamic>> _icons = [
    {'name': 'list', 'icon': Icons.list},
    {'name': 'home', 'icon': Icons.home},
    {'name': 'work', 'icon': Icons.work},
    {'name': 'shopping', 'icon': Icons.shopping_cart},
    {'name': 'family', 'icon': Icons.family_restroom},
    {'name': 'travel', 'icon': Icons.flight},
    {'name': 'health', 'icon': Icons.health_and_safety},
    {'name': 'education', 'icon': Icons.school},
    {'name': 'finance', 'icon': Icons.account_balance_wallet},
    {'name': 'entertainment', 'icon': Icons.movie},
    {'name': 'sports', 'icon': Icons.sports_soccer},
    {'name': 'food', 'icon': Icons.restaurant},
    {'name': 'star', 'icon': Icons.star},
    {'name': 'today', 'icon': Icons.today},
  ];

  final List<int> _colors = [
    0xFF0078D4, // Microsoft Blue
    0xFF107C10, // Green
    0xFFD83B01, // Orange
    0xFF881798, // Purple
    0xFFE74856, // Red
    0xFF0099BC, // Teal
    0xFF8764B8, // Light Purple
    0xFF00BCF2, // Light Blue
    0xFFFF8C00, // Dark Orange
    0xFF8CBF3F, // Lime Green
    0xFFE81123, // Bright Red
    0xFF0078A3, // Dark Blue
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createList() {
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'icon': _selectedIcon,
      'color': _selectedColor,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Create New List',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List name input
            TextField(
              controller: _nameController,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'List name',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                hintText: 'Enter list name',
                hintStyle: TextStyle(color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.surfaceDarker,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
              ),
              autofocus: true,
              onSubmitted: (_) => _createList(),
            ),
            
            const SizedBox(height: 24),
            
            // Icon selection
            Text(
              'Choose an icon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((iconData) {
                final isSelected = _selectedIcon == iconData['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = iconData['name'];
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Color(_selectedColor)
                          : AppTheme.surfaceDarker,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? Color(_selectedColor)
                            : AppTheme.borderDark,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      iconData['icon'],
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Color selection
            Text(
              'Choose a color',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.textPrimary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createList,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
} 