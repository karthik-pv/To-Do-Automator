import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/task_list.dart';
import '../models/task.dart';

class TaskListScreen extends StatefulWidget {
  final TaskList taskList;

  const TaskListScreen({
    super.key,
    required this.taskList,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _taskController = TextEditingController();
  bool _isAddingTask = false;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final tasks = appProvider.getTasksForList(widget.taskList.id);
        final activeTasks = tasks.where((task) => !task.isCompleted).toList();
        final completedTasks = tasks.where((task) => task.isCompleted).toList();

    return Scaffold(
          backgroundColor: const Color(0xFF1E1E1E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1E1E),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.taskList.iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    widget.taskList.icon,
                    color: widget.taskList.iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.taskList.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  // TODO: Add more options
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Header with task count
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.taskList.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (tasks.isNotEmpty)
                      Text(
                        '${activeTasks.length} active, ${completedTasks.length} completed',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF808080),
                        ),
                      ),
                  ],
                ),
              ),

              // Add task input
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isAddingTask
                        ? const Color(0xFF0078D4)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: _isAddingTask
                          ? const Color(0xFF0078D4)
                          : const Color(0xFF808080),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Add a task',
                          hintStyle: TextStyle(color: Color(0xFF808080)),
                          border: InputBorder.none,
                        ),
            onTap: () {
                          setState(() {
                            _isAddingTask = true;
                          });
                        },
                        onSubmitted: (value) {
                          _addTask(appProvider, value);
                        },
                      ),
                    ),
                    if (_isAddingTask) ...[
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Color(0xFF0078D4),
                          size: 20,
                        ),
                        onPressed: () {
                          _addTask(appProvider, _taskController.text);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFF808080),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isAddingTask = false;
                            _taskController.clear();
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tasks list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Active tasks
                    ...activeTasks.map((task) => _buildTaskItem(task, appProvider)),

                    // Completed tasks section
                    if (completedTasks.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildCompletedHeader(completedTasks.length),
                      const SizedBox(height: 12),
                      ...completedTasks.map((task) => _buildTaskItem(task, appProvider)),
                    ],

                    // Empty state
                    if (tasks.isEmpty)
                      _buildEmptyState(),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(Task task, AppProvider appProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? const Color(0xFF2D2D2D).withOpacity(0.7)
            : const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF404040), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // TODO: Show task details
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () {
                    appProvider.toggleTaskCompletion(task.id);
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? const Color(0xFF0078D4)
                            : const Color(0xFF808080),
                        width: 2,
                      ),
                      color: task.isCompleted
                          ? const Color(0xFF0078D4)
                          : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                ),

                const SizedBox(width: 16),

                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          color: task.isCompleted
                              ? const Color(0xFF808080)
                              : Colors.white,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: const Color(0xFF808080),
                        ),
                      ),
                      if (task.note != null && task.note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.note!,
                          style: TextStyle(
                            fontSize: 14,
                            color: task.isCompleted
                                ? const Color(0xFF606060)
                                : const Color(0xFF808080),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (task.dueDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: task.isCompleted
                                  ? const Color(0xFF606060)
                                  : const Color(0xFF808080),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(task.dueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                color: task.isCompleted
                                    ? const Color(0xFF606060)
                                    : const Color(0xFF808080),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Important star
                if (task.isImportant)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.star,
                      color: task.isCompleted
                          ? const Color(0xFF606060)
                          : const Color(0xFFFFB900),
                      size: 20,
                    ),
                  ),

                // More options
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    color: task.isCompleted
                        ? const Color(0xFF606060)
                        : const Color(0xFF808080),
                    size: 20,
                  ),
                  color: const Color(0xFF2D2D2D),
                  onSelected: (value) {
                    switch (value) {
                      case 'important':
                        appProvider.updateTask(task.copyWith(
                          isImportant: !task.isImportant,
                        ));
                        break;
                      case 'delete':
                        appProvider.deleteTask(task.id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'important',
                      child: Row(
                        children: [
                          Icon(
                            task.isImportant ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFB900),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            task.isImportant
                                ? 'Remove from Important'
                                : 'Mark as Important',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedHeader(int count) {
    return Row(
      children: [
        const Icon(
          Icons.keyboard_arrow_down,
          color: Color(0xFF808080),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Completed ($count)',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF808080),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.taskList.iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.taskList.icon,
              size: 48,
              color: widget.taskList.iconColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF808080),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a task to get started',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF606060),
            ),
          ),
        ],
      ),
    );
  }

  void _addTask(AppProvider appProvider, String title) {
    if (title.trim().isNotEmpty) {
      appProvider.addTask(
        title.trim(),
        widget.taskList.id,
      );
      _taskController.clear();
      setState(() {
        _isAddingTask = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 