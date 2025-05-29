import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<TaskList> _taskLists = [];
  bool _isLoggedIn = false;
  String? _currentUser;
  String? _userId;
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  List<TaskList> get taskLists => _taskLists;
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUser => _currentUser;
  String? get userId => _userId;
  bool get isLoading => _isLoading;

  AppProvider() {
    // Don't initialize any default lists - they should only come from backend
    // _initializeDefaultLists(); // REMOVED - only load after authentication
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Public method to load data
  Future<void> loadData() async {
    await _loadLoginState();
    if (_isLoggedIn && _userId != null) {
      ApiService.setUserId(_userId!);
      try {
        await _loadDataFromApi();
      } catch (e) {
        print('Failed to load data from API on startup: $e');
        // Don't logout on startup failures - user should stay logged in
        // Just show empty state until network/backend is available
        _tasks = [];
        _taskLists = [];
        notifyListeners();
      }
    } else {
      // Clear any existing data if not logged in
      _tasks = [];
      _taskLists = [];
      notifyListeners();
    }
  }

  Future<void> _loadDataFromApi() async {
    _setLoading(true);
    try {
      // First verify that we can connect to the backend with current user ID
      if (_userId == null) {
        throw Exception('No user ID available');
      }

      // Test connection by getting task lists from API only
      _taskLists = await ApiService.getTaskLists();
      
      // Load all tasks from API
      _tasks = await ApiService.getTasks();
      
      print('Successfully loaded ${_taskLists.length} lists and ${_tasks.length} tasks from API');
      
    } catch (e) {
      print('Error loading data from API: $e');
      // Only logout if it's specifically an authentication error (401)
      if (e.toString().contains('401') || e.toString().contains('Authentication failed')) {
        print('Authentication error detected - logging out user');
        await _handleAuthenticationFailure();
      }
      throw e; // Re-throw to let caller handle
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleAuthenticationFailure() async {
    print('Authentication failed - logging out user');
    _isLoggedIn = false;
    _currentUser = null;
    _userId = null;
    _tasks = [];
    _taskLists = [];
    ApiService.clearUserId();
    await _clearLoginState();
    notifyListeners();
  }

  // Authentication
  Future<Map<String, dynamic>> register(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return {'success': false, 'message': 'Email and password are required'};
    }

    _setLoading(true);
    try {
      final result = await ApiService.register(email, password);
      
      if (result != null && result['success'] == true) {
        _isLoggedIn = true;
        _currentUser = email;
        _userId = result['userId'];
        
        if (_userId == null || _userId!.isEmpty) {
          throw Exception('Invalid user ID received from server');
        }
        
        ApiService.setUserId(_userId!);
        await _saveLoginState();
        
        print('Registration successful - User ID: $_userId, Email: $_currentUser');
        
        // Try to load data after registration - but don't logout on network failures
        try {
          await _loadDataFromApi();
        } catch (e) {
          print('Warning: Failed to load user data after registration: $e');
          // Don't logout on data loading failures during registration
          // The user is successfully registered, just show empty state
          _tasks = [];
          _taskLists = [];
        }
        
        notifyListeners();
        return {'success': true, 'message': result['message'] ?? 'Registration successful'};
      } else {
        return {'success': false, 'message': result?['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      print('Registration error: $e');
      // Only clear auth state if it's actually an authentication failure
      if (e.toString().contains('401') || e.toString().contains('User already exists')) {
        await _handleAuthenticationFailure();
      }
      return {'success': false, 'message': 'Network error: Unable to connect to server'};
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return {'success': false, 'message': 'Email and password are required'};
    }

    _setLoading(true);
    try {
      final result = await ApiService.login(email, password);
      
      if (result != null && result['success'] == true) {
        _isLoggedIn = true;
        _currentUser = result['email'];
        _userId = result['userId'];
        
        if (_userId == null || _userId!.isEmpty) {
          throw Exception('Invalid user ID received from server');
        }
        
        ApiService.setUserId(_userId!);
        await _saveLoginState();
        
        print('Login successful - User ID: $_userId, Email: $_currentUser');
        
        // Try to load data after login - but don't logout on network failures
        try {
          await _loadDataFromApi();
        } catch (e) {
          print('Warning: Failed to load user data after login: $e');
          // Don't logout on data loading failures during login
          // The user is successfully authenticated, just show empty state
          _tasks = [];
          _taskLists = [];
        }
        
        notifyListeners();
        return {'success': true, 'message': result['message'] ?? 'Login successful'};
      } else {
        return {'success': false, 'message': result?['message'] ?? 'Invalid credentials'};
      }
    } catch (e) {
      print('Login error: $e');
      // Only clear auth state if it's actually an authentication failure
      if (e.toString().contains('401') || e.toString().contains('Invalid email or password')) {
        await _handleAuthenticationFailure();
      }
      return {'success': false, 'message': 'Network error: Unable to connect to server'};
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUser = null;
    _userId = null;
    _tasks = [];
    _taskLists = []; // Clear all lists on logout
    ApiService.clearUserId();
    await _clearLoginState();
    notifyListeners();
  }

  // Task Management - all require authentication
  Future<bool> addTask(String title, String listId) async {
    if (!_isLoggedIn || _userId == null) {
      print('Cannot add task: User not authenticated');
      return false;
    }

    try {
      final task = Task(
        id: '', // Will be set by backend
        title: title,
        listId: listId,
        createdAt: DateTime.now(),
      );
      
      final taskId = await ApiService.createTask(task);
      if (taskId != null) {
        // Add the task with the returned ID to local list
        final newTask = task.copyWith(id: taskId);
        _tasks.add(newTask);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding task: $e');
      // Check if it's an authentication error
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        await _handleAuthenticationFailure();
      }
      return false;
    }
  }

  Future<bool> toggleTaskCompletion(String taskId) async {
    if (!_isLoggedIn || _userId == null) {
      print('Cannot toggle task: User not authenticated');
      return false;
    }

    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final currentTask = _tasks[taskIndex];
        final newStatus = !currentTask.isCompleted;
        
        final success = await ApiService.markTaskCompleted(taskId, newStatus);
        if (success) {
          _tasks[taskIndex] = currentTask.copyWith(isCompleted: newStatus);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error toggling task completion: $e');
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        await _handleAuthenticationFailure();
      }
      return false;
    }
  }

  Future<bool> toggleTaskImportance(String taskId) async {
    if (!_isLoggedIn || _userId == null) {
      print('Cannot toggle task importance: User not authenticated');
      return false;
    }

    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final currentTask = _tasks[taskIndex];
        final newStatus = !currentTask.isImportant;
        
        final success = await ApiService.markTaskImportant(taskId, newStatus);
        if (success) {
          _tasks[taskIndex] = currentTask.copyWith(isImportant: newStatus);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error toggling task importance: $e');
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        await _handleAuthenticationFailure();
      }
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    if (!_isLoggedIn || _userId == null) {
      print('Cannot delete task: User not authenticated');
      return false;
    }

    try {
      final success = await ApiService.deleteTask(taskId);
      if (success) {
        _tasks.removeWhere((task) => task.id == taskId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting task: $e');
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        await _handleAuthenticationFailure();
      }
      return false;
    }
  }

  Future<bool> updateTask(Task updatedTask) async {
    if (!_isLoggedIn || _userId == null) {
      print('Cannot update task: User not authenticated');
      return false;
    }

    try {
      final taskData = updatedTask.toJson();
      taskData.remove('_id'); // Remove _id field for update
      
      final success = await ApiService.updateTask(updatedTask.id, taskData);
      if (success) {
        final taskIndex = _tasks.indexWhere((task) => task.id == updatedTask.id);
        if (taskIndex != -1) {
          _tasks[taskIndex] = updatedTask;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating task: $e');
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        await _handleAuthenticationFailure();
      }
      return false;
    }
  }

  List<Task> getTasksForList(String listId) {
    if (!_isLoggedIn) {
      return []; // Return empty list if not logged in
    }

    // Check if it's a special list by name instead of hardcoded IDs
    final list = _taskLists.firstWhere(
      (list) => list.id == listId, 
      orElse: () => TaskList(id: '', name: '', icon: Icons.list, iconColor: Colors.grey, createdAt: DateTime.now())
    );
    
    if (list.id.isEmpty) {
      return []; // List not found
    }
    
    // Handle special lists by name
    if (list.name.toLowerCase() == 'my day') {
      // For "My Day", show tasks that are due today or manually added to My Day
      final today = DateTime.now();
      return _tasks.where((task) {
        // Either the task is assigned to this specific list, or it's due today
        if (task.listId == listId) return true;
        if (task.dueDate != null) {
          return task.dueDate!.day == today.day &&
                 task.dueDate!.month == today.month &&
                 task.dueDate!.year == today.year &&
                 !task.isCompleted;
        }
        return false;
      }).toList();
    } else if (list.name.toLowerCase() == 'important') {
      // For "Important", show all important tasks regardless of list
      return _tasks.where((task) => task.isImportant && !task.isCompleted).toList();
    } else if (list.name.toLowerCase() == 'completed') {
      // For "Completed", show all completed tasks regardless of list
      return _tasks.where((task) => task.isCompleted).toList();
    }
    
    // For regular lists, show tasks for that specific list (excluding completed)
    return _tasks.where((task) => task.listId == listId && !task.isCompleted).toList();
  }

  // List Management
  Future<bool> addTaskList(String name, IconData icon, Color iconColor) async {
    if (!_isLoggedIn || _userId == null) {
      print('Cannot add task list: User not authenticated');
      return false;
    }

    try {
      final taskList = TaskList(
        id: '', // Will be set by backend
        name: name,
        icon: icon,
        iconColor: iconColor,
        createdAt: DateTime.now(),
      );
      
      final listId = await ApiService.createTaskList(taskList);
      if (listId != null) {
        final newList = taskList.copyWith(id: listId);
        _taskLists.add(newList);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding task list: $e');
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        await _handleAuthenticationFailure();
      }
      return false;
    }
  }

  Future<bool> deleteTaskList(String listId) async {
    if (!_isLoggedIn || _userId == null) {
      print('Cannot delete task list: User not authenticated');
      return false;
    }

    try {
      // Don't delete default lists
      final list = _taskLists.firstWhere((list) => list.id == listId);
      if (!list.isDefault) {
        final success = await ApiService.deleteTaskList(listId);
        if (success) {
          _taskLists.removeWhere((list) => list.id == listId);
          // Remove tasks from local list as well (backend already deleted them)
          _tasks.removeWhere((task) => task.listId == listId);
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error deleting task list: $e');
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        await _handleAuthenticationFailure();
      }
      return false;
    }
  }

  int getTaskCountForList(String listId) {
    return getTasksForList(listId).length;
  }

  // Search functionality
  Future<List<Task>> searchTasks(String searchTerm) async {
    if (!_isLoggedIn || _userId == null) {
      print('Cannot search tasks: User not authenticated');
      return [];
    }

    try {
      return await ApiService.searchTasks(searchTerm);
    } catch (e) {
      print('Error searching tasks: $e');
      if (e.toString().contains('401') || e.toString().contains('authentication')) {
        await _handleAuthenticationFailure();
      }
      return [];
    }
  }

  // Refresh data from API
  Future<void> refreshData() async {
    if (_isLoggedIn && _userId != null) {
      await retryLoadData();
    }
  }

  // Data Persistence (login state and user info)
  Future<void> _loadLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _currentUser = prefs.getString('currentUser');
    _userId = prefs.getString('userId');
    
    print('Loading login state: isLoggedIn=$_isLoggedIn, user=$_currentUser, userId=$_userId');
    
    // Validate that we have all required data
    if (_isLoggedIn && (_currentUser == null || _userId == null)) {
      print('Invalid login state detected - clearing');
      await _clearLoginState();
      _isLoggedIn = false;
      _currentUser = null;
      _userId = null;
    }
    
    notifyListeners();
  }

  Future<void> _saveLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', _isLoggedIn);
    if (_currentUser != null) {
      await prefs.setString('currentUser', _currentUser!);
    }
    if (_userId != null) {
      await prefs.setString('userId', _userId!);
    }
    print('Saved login state: isLoggedIn=$_isLoggedIn, user=$_currentUser, userId=$_userId');
  }

  Future<void> _clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('currentUser');
    await prefs.remove('userId');
    print('Cleared login state');
  }

  // Method to manually retry loading data (useful for refresh button)
  Future<bool> retryLoadData() async {
    if (!_isLoggedIn || _userId == null) {
      print('Cannot retry load data: User not logged in');
      return false;
    }
    
    try {
      ApiService.setUserId(_userId!);
      await _loadDataFromApi();
      return true;
    } catch (e) {
      print('Retry load data failed: $e');
      return false;
    }
  }
} 