import 'package:cloud_firestore/cloud_firestore.dart';

class FAQModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  FAQModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
    };
  }

  factory FAQModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FAQModel(
      id: documentId,
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      category: map['category'] ?? 'General',
      isActive: map['isActive'] ?? true,
      order: map['order'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      createdBy: map['createdBy'],
    );
  }

  FAQModel copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return FAQModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}