import 'package:equatable/equatable.dart';
import '../models/user_role.dart';

class UserEntity extends Equatable {
  final int id;
  final String username;
  final String fullName;
  final UserRole role;
  final String? pinCode; // Optional 4-digit fast-login PIN for POS
  final bool isActive;
  final DateTime createdAt;
  final String? tenantId;

  const UserEntity({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.pinCode,
    this.isActive = true,
    required this.createdAt,
    this.tenantId,
  });

  bool hasPermission(AppPermission permission) => role.hasPermission(permission);

  UserEntity copyWith({
    int? id,
    String? username,
    String? fullName,
    UserRole? role,
    String? pinCode,
    bool? isActive,
    DateTime? createdAt,
    String? tenantId,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      pinCode: pinCode ?? this.pinCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        fullName,
        role,
        pinCode,
        isActive,
        createdAt,
        tenantId,
      ];
}
