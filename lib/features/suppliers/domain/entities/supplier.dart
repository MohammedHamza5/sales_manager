import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

/// Pure Dart entity representing a supplier (المورد).
class Supplier extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final Money currentBalance; // int قرش — Cache من الـLedger
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;

  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    this.currentBalance = Money.zero,
    this.isActive = true,
    required this.createdAt,
    this.createdBy = 'admin',
  });

  /// Returns true if we owe money to this supplier (له مستحقات علينا).
  bool get hasBalanceDue => currentBalance.piastres > 0;

  /// Returns true if the supplier owes money to us (مدين لنا - دفعنا زيادة).
  bool get isDebtorToUs => currentBalance.piastres < 0;

  /// Returns true if the balance is fully settled.
  bool get isSettled => currentBalance.piastres == 0;

  Supplier copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    Money? currentBalance,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      currentBalance: currentBalance ?? this.currentBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        address,
        notes,
        currentBalance,
        isActive,
        createdAt,
        createdBy,
      ];
}
