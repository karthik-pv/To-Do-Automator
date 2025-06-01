import 'package:flutter/material.dart';
import '../models/task_list.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_list_tile.dart';
import '../widgets/add_list_dialog.dart';
import 'login_screen.dart';
import 'task_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TaskList> _taskLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTaskLists();
  }

  Future<void> _loadTaskLists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lists = await ApiService.getTaskLists();
      
      // Check if default lists exist, if not create them
      final hasTasksList = lists.any((list) => list.name == 'Tasks' || list.id == 'my-tasks');
      final hasMyDayList = lists.any((list) => list.name == 'My Day' || list.id == 'my-day');
      
      List<TaskList> updatedLists = List.from(lists);
      
      // Create default "Tasks" list if it doesn't exist
      if (!hasTasksList) {
        final tasksListData = {
          'name': 'Tasks',
          'icon': 'list',
          'color': 0xFF0078D4,
          'isDefault': true,
        };
        
        final tasksList = await ApiService.createTaskList(
          tasksListData['name'] as String,
          tasksListData['icon'] as String,
          tasksListData['color'] as int,
          isDefault: true,
        );
        
        if (tasksList != null) {
          updatedLists.add(tasksList);
        }
      }
      
      // Create default "My Day" list if it doesn't exist
      if (!hasMyDayList) {
        final myDayListData = {
          'name': 'My Day',
          'icon': 'wb_sunny',
          'color': 0xFF107C10,
          'isDefault': true,
        };
        
        final myDayList = await ApiService.createTaskList(
          myDayListData['name'] as String,
          myDayListData['icon'] as String,
          myDayListData['color'] as int,
          isDefault: true,
        );
        
        if (myDayList != null) {
          updatedLists.add(myDayList);
        }
      }
      
      // Sort lists to put default lists first
      updatedLists.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        if (a.name == 'Tasks') return -1;
        if (b.name == 'Tasks') return 1;
        if (a.name == 'My Day') return -1;
        if (b.name == 'My Day') return 1;
        return a.name.compareTo(b.name);
      });
      
      setState(() {
        _taskLists = updatedLists;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading task lists: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await ApiService.clearUserId();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _addNewList() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddListDialog(),
    );

    if (result != null) {
      final newList = await ApiService.createTaskList(
        result['name'],
        result['icon'],
        result['color'],
      );

      if (newList != null) {
        setState(() {
          _taskLists.add(newList);
        });
      }
    }
  }

  Future<void> _deleteList(TaskList taskList) async {
    if (taskList.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default lists cannot be deleted'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "${taskList.name}"? This will also delete all tasks in this list.'),
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
      final success = await ApiService.deleteTaskList(taskList.id);
      if (success) {
        setState(() {
          _taskLists.removeWhere((list) => list.id == taskList.id);
        });
      }
    }
  }

  void _openTaskList(TaskList taskList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskListScreen(taskList: taskList),
      ),
    ).then((wasDeleted) {
      _loadTaskLists();
      if (wasDeleted == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${taskList.name} was deleted'),
            backgroundColor: AppTheme.completedGreen,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To Do'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTaskLists,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign out'),
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
              onRefresh: _loadTaskLists,
              child: _taskLists.isEmpty
                  ? _buildEmptyState()
                  : _buildTaskListView(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewList,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No lists yet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first list to get started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewList,
            icon: const Icon(Icons.add),
            label: const Text('Create List'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _taskLists.length,
        itemBuilder: (context, index) {
          final taskList = _taskLists[index];
          return TaskListTile(
            taskList: taskList,
            onTap: () => _openTaskList(taskList),
          );
        },
      ),
    );
  }
} 