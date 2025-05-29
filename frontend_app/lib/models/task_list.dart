import 'package:flutter/material.dart';

class TaskList {
  final String id;
  final String name;
  final IconData icon;
  final Color iconColor;
  final bool isDefault;
  final DateTime createdAt;

  TaskList({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconColor,
    this.isDefault = false,
    required this.createdAt,
  });

  TaskList copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? iconColor,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return TaskList(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'iconColor': iconColor.value,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskList.fromJson(Map<String, dynamic> json) {
    return TaskList(
      id: json['id'],
      name: json['name'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      iconColor: Color(json['iconColor']),
      isDefault: json['isDefault'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 