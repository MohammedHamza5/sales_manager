import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class HashUtils {
  HashUtils._();

  /// Generates a random 16-byte hex salt
  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes a password using SHA-256 with salt: `hash(salt + password)`
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  /// Verifies whether the plain password matches the hashed password with the given salt
  static bool verifyPassword({
    required String plainPassword,
    required String salt,
    required String expectedHash,
  }) {
    final computed = hashPassword(plainPassword, salt);
    return computed == expectedHash;
  }

  /// Hashes a 4-digit PIN code with salt
  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('pin:$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  /// Verifies a 4-digit PIN code
  static bool verifyPin({
    required String plainPin,
    required String salt,
    required String expectedHash,
  }) {
    final computed = hashPin(plainPin, salt);
    return computed == expectedHash;
  }
}
