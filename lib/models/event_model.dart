import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime eventDate;
  final String? location;
  final String category;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int attendeeCount;
  final List<String> tags;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.eventDate,
    this.location,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.attendeeCount = 0,
    this.tags = const [],
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      eventDate: (map['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: map['location'],
      category: map['category'] ?? 'General',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attendeeCount: map['attendeeCount'] is int
          ? map['attendeeCount'] as int
          : map['attendeeCount'] is double
              ? (map['attendeeCount'] as double).toInt()
              : map['attendeeCount'] is String
                  ? int.tryParse(map['attendeeCount'] as String) ?? 0
                  : 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location,
      'category': category,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'attendeeCount': attendeeCount,
      'tags': tags,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? eventDate,
    String? location,
    String? category,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    int? attendeeCount,
    List<String>? tags,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      tags: tags ?? this.tags,
    );
  }
}
