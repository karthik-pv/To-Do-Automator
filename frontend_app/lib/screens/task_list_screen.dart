import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_detail_dialog.dart';
import '../widgets/add_to_list_dialog.dart';

class TaskListScreen extends StatefulWidget {
  final TaskList taskList;

  const TaskListScreen({super.key, required this.taskList});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  
  // Multi-select state
  bool _isSelectionMode = false;
  Set<String> _selectedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Task> tasks;
      if (widget.taskList.name == 'Important' && widget.taskList.isDefault) {
        // For Important list, fetch all important tasks
        tasks = await ApiService.getImportantTasks();
      } else {
        // For regular lists, fetch tasks by list ID
        tasks = await ApiService.getTasks(listId: widget.taskList.id);
      }
      
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask(String title) async {
    if (title.trim().isEmpty) return;

    final newTask = await ApiService.createTask(
      title.trim(),
      widget.taskList.id,
    );

    if (newTask != null) {
      setState(() {
        _tasks.insert(0, newTask);
      });
    }
  }

  Future<void> _showAddTaskDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddTaskDialog(listId: widget.taskList.id),
    );

    if (result != null) {
      final newTask = await ApiService.createTask(
        result['title'],
        widget.taskList.id,
        note: result['notes'],
      );

      if (newTask != null) {
        setState(() {
          _tasks.insert(0, newTask);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${result['title']}" added successfully'),
            backgroundColor: AppTheme.completedGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    final success = await ApiService.toggleTaskCompletion(
      task.id,
      !task.isCompleted,
    );

    if (success) {
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
        }
      });
    }
  }

  Future<void> _toggleTaskImportance(Task task) async {
    final success = await ApiService.toggleTaskImportance(
      task.id,
      !task.isImportant,
    );

    if (success) {
      setState(() {
        if (widget.taskList.name == 'Important' && widget.taskList.isDefault) {
          if (!task.isImportant) {
            // Task was marked as not important, remove from Important list
            _tasks.removeWhere((t) => t.id == task.id);
          } else {
            // Task was marked as important, update it
            final index = _tasks.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              _tasks[index] = task.copyWith(isImportant: !task.isImportant);
            }
          }
        } else {
          // For regular lists, just update the task
          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            _tasks[index] = task.copyWith(isImportant: !task.isImportant);
          }
        }
      });
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.deleteTask(task.id);
      if (success) {
        setState(() {
          _tasks.removeWhere((t) => t.id == task.id);
        });
      }
    }
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDetailDialog(
        task: task,
        onUpdate: (updatedTask) {
          setState(() {
            if (widget.taskList.name == 'Important' && widget.taskList.isDefault) {
              if (updatedTask.isImportant) {
                // Task is still important, update it
                final index = _tasks.indexWhere((t) => t.id == task.id);
                if (index != -1) {
                  _tasks[index] = updatedTask;
                }
              } else {
                // Task is no longer important, remove from Important list
                _tasks.removeWhere((t) => t.id == task.id);
              }
            } else {
              // For regular lists, just update the task
              final index = _tasks.indexWhere((t) => t.id == task.id);
              if (index != -1) {
                _tasks[index] = updatedTask;
              }
            }
          });
        },
        onDelete: () {
          setState(() {
            _tasks.removeWhere((t) => t.id == task.id);
          });
        },
      ),
    );
  }

  Future<void> _deleteList() async {
    if (widget.taskList.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Default lists cannot be deleted'),
          backgroundColor: AppTheme.warningRed,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text(
          'Are you sure you want to delete "${widget.taskList.name}"?\n\nThis will permanently delete the list and all tasks in it. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final success = await ApiService.deleteTaskList(widget.taskList.id);
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.taskList.name} deleted successfully'),
                backgroundColor: AppTheme.completedGreen,
              ),
            );
            Navigator.pop(context, true); // Return to home with refresh signal
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to delete list'),
                backgroundColor: AppTheme.warningRed,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('An error occurred while deleting the list'),
              backgroundColor: AppTheme.warningRed,
            ),
          );
        }
      }
    }
  }

  void _enterSelectionMode(String taskId) {
    setState(() {
      _isSelectionMode = true;
      _selectedTaskIds.add(taskId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTaskIds.clear();
    });
  }

  void _toggleTaskSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _selectAllTasks() {
    setState(() {
      _selectedTaskIds.addAll(_tasks.map((task) => task.id));
    });
  }

  void _deselectAllTasks() {
    setState(() {
      _selectedTaskIds.clear();
    });
  }

  Future<void> _deleteSelectedTasks() async {
    if (_selectedTaskIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tasks'),
        content: Text(
          'Are you sure you want to delete ${_selectedTaskIds.length} task${_selectedTaskIds.length == 1 ? '' : 's'}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final taskIdsToDelete = _selectedTaskIds.toList();
      final deletedCount = await ApiService.deleteMultipleTasks(taskIdsToDelete);
      
      if (deletedCount > 0) {
        setState(() {
          _tasks.removeWhere((task) => taskIdsToDelete.contains(task.id));
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deletedCount task${deletedCount == 1 ? '' : 's'} deleted'),
            backgroundColor: AppTheme.completedGreen,
          ),
        );
      }
      
      _exitSelectionMode();
    }
  }

  Future<void> _addTasksToLists() async {
    if (_selectedTaskIds.isEmpty) return;

    final taskLists = await ApiService.getTaskLists();
    final availableLists = taskLists.where((list) => 
      list.id != widget.taskList.id && 
      !(list.name == 'Important' && list.isDefault)
    ).toList();

    if (availableLists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other lists available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedListIds = await showDialog<List<String>>(
      context: context,
      builder: (context) => AddToListDialog(lists: availableLists),
    );

    if (selectedListIds != null && selectedListIds.isNotEmpty) {
      final success = await ApiService.addTasksToLists(
        _selectedTaskIds.toList(),
        selectedListIds,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tasks added to ${selectedListIds.length} list${selectedListIds.length == 1 ? '' : 's'}'),
            backgroundColor: AppTheme.completedGreen,
          ),
        );
      }
      
      _exitSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = _tasks.where((task) => task.isCompleted).toList();
    final incompleteTasks = _tasks.where((task) => !task.isCompleted).toList();
    final isImportantList = widget.taskList.name == 'Important' && widget.taskList.isDefault;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
          ? Text('${_selectedTaskIds.length} selected')
          : Text(widget.taskList.name),
        leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitSelectionMode,
            )
          : null,
        actions: _isSelectionMode
          ? [
              if (_selectedTaskIds.length != _tasks.length)
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAllTasks,
                  tooltip: 'Select All',
                ),
              if (_selectedTaskIds.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.deselect),
                  onPressed: _deselectAllTasks,
                  tooltip: 'Deselect All',
                ),
              IconButton(
                icon: const Icon(Icons.playlist_add),
                onPressed: _selectedTaskIds.isNotEmpty ? _addTasksToLists : null,
                tooltip: 'Add to List',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _selectedTaskIds.isNotEmpty ? _deleteSelectedTasks : null,
                tooltip: 'Delete Selected',
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadTasks,
              ),
              if (!widget.taskList.isDefault)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteList();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete List'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: _tasks.isEmpty
                  ? _buildEmptyState()
                  : _buildTaskList(incompleteTasks, completedTasks),
            ),
      floatingActionButton: !_isSelectionMode && !isImportantList
          ? FloatingActionButton(
              onPressed: _showAddTaskDialog,
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              tooltip: 'Add Task',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    final isImportantList = widget.taskList.name == 'Important' && widget.taskList.isDefault;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isImportantList ? Icons.star_border : Icons.task_alt,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            isImportantList ? 'No important tasks' : 'No tasks yet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isImportantList 
              ? 'Mark tasks as important to see them here'
              : 'Add your first task to get started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> incompleteTasks, List<Task> completedTasks) {
    return ListView(
      children: [
        // Incomplete tasks
        ...incompleteTasks.map((task) => _buildSelectableTaskTile(task)),

        // Completed tasks section
        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.completedGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Completed (${completedTasks.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.completedGreen,
                  ),
                ),
              ],
            ),
          ),
          ...completedTasks.map((task) => _buildSelectableTaskTile(task)),
        ],

        const SizedBox(height: 80), // Extra space at bottom
      ],
    );
  }

  Widget _buildSelectableTaskTile(Task task) {
    final isSelected = _selectedTaskIds.contains(task.id);
    
    return Container(
      decoration: _isSelectionMode && isSelected
          ? BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              border: Border.all(color: AppTheme.primaryBlue, width: 2),
            )
          : null,
      child: TaskTile(
        task: task,
        isSelected: _isSelectionMode ? isSelected : null,
        onTap: _isSelectionMode
            ? () => _toggleTaskSelection(task.id)
            : () => _showTaskDetails(task),
        onLongPress: _isSelectionMode 
            ? null 
            : () => _enterSelectionMode(task.id),
        onToggleComplete: _isSelectionMode 
            ? null 
            : () => _toggleTaskCompletion(task),
        onToggleImportant: _isSelectionMode 
            ? null 
            : () => _toggleTaskImportance(task),
        onDelete: _isSelectionMode 
            ? null 
            : () => _deleteTask(task),
      ),
    );
  }
}