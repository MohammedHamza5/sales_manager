import '../../../../core/result/result.dart';
import '../entities/user_entity.dart';
import '../models/user_role.dart';

abstract class AuthRepository {
  /// Returns the currently authenticated user session if present, or null if logged out.
  Future<UserEntity?> getCurrentUser();

  /// Logs in with username and password.
  Future<Result<UserEntity>> login({
    required String username,
    required String password,
  });

  /// Quick POS switch using a 4-digit PIN code.
  Future<Result<UserEntity>> loginWithPin({
    required String pinCode,
  });

  /// Terminates the current active user session.
  Future<Result<void>> logout();

  /// Fetches all users registered in the system (Admin only).
  Future<Result<List<UserEntity>>> getUsers();

  /// Creates a new user account.
  Future<Result<UserEntity>> createUser({
    required String username,
    required String fullName,
    required String password,
    required UserRole role,
    String? pinCode,
  });

  /// Updates an existing user's details or role.
  Future<Result<UserEntity>> updateUser({
    required int id,
    required String fullName,
    required UserRole role,
    String? newPassword,
    String? newPinCode,
    required bool isActive,
  });

  /// Deactivates or removes a user account.
  Future<Result<void>> deleteUser(int id);
}
