import 'package:flutter/material.dart';
import '../models/task_list.dart';
import '../theme/app_theme.dart';

class TaskListTile extends StatelessWidget {
  final TaskList taskList;
  final VoidCallback onTap;

  const TaskListTile({
    super.key,
    required this.taskList,
    required this.onTap,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'shopping':
        return Icons.shopping_cart;
      case 'family':
        return Icons.family_restroom;
      case 'travel':
        return Icons.flight;
      case 'health':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      case 'finance':
        return Icons.account_balance_wallet;
      case 'entertainment':
        return Icons.movie;
      case 'sports':
        return Icons.sports_soccer;
      case 'food':
        return Icons.restaurant;
      case 'star':
        return Icons.star;
      case 'today':
        return Icons.today;
      default:
        return Icons.list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and color indicator
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(taskList.iconColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getIconData(taskList.icon),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // List name
                  Expanded(
                    child: Text(
                      taskList.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                ],
              ),
            ),
            
            // Hover effect overlay
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  hoverColor: AppTheme.hoverGray.withOpacity(0.5),
                  splashColor: Color(taskList.iconColor).withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 