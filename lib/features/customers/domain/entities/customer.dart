import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

/// Pure Dart Customer Entity (100% free of Flutter/Drift dependencies).
class Customer extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final Money currentBalance; // بالقرش — موجب = عليه دين (مدين)، سالب = له رصيد دائن
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;

  const Customer({
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

  /// Check if the customer has outstanding debt (owes money).
  bool get hasDebt => currentBalance.piastres > 0;

  /// Check if the customer has an advance credit (paid more than required).
  bool get isCreditor => currentBalance.piastres < 0;

  /// Check if the balance is completely settled.
  bool get isSettled => currentBalance.piastres == 0;

  Customer copyWith({
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
    return Customer(
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
