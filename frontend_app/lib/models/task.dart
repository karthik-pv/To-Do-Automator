class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isImportant;
  final String? note;
  final String listId;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
    this.isImportant = false,
    this.note,
    required this.listId,
  });

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isImportant,
    String? note,
    String? listId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isImportant: isImportant ?? this.isImportant,
      note: note ?? this.note,
      listId: listId ?? this.listId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isImportant': isImportant,
      'note': note,
      'listId': listId,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isImportant: json['isImportant'],
      note: json['note'],
      listId: json['listId'],
    );
  }
} 