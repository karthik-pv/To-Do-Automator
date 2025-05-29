import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/task_list.dart';

class AppProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<TaskList> _taskLists = [];
  bool _isLoggedIn = false;
  String? _currentUser;
  final Uuid _uuid = const Uuid();

  List<Task> get tasks => _tasks;
  List<TaskList> get taskLists => _taskLists;
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUser => _currentUser;

  AppProvider() {
    _initializeDefaultLists();
  }

  // Public method to load data
  Future<void> loadData() async {
    await _loadData();
  }

  void _initializeDefaultLists() {
    _taskLists = [
      TaskList(
        id: 'my-day',
        name: 'My Day',
        icon: Icons.wb_sunny_outlined,
        iconColor: const Color(0xFFFFB900),
        isDefault: true,
        createdAt: DateTime.now(),
      ),
      TaskList(
        id: 'my-tasks',
        name: 'My Tasks',
        icon: Icons.home_outlined,
        iconColor: const Color(0xFF0078D4),
        isDefault: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  // Authentication
  Future<bool> login(String username, String password) async {
    // Simple authentication - in real app, this would connect to a backend
    if (username.isNotEmpty && password.isNotEmpty) {
      _isLoggedIn = true;
      _currentUser = username;
      await _saveLoginState();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUser = null;
    await _clearLoginState();
    notifyListeners();
  }

  // Task Management
  void addTask(String title, String listId) {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      listId: listId,
      createdAt: DateTime.now(),
    );
    _tasks.add(task);
    _saveData();
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        isCompleted: !_tasks[taskIndex].isCompleted,
      );
      _saveData();
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    _saveData();
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final taskIndex = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (taskIndex != -1) {
      _tasks[taskIndex] = updatedTask;
      _saveData();
      notifyListeners();
    }
  }

  List<Task> getTasksForList(String listId) {
    if (listId == 'my-day') {
      // For "My Day", show tasks that are due today or marked for today
      final today = DateTime.now();
      return _tasks.where((task) {
        if (task.dueDate != null) {
          return task.dueDate!.day == today.day &&
                 task.dueDate!.month == today.month &&
                 task.dueDate!.year == today.year;
        }
        return false;
      }).toList();
    }
    return _tasks.where((task) => task.listId == listId).toList();
  }

  // List Management
  void addTaskList(String name, IconData icon, Color iconColor) {
    final taskList = TaskList(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      iconColor: iconColor,
      createdAt: DateTime.now(),
    );
    _taskLists.add(taskList);
    _saveData();
    notifyListeners();
  }

  void deleteTaskList(String listId) {
    // Don't delete default lists
    final list = _taskLists.firstWhere((list) => list.id == listId);
    if (!list.isDefault) {
      _taskLists.removeWhere((list) => list.id == listId);
      // Also delete all tasks in this list
      _tasks.removeWhere((task) => task.listId == listId);
      _saveData();
      notifyListeners();
    }
  }

  int getTaskCountForList(String listId) {
    return getTasksForList(listId).where((task) => !task.isCompleted).length;
  }

  // Data Persistence
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load login state
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _currentUser = prefs.getString('currentUser');

    // Load tasks
    final tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      final List<dynamic> tasksList = jsonDecode(tasksJson);
      _tasks = tasksList.map((json) => Task.fromJson(json)).toList();
    }

    // Load custom task lists (default ones are already initialized)
    final listsJson = prefs.getString('taskLists');
    if (listsJson != null) {
      final List<dynamic> listsList = jsonDecode(listsJson);
      final customLists = listsList.map((json) => TaskList.fromJson(json)).toList();
      // Add custom lists to default ones
      _taskLists.addAll(customLists.where((list) => !list.isDefault));
    }

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save tasks
    final tasksJson = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks', tasksJson);

    // Save custom lists only (default ones are hardcoded)
    final customLists = _taskLists.where((list) => !list.isDefault).toList();
    final listsJson = jsonEncode(customLists.map((list) => list.toJson()).toList());
    await prefs.setString('taskLists', listsJson);
  }

  Future<void> _saveLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', _isLoggedIn);
    if (_currentUser != null) {
      await prefs.setString('currentUser', _currentUser!);
    }
  }

  Future<void> _clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('currentUser');
  }
} 