import 'dart:convert';

enum NotificationType {
  badge, // Notifikasi ketika mendapatkan badge/pencapaian
  system, // Notifikasi sistem (update, info)
  family, // Notifikasi dari grup keluarga
  savings, // Notifikasi pengingat target tabungan
  bills,
  investment,
  tax,
  recurring,
  healthCheck,
  gold,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final String? actionData; // Data opsional untuk navigasi (misal: badgeId)

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.actionData,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: NotificationType.values[json['type'] as int],
      actionData: json['actionData'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.index,
      'actionData': actionData,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
    String? actionData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      actionData: actionData ?? this.actionData,
    );
  }
}
