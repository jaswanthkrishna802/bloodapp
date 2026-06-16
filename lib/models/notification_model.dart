import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { urgent, success, info, warning }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return "${diff.inMinutes} minutes ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    return "${diff.inDays} days ago";
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime dt;
    final raw = json['createdAt'];
    if (raw is Timestamp) {
      dt = raw.toDate();
    } else {
      dt = DateTime.now();
    }
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values[json['type'] ?? 2],
      createdAt: dt,
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }
}
