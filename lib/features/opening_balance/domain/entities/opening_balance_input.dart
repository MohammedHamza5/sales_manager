import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

class ProductOpeningBalance extends Equatable {
  final int productId;
  final String productName;
  final String? code;
  final String unit;
  final Decimal initialQuantity;

  const ProductOpeningBalance({
    required this.productId,
    required this.productName,
    this.code,
    required this.unit,
    required this.initialQuantity,
  });

  ProductOpeningBalance copyWith({
    int? productId,
    String? productName,
    String? code,
    String? unit,
    Decimal? initialQuantity,
  }) {
    return ProductOpeningBalance(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      code: code ?? this.code,
      unit: unit ?? this.unit,
      initialQuantity: initialQuantity ?? this.initialQuantity,
    );
  }

  @override
  List<Object?> get props => [productId, productName, code, unit, initialQuantity];
}

class StakeholderOpeningBalance extends Equatable {
  final int stakeholderId;
  final String name;
  final String? phone;
  final Money balance;

  const StakeholderOpeningBalance({
    required this.stakeholderId,
    required this.name,
    this.phone,
    required this.balance,
  });

  StakeholderOpeningBalance copyWith({
    int? stakeholderId,
    String? name,
    String? phone,
    Money? balance,
  }) {
    return StakeholderOpeningBalance(
      stakeholderId: stakeholderId ?? this.stakeholderId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balance: balance ?? this.balance,
    );
  }

  @override
  List<Object?> get props => [stakeholderId, name, phone, balance];
}

class OpeningBalanceInput extends Equatable {
  final Money cashboxBalance;
  final List<ProductOpeningBalance> products;
  final List<StakeholderOpeningBalance> customers;
  final List<StakeholderOpeningBalance> suppliers;

  const OpeningBalanceInput({
    this.cashboxBalance = Money.zero,
    this.products = const [],
    this.customers = const [],
    this.suppliers = const [],
  });

  Decimal get totalProductsQuantity {
    var sum = Decimal.zero;
    for (final p in products) {
      sum += p.initialQuantity;
    }
    return sum;
  }

  Money get totalCustomerDebt {
    var sum = 0;
    for (final c in customers) {
      sum += c.balance.piastres;
    }
    return Money.fromPiastres(sum);
  }

  Money get totalSupplierDue {
    var sum = 0;
    for (final s in suppliers) {
      sum += s.balance.piastres;
    }
    return Money.fromPiastres(sum);
  }

  bool get hasAnyData {
    return cashboxBalance.piastres > 0 ||
        products.any((p) => p.initialQuantity > Decimal.zero) ||
        customers.any((c) => c.balance.piastres > 0) ||
        suppliers.any((s) => s.balance.piastres > 0);
  }

  OpeningBalanceInput copyWith({
    Money? cashboxBalance,
    List<ProductOpeningBalance>? products,
    List<StakeholderOpeningBalance>? customers,
    List<StakeholderOpeningBalance>? suppliers,
  }) {
    return OpeningBalanceInput(
      cashboxBalance: cashboxBalance ?? this.cashboxBalance,
      products: products ?? this.products,
      customers: customers ?? this.customers,
      suppliers: suppliers ?? this.suppliers,
    );
  }

  @override
  List<Object?> get props => [cashboxBalance, products, customers, suppliers];
}
