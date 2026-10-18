import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../entities/customer.dart';
import '../entities/customer_ledger_entry.dart';

abstract interface class CustomerRepository {
  /// Fetch customers with optional search and active status filter.
  Future<Result<List<Customer>>> getCustomers({
    String? query,
    bool? isActiveOnly,
  });

  /// Real-time stream of customers list.
  Stream<List<Customer>> watchCustomers({
    String? query,
    bool? isActiveOnly,
  });

  /// Get single customer by ID.
  Future<Result<Customer>> getCustomerById(int id);

  /// Add a new customer atomically (writes to customers, audit_log, and optional opening balance).
  Future<Result<Customer>> addCustomer({
    required String name,
    String? phone,
    String? address,
    String? notes,
    Money initialBalance = Money.zero,
    String createdBy = 'admin',
  });

  /// Update existing customer details.
  Future<Result<Customer>> updateCustomer(Customer customer);

  /// Toggle active/deactivated state of customer (No hard delete).
  Future<Result<void>> toggleCustomerStatus(int id, bool isActive);

  /// Get statement of account (Ledger entries) for a customer.
  Future<Result<List<CustomerLedgerEntry>>> getCustomerLedger(int customerId);

  /// Real-time stream of customer statement entries.
  Stream<List<CustomerLedgerEntry>> watchCustomerLedger(int customerId);
}
