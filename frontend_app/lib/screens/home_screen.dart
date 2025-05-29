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
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  // TODO: Implement search
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
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Lists',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // Lists
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
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
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmation(context, taskList, appProvider);
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
        onTap: () => _showAddListDialog(context, appProvider),
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

  void _showAddListDialog(BuildContext context, AppProvider appProvider) {
    final controller = TextEditingController();
    IconData selectedIcon = Icons.list;
    Color selectedColor = const Color(0xFF0078D4);
    
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
                    onTap: () {
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
                    onTap: () {
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF808080)),
              ),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  appProvider.addTaskList(
                    controller.text.trim(),
                    selectedIcon,
                    selectedColor,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Create',
                style: TextStyle(color: Color(0xFF0078D4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    TaskList taskList,
    AppProvider appProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF808080)),
            ),
          ),
          TextButton(
            onPressed: () {
              appProvider.deleteTaskList(taskList.id);
              Navigator.of(context).pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 