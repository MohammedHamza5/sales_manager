import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/security/hash_utils.dart';

void main() {
  group('HashUtils Tests', () {
    test('generateSalt returns valid hex string with expected length', () {
      final salt = HashUtils.generateSalt(16);
      expect(salt.length, equals(32)); // 16 bytes = 32 hex chars
      final salt2 = HashUtils.generateSalt(16);
      expect(salt, isNot(equals(salt2)));
    });

    test('hashPassword produces consistent hash for same password and salt', () {
      const password = 'mySecretPassword123';
      const salt = 'randomSaltHex12345';

      final hash1 = HashUtils.hashPassword(password, salt);
      final hash2 = HashUtils.hashPassword(password, salt);

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 is 64 hex characters
    });

    test('verifyPassword correctly validates matching and non-matching passwords', () {
      const password = 'AdminPassword#2026';
      final salt = HashUtils.generateSalt();
      final hash = HashUtils.hashPassword(password, salt);

      expect(
        HashUtils.verifyPassword(
          plainPassword: password,
          salt: salt,
          expectedHash: hash,
        ),
        isTrue,
      );

      expect(
        HashUtils.verifyPassword(
          plainPassword: 'wrongPassword',
          salt: salt,
          expectedHash: hash,
        ),
        isFalse,
      );
    });

    test('hashPin and verifyPin work correctly for 4-digit PINs', () {
      const pin = '1234';
      final salt = HashUtils.generateSalt();
      final hash = HashUtils.hashPin(pin, salt);

      expect(
        HashUtils.verifyPin(
          plainPin: pin,
          salt: salt,
          expectedHash: hash,
        ),
        isTrue,
      );

      expect(
        HashUtils.verifyPin(
          plainPin: '9999',
          salt: salt,
          expectedHash: hash,
        ),
        isFalse,
      );
    });
  });
}
