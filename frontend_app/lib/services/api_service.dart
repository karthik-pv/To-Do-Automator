import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000'; // Change this to your server URL
  
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final userId = await getUserId();
    return {
      'Content-Type': 'application/json',
      if (userId != null) 'X-User-ID': userId,
    };
  }

  // Auth endpoints
  static Future<User?> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          await saveUserId(data['userId']);
          return User(id: data['userId'], email: email);
        }
      }
      return null;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  static Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          await saveUserId(data['userId']);
          return User(id: data['userId'], email: data['email']);
        }
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Task List endpoints
  static Future<List<TaskList>> getTaskLists() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/task-lists'),
        headers: headers,
      );

      print('Get task lists response status: ${response.statusCode}');
      print('Get task lists response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          print('Task lists data: ${data['taskLists']}');
          final taskLists = (data['taskLists'] as List)
              .map((json) {
                print('Processing task list JSON: $json');
                return TaskList.fromJson(json);
              })
              .toList();
          print('Parsed ${taskLists.length} task lists');
          return taskLists;
        }
      }
      return [];
    } catch (e) {
      print('Get task lists error: $e');
      print('Error type: ${e.runtimeType}');
      if (e is TypeError) {
        print('TypeError details: $e');
      }
      return [];
    }
  }

  static Future<TaskList?> createTaskList(String name, String icon, int iconColor, {bool isDefault = false}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/task-lists'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'icon': icon,
          'iconColor': iconColor,
          'isDefault': isDefault,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Fetch the created list
          final lists = await getTaskLists();
          return lists.firstWhere((list) => list.id == data['listId']);
        }
      }
      return null;
    } catch (e) {
      print('Create task list error: $e');
      return null;
    }
  }

  static Future<bool> updateTaskList(String listId, String name, String icon, int iconColor) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/task-lists/$listId'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'icon': icon,
          'iconColor': iconColor,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update task list error: $e');
      return false;
    }
  }

  static Future<bool> deleteTaskList(String listId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/task-lists/$listId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete task list error: $e');
      return false;
    }
  }

  // Task endpoints
  static Future<List<Task>> getTasks({String? listId}) async {
    try {
      final headers = await _getHeaders();
      String url = '$baseUrl/tasks';
      if (listId != null) {
        url += '?listId=$listId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['tasks'] as List)
              .map((json) => Task.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Get tasks error: $e');
      return [];
    }
  }

  static Future<Task?> createTask(String title, String listId, {String? note, DateTime? dueDate, bool isImportant = false}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'listId': listId,
          'note': note,
          'dueDate': dueDate?.toIso8601String(),
          'isImportant': isImportant,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Fetch the created task
          final tasks = await getTasks(listId: listId);
          return tasks.firstWhere((task) => task.id == data['taskId']);
        }
      }
      return null;
    } catch (e) {
      print('Create task error: $e');
      return null;
    }
  }

  static Future<bool> updateTask(String taskId, {String? title, String? note, DateTime? dueDate, bool? isImportant, bool? isCompleted}) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> body = {};
      
      if (title != null) body['title'] = title;
      if (note != null) body['note'] = note;
      if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();
      if (isImportant != null) body['isImportant'] = isImportant;
      if (isCompleted != null) body['isCompleted'] = isCompleted;

      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update task error: $e');
      return false;
    }
  }

  static Future<bool> deleteTask(String taskId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete task error: $e');
      return false;
    }
  }

  static Future<int> deleteMultipleTasks(List<String> taskIds) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/bulk-delete'),
        headers: headers,
        body: jsonEncode({'taskIds': taskIds}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['deletedCount'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      print('Delete multiple tasks error: $e');
      return 0;
    }
  }

  static Future<bool> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId/complete'),
        headers: headers,
        body: jsonEncode({'isCompleted': isCompleted}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Toggle task completion error: $e');
      return false;
    }
  }

  static Future<bool> toggleTaskImportance(String taskId, bool isImportant) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId/important'),
        headers: headers,
        body: jsonEncode({'isImportant': isImportant}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Toggle task importance error: $e');
      return false;
    }
  }

  static Future<List<Task>> getImportantTasks() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/important'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['tasks'] as List)
              .map((json) => Task.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Get important tasks error: $e');
      return [];
    }
  }

  static Future<bool> addTasksToLists(List<String> taskIds, List<String> listIds) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/add-to-lists'),
        headers: headers,
        body: jsonEncode({
          'taskIds': taskIds,
          'listIds': listIds,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Add tasks to lists error: $e');
      return false;
    }
  }
} 