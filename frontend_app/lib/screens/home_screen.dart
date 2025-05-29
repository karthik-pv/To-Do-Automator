import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/task_list.dart';
import 'task_list_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1E1E1E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1E1E),
            elevation: 0,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0078D4),
                  radius: 16,
                  child: Text(
                    appProvider.currentUser?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF808080),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        appProvider.currentUser ?? 'User',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: appProvider.isLoading ? null : () async {
                  await appProvider.refreshData();
                },
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  _showSearchDialog(context, appProvider);
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: const Color(0xFF2D2D2D),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await appProvider.logout();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text('Sign Out', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Text(
                      'Lists',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    if (appProvider.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0078D4)),
                        ),
                      ),
                  ],
                ),
              ),

              // Lists
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: appProvider.taskLists.isEmpty && !appProvider.isLoading
                      ? _buildEmptyState(context, appProvider)
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: appProvider.taskLists.length + 1, // +1 for add button
                          itemBuilder: (context, index) {
                            if (index == appProvider.taskLists.length) {
                              return _buildAddListCard(context, appProvider);
                            }
                            
                            final taskList = appProvider.taskLists[index];
                            final taskCount = appProvider.getTaskCountForList(taskList.id);
                            
                            return _buildListCard(
                              context,
                              taskList,
                              taskCount,
                              appProvider,
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListCard(
    BuildContext context,
    TaskList taskList,
    int taskCount,
    AppProvider appProvider,
  ) {
    return Card(
      color: const Color(0xFF2D2D2D),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF404040), width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TaskListScreen(taskList: taskList),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: taskList.iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      taskList.icon,
                      color: taskList.iconColor,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (!taskList.isDefault)
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Color(0xFF808080),
                        size: 20,
                      ),
                      color: const Color(0xFF2D2D2D),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await _showDeleteConfirmation(context, taskList, appProvider);
                        }
                      },
                      itemBuilder: (context) => [
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
              const Spacer(),
              Text(
                taskList.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                taskCount == 1 ? '$taskCount task' : '$taskCount tasks',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF808080),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddListCard(BuildContext context, AppProvider appProvider) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF0078D4).withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: appProvider.isLoading ? null : () => _showAddListDialog(context, appProvider),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0078D4).withOpacity(0.1),
                const Color(0xFF0078D4).withOpacity(0.05),
              ],
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: Color(0xFF0078D4),
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'New List',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0078D4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, AppProvider appProvider) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Search Tasks',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Search term',
            labelStyle: TextStyle(color: Color(0xFF808080)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0078D4)),
            ),
          ),
          onSubmitted: (value) async {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop();
              final results = await appProvider.searchTasks(value.trim());
              _showSearchResults(context, results, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF808080)),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                final results = await appProvider.searchTasks(controller.text.trim());
                _showSearchResults(context, results, controller.text.trim());
              }
            },
            child: const Text(
              'Search',
              style: TextStyle(color: Color(0xFF0078D4)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(BuildContext context, List tasks, String searchTerm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text(
          'Search Results for "$searchTerm"',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: tasks.isEmpty 
            ? const Center(
                child: Text(
                  'No tasks found',
                  style: TextStyle(color: Color(0xFF808080)),
                ),
              )
            : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    title: Text(
                      task.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Due: ${task.dueDate?.toString().split(' ')[0] ?? 'No due date'}',
                      style: const TextStyle(color: Color(0xFF808080)),
                    ),
                    trailing: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: task.isCompleted ? Colors.green : const Color(0xFF808080),
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF0078D4)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddListDialog(BuildContext context, AppProvider appProvider) {
    final controller = TextEditingController();
    IconData selectedIcon = Icons.list;
    Color selectedColor = const Color(0xFF0078D4);
    bool isLoading = false;
    
    final List<IconData> availableIcons = [
      Icons.list,
      Icons.work_outline,
      Icons.shopping_cart,
      Icons.home_outlined,
      Icons.school_outlined,
      Icons.fitness_center_outlined,
      Icons.favorite_border,
      Icons.local_grocery_store_outlined,
    ];

    final List<Color> availableColors = [
      const Color(0xFF0078D4),
      const Color(0xFFFFB900),
      const Color(0xFF10893E),
      const Color(0xFFD13438),
      const Color(0xFF881798),
      const Color(0xFF00B7C3),
      const Color(0xFF8764B8),
      const Color(0xFF00B294),
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Text(
            'New List',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'List name',
                  labelStyle: TextStyle(color: Color(0xFF808080)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF404040)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0078D4)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose an icon',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: availableIcons.map((icon) {
                  return GestureDetector(
                    onTap: isLoading ? null : () {
                      setState(() {
                        selectedIcon = icon;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedIcon == icon
                            ? selectedColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: selectedIcon == icon
                            ? Border.all(color: selectedColor)
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: selectedIcon == icon ? selectedColor : Colors.grey,
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose a color',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: availableColors.map((color) {
                  return GestureDetector(
                    onTap: isLoading ? null : () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF808080)),
              ),
            ),
            TextButton(
              onPressed: isLoading ? null : () async {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    isLoading = true;
                  });
                  
                  final success = await appProvider.addTaskList(
                    controller.text.trim(),
                    selectedIcon,
                    selectedColor,
                  );
                  
                  if (success) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to create list. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0078D4)),
                    ),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(color: Color(0xFF0078D4)),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    TaskList taskList,
    AppProvider appProvider,
  ) async {
    bool isLoading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Text(
            'Delete List',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${taskList.name}"? This will also delete all tasks in this list.',
            style: const TextStyle(color: Color(0xFF808080)),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF808080)),
              ),
            ),
            TextButton(
              onPressed: isLoading ? null : () async {
                setState(() {
                  isLoading = true;
                });
                
                final success = await appProvider.deleteTaskList(taskList.id);
                
                if (success) {
                  Navigator.of(context).pop();
                } else {
                  setState(() {
                    isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete list. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                : const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider appProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No lists found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: appProvider.isLoading ? null : () => _showAddListDialog(context, appProvider),
            child: const Text(
              'Add New List',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
} 