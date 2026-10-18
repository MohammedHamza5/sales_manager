import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/features/auth/domain/entities/user_entity.dart';
import 'package:sales_manager/features/auth/domain/models/user_role.dart';

void main() {
  group('UserRole & Permissions Tests', () {
    test('Admin role has all permissions', () {
      const admin = UserRole.admin;
      for (final permission in AppPermission.values) {
        expect(admin.hasPermission(permission), isTrue,
            reason: 'Admin should have ${permission.name}');
      }
    });

    test('Cashier has only sales, returns, and customers permissions', () {
      const cashier = UserRole.cashier;
      expect(cashier.hasPermission(AppPermission.createSale), isTrue);
      expect(cashier.hasPermission(AppPermission.createReturn), isTrue);
      expect(cashier.hasPermission(AppPermission.manageCustomers), isTrue);

      expect(cashier.hasPermission(AppPermission.viewProfits), isFalse);
      expect(cashier.hasPermission(AppPermission.viewCosts), isFalse);
      expect(cashier.hasPermission(AppPermission.manageExpenses), isFalse);
      expect(cashier.hasPermission(AppPermission.manageUsers), isFalse);
    });

    test('Accountant has financial and report permissions but no sales/stock', () {
      const accountant = UserRole.accountant;
      expect(accountant.hasPermission(AppPermission.viewReports), isTrue);
      expect(accountant.hasPermission(AppPermission.viewProfits), isTrue);
      expect(accountant.hasPermission(AppPermission.manageCashbox), isTrue);
      expect(accountant.hasPermission(AppPermission.manageExpenses), isTrue);

      expect(accountant.hasPermission(AppPermission.createSale), isFalse);
      expect(accountant.hasPermission(AppPermission.manageInventory), isFalse);
      expect(accountant.hasPermission(AppPermission.manageUsers), isFalse);
    });

    test('StockManager has inventory and purchase permissions', () {
      const stockManager = UserRole.stockManager;
      expect(stockManager.hasPermission(AppPermission.manageProducts), isTrue);
      expect(stockManager.hasPermission(AppPermission.managePurchases), isTrue);
      expect(stockManager.hasPermission(AppPermission.manageInventory), isTrue);
      expect(stockManager.hasPermission(AppPermission.viewCosts), isTrue);

      expect(stockManager.hasPermission(AppPermission.createSale), isFalse);
      expect(stockManager.hasPermission(AppPermission.manageCashbox), isFalse);
      expect(stockManager.hasPermission(AppPermission.manageUsers), isFalse);
    });

    test('UserEntity propagates permission check correctly', () {
      final user = UserEntity(
        id: 1,
        username: 'cashier1',
        fullName: 'أحمد علي',
        role: UserRole.cashier,
        createdAt: DateTime.now(),
      );

      expect(user.hasPermission(AppPermission.createSale), isTrue);
      expect(user.hasPermission(AppPermission.viewProfits), isFalse);
    });
  });
}
