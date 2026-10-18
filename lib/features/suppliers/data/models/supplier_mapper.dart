import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/supplier_ledger_entry.dart';

class SupplierMapper {
  const SupplierMapper._();

  static Supplier toDomain(SupplierEntry entry) {
    return Supplier(
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

  static SuppliersCompanion toCompanion({
    required String name,
    String? phone,
    String? address,
    String? notes,
    Money initialBalance = Money.zero,
    bool isActive = true,
    String createdBy = 'admin',
  }) {
    return SuppliersCompanion.insert(
      name: name,
      phone: Value(phone),
      address: Value(address),
      notes: Value(notes),
      currentBalance: Value(initialBalance.piastres),
      isActive: Value(isActive),
      createdBy: Value(createdBy),
    );
  }

  static SupplierLedgerEntry toLedgerDomain(SupplierLedgerEntryData entry) {
    return SupplierLedgerEntry(
      id: entry.id,
      supplierId: entry.supplierId,
      entryType: SupplierLedgerEntryType.fromValue(entry.entryType),
      amount: Money.fromPiastres(entry.amount),
      effect: SupplierLedgerEffect.fromValue(entry.effect),
      balanceAfter: Money.fromPiastres(entry.balanceAfter),
      referenceType: entry.referenceType,
      referenceId: entry.referenceId,
      note: entry.note,
      createdAt: entry.createdAt,
      createdBy: entry.createdBy,
    );
  }
}
