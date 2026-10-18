import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_ledger_entry.dart';

class CustomerMapper {
  const CustomerMapper._();

  static Customer toDomain(CustomerEntry entry) {
    return Customer(
      id: entry.id,
      name: entry.name,
      phone: entry.phone,
      address: entry.address,
      notes: entry.notes,
      currentBalance: Money.fromPiastres(entry.currentBalance),
      isActive: entry.isActive,
      createdAt: entry.createdAt,
      createdBy: entry.createdBy,
    );
  }

  static CustomersCompanion toCompanion({
    required String name,
    String? phone,
    String? address,
    String? notes,
    Money initialBalance = Money.zero,
    bool isActive = true,
    String createdBy = 'admin',
  }) {
    return CustomersCompanion.insert(
      name: name,
      phone: Value(phone),
      address: Value(address),
      notes: Value(notes),
      currentBalance: Value(initialBalance.piastres),
      isActive: Value(isActive),
      createdBy: Value(createdBy),
    );
  }

  static CustomerLedgerEntry toLedgerDomain(CustomerLedgerEntryData entry) {
    return CustomerLedgerEntry(
      id: entry.id,
      customerId: entry.customerId,
      entryType: CustomerLedgerEntryType.fromValue(entry.entryType),
      amount: Money.fromPiastres(entry.amount),
      effect: LedgerEffect.fromValue(entry.effect),
      balanceAfter: Money.fromPiastres(entry.balanceAfter),
      referenceType: entry.referenceType,
      referenceId: entry.referenceId,
      note: entry.note,
      createdAt: entry.createdAt,
      createdBy: entry.createdBy,
    );
  }
}
