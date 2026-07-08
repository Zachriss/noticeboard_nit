import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  noticePublished,
  noticeUpdated,
  noticeDeleted,
  announcement,
  approval,
  rejection,
  feedback,
  reportCreated,
  systemActivity,
  unknown,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String senderId;
  final String senderRole;
  final String? relatedNoticeId;
  final String targetRole;
  final String? category;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    required this.senderId,
    required this.senderRole,
    this.relatedNoticeId,
    this.targetRole = 'all',
    this.category,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: _typeFromString(map['type'] as String?),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      senderId: map['senderId'] ?? '',
      senderRole: map['senderRole'] ?? '',
      relatedNoticeId: map['relatedNoticeId'],
      targetRole: map['targetRole'] ?? 'all',
      category: map['category'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'senderId': senderId,
      'senderRole': senderRole,
      'relatedNoticeId': relatedNoticeId,
      'targetRole': targetRole,
      'category': category,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? senderId,
    String? senderRole,
    String? relatedNoticeId,
    String? targetRole,
    String? category,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      relatedNoticeId: relatedNoticeId ?? this.relatedNoticeId,
      targetRole: targetRole ?? this.targetRole,
      category: category ?? this.category,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    }
    if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }

  IconData get icon {
    switch (type) {
      case NotificationType.noticePublished:
        return Icons.campaign;
      case NotificationType.noticeUpdated:
        return Icons.update;
      case NotificationType.noticeDeleted:
        return Icons.delete_outline;
      case NotificationType.announcement:
        return Icons.announcement;
      case NotificationType.approval:
        return Icons.check_circle_outline;
      case NotificationType.rejection:
        return Icons.close_outlined;
      case NotificationType.feedback:
        return Icons.feedback_outlined;
      case NotificationType.reportCreated:
        return Icons.report;
      case NotificationType.systemActivity:
        return Icons.auto_awesome_motion;
      case NotificationType.unknown:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.noticePublished:
        return const Color(0xFF1E88E5);
      case NotificationType.noticeUpdated:
        return const Color(0xFF0288D1);
      case NotificationType.noticeDeleted:
        return const Color(0xFFD32F2F);
      case NotificationType.announcement:
        return const Color(0xFF6A1B9A);
      case NotificationType.approval:
        return const Color(0xFF2E7D32);
      case NotificationType.rejection:
        return const Color(0xFFF57C00);
      case NotificationType.feedback:
        return const Color(0xFF00897B);
      case NotificationType.reportCreated:
        return const Color(0xFF5D4037);
      case NotificationType.systemActivity:
        return const Color(0xFF5E35B1);
      case NotificationType.unknown:
        return const Color(0xFF424242);
    }
  }

  static NotificationType _typeFromString(String? value) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationType.unknown,
    );
  }
}
