import 'package:cloud_firestore/cloud_firestore.dart';

enum NoticeStatus { pending, approved, rejected }

class NoticeModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String authorId;
  final String authorName;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final NoticeStatus status;
  final String? rejectionReason;
  final int likesCount;
  final List<String> tags;

  NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.authorId,
    required this.authorName,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.status = NoticeStatus.pending,
    this.rejectionReason,
    this.likesCount = 0,
    this.tags = const [],
  });

  factory NoticeModel.fromMap(Map<String, dynamic> map, String id) {
    return NoticeModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      imageUrl: map['imageUrl'] ?? map['fileUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      status: NoticeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => NoticeStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      likesCount: map['likesCount'] is int
          ? map['likesCount'] as int
          : map['likesCount'] is double
              ? (map['likesCount'] as double).toInt()
              : map['likesCount'] is String
                  ? int.tryParse(map['likesCount'] as String) ?? 0
                  : 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'authorId': authorId,
      'authorName': authorName,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'likesCount': likesCount,
      'tags': tags,
    };
  }

  NoticeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? authorId,
    String? authorName,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    NoticeStatus? status,
    String? rejectionReason,
    int? likesCount,
    List<String>? tags,
  }) {
    return NoticeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      likesCount: likesCount ?? this.likesCount,
      tags: tags ?? this.tags,
    );
  }

  String get formattedDate {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool get hasFile => imageUrl != null && imageUrl!.isNotEmpty;

  bool get isNew {
    try {
      return DateTime.now().difference(createdAt).inHours < 24;
    } catch (_) {
      return false;
    }
  }
}
