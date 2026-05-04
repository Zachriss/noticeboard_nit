import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, admin, superAdmin }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImageUrl;
  final String? department;
  final String? year;
  final DateTime createdAt;
  final bool isApproved;
  final bool isDisabled;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageUrl,
    this.department,
    this.year,
    required this.createdAt,
    this.isApproved = true,
    this.isDisabled = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.student,
      ),
      profileImageUrl: map['profileImageUrl'],
      department: map['department'],
      year: map['year'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isApproved: map['isApproved'] ?? true,
      isDisabled: map['isDisabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
      'department': department,
      'year': year,
      'createdAt': Timestamp.fromDate(createdAt),
      'isApproved': isApproved,
      'isDisabled': isDisabled,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? profileImageUrl,
    String? department,
    String? year,
    DateTime? createdAt,
    bool? isApproved,
    bool? isDisabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      department: department ?? this.department,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      isApproved: isApproved ?? this.isApproved,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}
