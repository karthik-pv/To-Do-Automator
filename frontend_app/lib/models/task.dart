class Task {
  final String id;
  final String title;
  final String userId;
  final String listId; // Backward compatibility - first list ID
  final List<String> listIds; // New field for multiple list IDs
  final bool isCompleted;
  final bool isImportant;
  final String? note;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.userId,
    required this.listId,
    List<String>? listIds,
    this.isCompleted = false,
    this.isImportant = false,
    this.note,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  }) : listIds = listIds ?? [listId];

  factory Task.fromJson(Map<String, dynamic> json) {
    // Handle list_ids array
    List<String> listIds = [];
    if (json['list_ids'] != null) {
      if (json['list_ids'] is List) {
        listIds = (json['list_ids'] as List).map((e) => e.toString()).toList();
      } else {
        listIds = [json['list_ids'].toString()];
      }
    }
    
    // Backward compatibility - get primary listId
    String listId = '';
    if (listIds.isNotEmpty) {
      listId = listIds.first;
    } else if (json['list_id'] != null) {
      listId = json['list_id'].toString();
      listIds = [listId];
    } else if (json['listId'] != null) {
      listId = json['listId'].toString();
      listIds = [listId];
    }

    return Task(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      listId: listId,
      listIds: listIds,
      isCompleted: json['isCompleted'] == true || json['is_completed'] == true,
      isImportant: json['isImportant'] == true || json['is_important'] == true,
      note: json['note']?.toString(),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : 
               json['due_date'] != null ? DateTime.tryParse(json['due_date'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : 
                 json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : 
                 json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'listId': listId,
      'list_ids': listIds,
      'isCompleted': isCompleted,
      'isImportant': isImportant,
      'note': note,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  Task copyWith({
    String? title,
    List<String>? listIds,
    bool? isCompleted,
    bool? isImportant,
    String? note,
    DateTime? dueDate,
  }) {
    final newListIds = listIds ?? this.listIds;
    return Task(
      id: id,
      title: title ?? this.title,
      userId: userId,
      listId: newListIds.isNotEmpty ? newListIds.first : this.listId,
      listIds: newListIds,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helper method to check if task is in a specific list
  bool isInList(String checkListId) {
    return listIds.contains(checkListId);
  }
} 