import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../models/task_list.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';
  static String? _userId;
  
  // Set user ID for authentication
  static void setUserId(String userId) {
    _userId = userId;
    print('ApiService: Set user ID to $_userId');
  }
  
  // Clear user ID on logout
  static void clearUserId() {
    print('ApiService: Clearing user ID (was $_userId)');
    _userId = null;
  }
  
  // Get headers with authentication
  static Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_userId != null) {
      headers['X-User-ID'] = _userId!;
      print('ApiService: Using authenticated headers with user ID $_userId');
    } else {
      print('ApiService: Using unauthenticated headers (no user ID)');
    }
    return headers;
  }
  
  // Helper method to handle API responses
  static Map<String, dynamic> _handleResponse(http.Response response, String operation) {
    if (response.statusCode == 401) {
      throw Exception('Authentication failed - please login again');
    }
    
    if (response.statusCode >= 500) {
      throw Exception('Server error - please try again later');
    }
    
    try {
      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      throw Exception('Invalid response from server during $operation');
    }
  }
  
  // Authentication API calls
  static Future<Map<String, dynamic>?> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: 10));
      
      final data = _handleResponse(response, 'registration');
      
      if (response.statusCode == 201 && data['success']) {
        return {
          'success': true,
          'userId': data['userId'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('Error registering user: $e');
      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'Connection timeout - please check your internet connection',
        };
      }
      return {
        'success': false,
        'message': 'Network error: Unable to connect to server',
      };
    }
  }
  
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: 10));
      
      final data = _handleResponse(response, 'login');
      
      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'userId': data['userId'],
          'email': data['email'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Error logging in: $e');
      if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'Connection timeout - please check your internet connection',
        };
      }
      return {
        'success': false,
        'message': 'Network error: Unable to connect to server',
      };
    }
  }
  
  // Task API calls
  static Future<String?> createTask(Task task) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: _getHeaders(),
        body: jsonEncode(task.toJson()),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['taskId'];
      }
      return null;
    } catch (e) {
      print('Error creating task: $e');
      rethrow; // Re-throw to let caller handle authentication errors
    }
  }
  
  static Future<List<Task>> getTasks({String? listId}) async {
    try {
      String url = '$baseUrl/tasks';
      if (listId != null) {
        url += '?listId=$listId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List<dynamic> tasksData = data['tasks'];
          return tasksData.map((json) => Task.fromJson(json)).toList();
        }
      }
      
      // If we get here and status is not 200, throw an error
      if (response.statusCode != 200) {
        throw Exception('Failed to load tasks: HTTP ${response.statusCode}');
      }
      
      return [];
    } catch (e) {
      print('Error getting tasks: $e');
      rethrow; // Re-throw to let caller handle authentication errors
    }
  }
  
  static Future<Task?> getTask(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return Task.fromJson(data['task']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting task: $e');
      rethrow;
    }
  }
  
  static Future<bool> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: _getHeaders(),
        body: jsonEncode(updates),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'];
      }
      return false;
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }
  
  static Future<bool> deleteTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'];
      }
      return false;
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }
  
  static Future<bool> markTaskCompleted(String taskId, bool isCompleted) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId/complete'),
        headers: _getHeaders(),
        body: jsonEncode({'isCompleted': isCompleted}),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'];
      }
      return false;
    } catch (e) {
      print('Error marking task completed: $e');
      rethrow;
    }
  }
  
  static Future<bool> markTaskImportant(String taskId, bool isImportant) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId/important'),
        headers: _getHeaders(),
        body: jsonEncode({'isImportant': isImportant}),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'];
      }
      return false;
    } catch (e) {
      print('Error marking task important: $e');
      rethrow;
    }
  }
  
  // TaskList API calls
  static Future<String?> createTaskList(TaskList taskList) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/task-lists'),
        headers: _getHeaders(),
        body: jsonEncode(taskList.toJson()),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['listId'];
      }
      return null;
    } catch (e) {
      print('Error creating task list: $e');
      rethrow;
    }
  }
  
  static Future<List<TaskList>> getTaskLists({bool defaultOnly = false}) async {
    try {
      String url = '$baseUrl/task-lists';
      if (defaultOnly) {
        url += '?defaultOnly=true';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List<dynamic> listsData = data['taskLists'];
          return listsData.map((json) => TaskList.fromJson(json)).toList();
        }
      }
      
      // If we get here and status is not 200, throw an error
      if (response.statusCode != 200) {
        throw Exception('Failed to load task lists: HTTP ${response.statusCode}');
      }
      
      return [];
    } catch (e) {
      print('Error getting task lists: $e');
      rethrow;
    }
  }
  
  static Future<TaskList?> getTaskList(String listId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/task-lists/$listId'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return TaskList.fromJson(data['taskList']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting task list: $e');
      rethrow;
    }
  }
  
  static Future<bool> updateTaskList(String listId, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/task-lists/$listId'),
        headers: _getHeaders(),
        body: jsonEncode(updates),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'];
      }
      return false;
    } catch (e) {
      print('Error updating task list: $e');
      rethrow;
    }
  }
  
  static Future<bool> deleteTaskList(String listId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/task-lists/$listId'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'];
      }
      return false;
    } catch (e) {
      print('Error deleting task list: $e');
      rethrow;
    }
  }
  
  // Utility API calls
  static Future<List<Task>> getImportantTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/important'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List<dynamic> tasksData = data['tasks'];
          return tasksData.map((json) => Task.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting important tasks: $e');
      rethrow;
    }
  }
  
  static Future<List<Task>> getCompletedTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/completed'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List<dynamic> tasksData = data['tasks'];
          return tasksData.map((json) => Task.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting completed tasks: $e');
      rethrow;
    }
  }
  
  static Future<List<Task>> searchTasks(String searchTerm) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/search?q=${Uri.encodeComponent(searchTerm)}'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List<dynamic> tasksData = data['tasks'];
          return tasksData.map((json) => Task.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching tasks: $e');
      rethrow;
    }
  }
  
  static Future<Map<String, int>?> getListStats(String listId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/task-lists/$listId/stats'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final stats = data['stats'];
          return {
            'totalTasks': stats['totalTasks'],
            'completedTasks': stats['completedTasks'],
            'pendingTasks': stats['pendingTasks'],
          };
        }
      }
      return null;
    } catch (e) {
      print('Error getting list stats: $e');
      rethrow;
    }
  }
} 