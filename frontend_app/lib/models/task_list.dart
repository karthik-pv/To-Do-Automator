class TaskList {
  final String id;
  final String name;
  final String userId;
  final String icon;
  final int iconColor;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskList({
    required this.id,
    required this.name,
    required this.userId,
    this.icon = 'list',
    this.iconColor = 0xFF0078D4,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskList.fromJson(Map<String, dynamic> json) {
    return TaskList(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'list',
      iconColor: _parseIconColor(json['iconColor']),
      isDefault: json['isDefault'] == true || json['is_default'] == true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  static int _parseIconColor(dynamic color) {
    if (color == null) return 0xFF0078D4;
    if (color is int) return color;
    if (color is String) {
      // Remove # if present
      String cleanColor = color.replaceAll('#', '');
      // Add FF prefix if not present (for alpha channel)
      if (cleanColor.length == 6) {
        cleanColor = 'FF$cleanColor';
      }
      return int.tryParse(cleanColor, radix: 16) ?? 0xFF0078D4;
    }
    return 0xFF0078D4;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'iconColor': iconColor,
      'isDefault': isDefault,
    };
  }

  TaskList copyWith({
    String? name,
    String? icon,
    int? iconColor,
    bool? isDefault,
  }) {
    return TaskList(
      id: id,
      name: name ?? this.name,
      userId: userId,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
} 