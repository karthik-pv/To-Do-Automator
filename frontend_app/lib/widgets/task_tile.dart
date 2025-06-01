import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onToggleImportant;
  final VoidCallback? onDelete;
  final bool? isSelected;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    this.onLongPress,
    this.onToggleComplete,
    this.onToggleImportant,
    this.onDelete,
    this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final showSelectionCheckbox = isSelected != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: task.isCompleted 
              ? AppTheme.completedGreen.withOpacity(0.3)
              : AppTheme.borderDark,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Selection checkbox (in selection mode) or completion checkbox
                GestureDetector(
                  onTap: showSelectionCheckbox ? onTap : onToggleComplete,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: showSelectionCheckbox ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: showSelectionCheckbox ? BorderRadius.circular(4) : null,
                      border: Border.all(
                        color: showSelectionCheckbox 
                            ? (isSelected == true ? AppTheme.primaryBlue : AppTheme.borderDark)
                            : (task.isCompleted ? AppTheme.completedGreen : AppTheme.borderDark),
                        width: 2,
                      ),
                      color: showSelectionCheckbox
                          ? (isSelected == true ? AppTheme.primaryBlue : Colors.transparent)
                          : (task.isCompleted ? AppTheme.completedGreen : Colors.transparent),
                    ),
                    child: showSelectionCheckbox
                        ? (isSelected == true
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null)
                        : (task.isCompleted
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task title
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          decoration: task.isCompleted 
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted 
                              ? AppTheme.textTertiary
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Task note and due date
                      if (task.note != null || task.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (task.note != null && task.note !="null" && task.note !='0' && task.note!='') ...[
                              Icon(
                                Icons.note,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task.note!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (task.dueDate != null) ...[
                              if (task.note != null) const SizedBox(width: 8),
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: _getDueDateColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDueDate(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _getDueDateColor(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                if (!showSelectionCheckbox) ...[
                  const SizedBox(width: 8),
                  
                  // Important star
                  GestureDetector(
                    onTap: onToggleImportant,
                    child: Icon(
                      task.isImportant ? Icons.star : Icons.star_border,
                      color: task.isImportant 
                          ? AppTheme.importantOrange 
                          : AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  // More options
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'delete':
                          onDelete?.call();
                          break;
                        case 'toggle_important':
                          onToggleImportant?.call();
                          break;
                        case 'toggle_complete':
                          onToggleComplete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle_complete',
                        child: Row(
                          children: [
                            Icon(
                              task.isCompleted ? Icons.radio_button_unchecked : Icons.check_circle,
                              color: AppTheme.completedGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              task.isCompleted ? 'Mark incomplete' : 'Mark complete',
                              style: TextStyle(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_important',
                        child: Row(
                          children: [
                            Icon(
                              task.isImportant ? Icons.star_border : Icons.star,
                              color: AppTheme.importantOrange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              task.isImportant ? 'Remove importance' : 'Mark important',
                              style: TextStyle(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDueDateColor() {
    if (task.dueDate == null) return AppTheme.textSecondary;
    
    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (dueDateOnly.isBefore(today)) {
      return AppTheme.warningRed; // Overdue
    } else if (dueDateOnly.isAtSameMomentAs(today)) {
      return AppTheme.importantOrange; // Due today
    } else {
      return AppTheme.textSecondary; // Future
    }
  }

  String _formatDueDate() {
    if (task.dueDate == null) return '';
    
    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (dueDateOnly.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (dueDateOnly.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else if (dueDateOnly.isBefore(today.add(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(dueDate); // Day of week
    } else {
      return DateFormat('MMM d').format(dueDate); // Month and day
    }
  }
} 