import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for the type of feedback.
enum FeedbackType {
  suggestion('Suggestion'),
  bug('Bug Report'),
  feature('Feature Request'),
  compliment('Compliment'),
  other('Other');

  final String displayName;
  const FeedbackType(this.displayName);
}

/// Extension on [String] to get display name for feedback status values.
extension FeedbackStatusExtension on String {
  String get displayName {
    switch (this) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }
}

/// Model class for user feedback submissions.
class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final FeedbackType type;
  final DateTime? createdAt;
  final bool isResolved;
  final String status;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    required this.type,
    this.createdAt,
    this.isResolved = false,
    this.status = 'pending',
  });

  /// Create a FeedbackModel from a Firestore document.
  factory FeedbackModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FeedbackModel(
      id: map['id'] ?? documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: _parseFeedbackType(map['type']),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      isResolved: map['isResolved'] ?? false,
      status: map['status'] ?? 'pending',
    );
  }

  /// Helper to parse FeedbackType from dynamic value.
  static FeedbackType _parseFeedbackType(dynamic type) {
    if (type is FeedbackType) return type;
    if (type is String) {
      return FeedbackType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => FeedbackType.suggestion,
      );
    }
    return FeedbackType.suggestion;
  }

  /// Convert the FeedbackModel to a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'type': type.name,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'isResolved': isResolved,
      'status': status,
    };
  }

  /// Create a copy of this FeedbackModel with modified fields.
  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? title,
    String? description,
    FeedbackType? type,
    DateTime? createdAt,
    bool? isResolved,
    String? status,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
      status: status ?? this.status,
    );
  }
}