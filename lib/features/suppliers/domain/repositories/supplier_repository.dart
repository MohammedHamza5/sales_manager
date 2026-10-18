import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../entities/supplier.dart';
import '../entities/supplier_ledger_entry.dart';

abstract interface class SupplierRepository {
  /// Fetch suppliers with optional search and active status filter.
  Future<Result<List<Supplier>>> getSuppliers({
    String? query,
    bool? isActiveOnly,
  });

  /// Real-time stream of suppliers list.
  Stream<List<Supplier>> watchSuppliers({
    String? query,
    bool? isActiveOnly,
  });

  /// Get single supplier by ID.
  Future<Result<Supplier>> getSupplierById(int id);

  /// Add a new supplier atomically (writes to suppliers, audit_log, and optional opening balance).
  Future<Result<Supplier>> addSupplier({
    required String name,
    String? phone,
    String? address,
    String? notes,
    Money initialBalance = Money.zero,
    String createdBy = 'admin',
  });

  /// Update existing supplier details.
  Future<Result<Supplier>> updateSupplier(Supplier supplier);

  /// Toggle active/deactivated state of supplier (No hard delete).
  Future<Result<void>> toggleSupplierStatus(int id, bool isActive);

  /// Get statement of account (Ledger entries) for a supplier.
  Future<Result<List<SupplierLedgerEntry>>> getSupplierLedger(int supplierId);

  /// Real-time stream of supplier statement entries.
  Stream<List<SupplierLedgerEntry>> watchSupplierLedger(int supplierId);
}
