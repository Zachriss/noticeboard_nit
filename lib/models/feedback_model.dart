import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String noticeId;
  final String noticeTitle;
  final String message;
  final DateTime createdAt;
  final bool isResolved;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.noticeId,
    required this.noticeTitle,
    required this.message,
    required this.createdAt,
    this.isResolved = false,
  });

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      noticeId: map['noticeId'] ?? '',
      noticeTitle: map['noticeTitle'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isResolved: map['isResolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'noticeId': noticeId,
      'noticeTitle': noticeTitle,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isResolved': isResolved,
    };
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? noticeId,
    String? noticeTitle,
    String? message,
    DateTime? createdAt,
    bool? isResolved,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      noticeId: noticeId ?? this.noticeId,
      noticeTitle: noticeTitle ?? this.noticeTitle,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}
