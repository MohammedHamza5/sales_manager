import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import '../../features/customers/data/daos/customers_dao.dart';
import '../../features/customers/data/repositories/customer_repository_impl.dart';
import '../../features/customers/domain/repositories/customer_repository.dart';
import '../../features/customers/domain/usecases/add_customer_usecase.dart';
import '../../features/customers/domain/usecases/get_customers_usecase.dart';
import '../../features/customers/domain/usecases/toggle_customer_status_usecase.dart';
import '../../features/customers/domain/usecases/update_customer_usecase.dart';
import '../../features/customers/domain/usecases/watch_customer_ledger_usecase.dart';
import '../../features/customers/domain/usecases/watch_customers_usecase.dart';
import '../../features/inventory/data/daos/inventory_movements_dao.dart';
import '../../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/inventory/domain/usecases/get_inventory_movements_usecase.dart';
import '../../features/inventory/domain/usecases/record_stock_adjustment_usecase.dart';
import '../../features/inventory/domain/usecases/watch_inventory_movements_usecase.dart';
import '../../features/products/data/daos/products_dao.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/add_product_usecase.dart';
import '../../features/products/domain/usecases/get_products_usecase.dart';
import '../../features/products/domain/usecases/toggle_product_status_usecase.dart';
import '../../features/products/domain/usecases/update_product_usecase.dart';
import '../../features/products/domain/usecases/watch_products_usecase.dart';
import '../../features/suppliers/data/daos/suppliers_dao.dart';
import '../../features/suppliers/data/repositories/supplier_repository_impl.dart';
import '../../features/suppliers/domain/repositories/supplier_repository.dart';
import '../../features/suppliers/domain/usecases/add_supplier_usecase.dart';
import '../../features/suppliers/domain/usecases/get_suppliers_usecase.dart';
import '../../features/suppliers/domain/usecases/toggle_supplier_status_usecase.dart';
import '../../features/suppliers/domain/usecases/update_supplier_usecase.dart';
import '../../features/suppliers/domain/usecases/watch_supplier_ledger_usecase.dart';
import '../../features/suppliers/domain/usecases/watch_suppliers_usecase.dart';
import '../../features/opening_balance/data/repositories/opening_balance_repository_impl.dart';
import '../../features/opening_balance/domain/repositories/opening_balance_repository.dart';
import '../../features/opening_balance/domain/usecases/check_opening_balance_status_usecase.dart';
import '../../features/opening_balance/domain/usecases/save_opening_balances_usecase.dart';
import '../../features/purchases/data/daos/purchases_dao.dart';
import '../../features/purchases/data/repositories/purchase_repository_impl.dart';
import '../../features/purchases/domain/repositories/purchase_repository.dart';
import '../../features/purchases/domain/usecases/create_purchase_usecase.dart';
import '../../features/purchases/domain/usecases/get_purchases_usecase.dart';
import '../../features/purchases/domain/usecases/reverse_purchase_usecase.dart';
import '../../features/purchases/domain/usecases/watch_purchases_usecase.dart';
import '../../features/sales/data/daos/sales_dao.dart';
import '../../features/sales/data/repositories/sale_repository_impl.dart';
import '../../features/sales/domain/repositories/sale_repository.dart';
import '../../features/sales/domain/usecases/create_sale_usecase.dart';
import '../../features/sales/domain/usecases/get_sales_usecase.dart';
import '../../features/sales/domain/usecases/watch_sales_usecase.dart';
import '../../features/sales/domain/usecases/get_sale_by_id_usecase.dart';
import '../../features/sales/domain/usecases/reverse_sale_usecase.dart';
import '../../features/returns/data/daos/returns_dao.dart';
import '../../features/returns/data/repositories/return_repository_impl.dart';
import '../../features/returns/domain/repositories/return_repository.dart';
import '../../features/returns/domain/usecases/create_customer_return_usecase.dart';
import '../../features/returns/domain/usecases/create_supplier_return_usecase.dart';
import '../../features/returns/domain/usecases/get_customer_returns_usecase.dart';
import '../../features/returns/domain/usecases/watch_customer_returns_usecase.dart';
import '../../features/returns/domain/usecases/get_supplier_returns_usecase.dart';
import '../../features/returns/domain/usecases/watch_supplier_returns_usecase.dart';
import '../../features/audit_log/data/daos/audit_log_dao.dart';
import '../../features/audit_log/data/repositories/audit_log_repository_impl.dart';
import '../../features/audit_log/domain/repositories/audit_log_repository.dart';
import '../../features/audit_log/domain/usecases/get_audit_logs_usecase.dart';
import '../../features/audit_log/domain/usecases/watch_audit_logs_usecase.dart';
import '../backup/backup_service.dart';
import '../backup/restore_service.dart';
import '../print/print_service.dart';
import '../../features/backup_restore/data/repositories/backup_repository_impl.dart';
import '../../features/backup_restore/domain/repositories/backup_repository.dart';
import '../../features/backup_restore/domain/usecases/create_manual_backup_usecase.dart';
import '../../features/backup_restore/domain/usecases/export_backup_usecase.dart';
import '../../features/backup_restore/domain/usecases/create_auto_backup_usecase.dart';
import '../../features/backup_restore/domain/usecases/restore_backup_usecase.dart';
import '../../features/backup_restore/domain/usecases/get_backup_history_usecase.dart';
import '../../features/backup_restore/domain/usecases/manage_backup_settings_usecase.dart';
import '../../features/cashbox/data/daos/cashbox_dao.dart';
import '../../features/cashbox/data/repositories/cashbox_repository_impl.dart';
import '../../features/cashbox/domain/repositories/cashbox_repository.dart';
import '../../features/cashbox/domain/usecases/get_cashbox_summary_usecase.dart';
import '../../features/cashbox/domain/usecases/watch_cashbox_balance_usecase.dart';
import '../../features/cashbox/domain/usecases/watch_cashbox_summary_usecase.dart';
import '../../features/cashbox/domain/usecases/watch_cashbox_transactions_usecase.dart';
import '../../features/expenses/data/daos/expenses_dao.dart';
import '../../features/expenses/data/repositories/expense_repository_impl.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/expenses/domain/usecases/get_expenses_usecase.dart';
import '../../features/expenses/domain/usecases/record_expense_usecase.dart';
import '../../features/expenses/domain/usecases/watch_expenses_usecase.dart';
import '../../features/reports/data/repositories/report_repository_impl.dart';
import '../../features/reports/domain/repositories/report_repository.dart';
import '../../features/reports/domain/usecases/get_all_customer_balances_usecase.dart';
import '../../features/reports/domain/usecases/get_all_supplier_balances_usecase.dart';
import '../../features/reports/domain/usecases/get_cashbox_report_usecase.dart';
import '../../features/reports/domain/usecases/get_collections_report_usecase.dart';
import '../../features/reports/domain/usecases/get_customer_report_usecase.dart';
import '../../features/reports/domain/usecases/get_inventory_report_usecase.dart';
import '../../features/reports/domain/usecases/get_profit_report_usecase.dart';
import '../../features/reports/domain/usecases/get_sales_report_usecase.dart';
import '../../features/reports/domain/usecases/get_supplier_report_usecase.dart';
import '../../features/reports/presentation/cubit/reports_cubit.dart';
import '../../features/customer_payments/data/daos/customer_payments_dao.dart';
import '../../features/customer_payments/data/repositories/customer_payment_repository_impl.dart';
import '../../features/customer_payments/domain/repositories/customer_payment_repository.dart';
import '../../features/customer_payments/domain/usecases/record_customer_payment_usecase.dart';
import '../../features/customer_payments/domain/usecases/get_customer_payments_usecase.dart';
import '../../features/customer_payments/domain/usecases/watch_customer_payments_usecase.dart';
import '../../features/customer_payments/presentation/cubit/customer_payments_cubit.dart';
import '../../features/supplier_payments/data/daos/supplier_payments_dao.dart';
import '../../features/supplier_payments/data/repositories/supplier_payment_repository_impl.dart';
import '../../features/supplier_payments/domain/repositories/supplier_payment_repository.dart';
import '../../features/supplier_payments/domain/usecases/record_supplier_payment_usecase.dart';
import '../../features/supplier_payments/domain/usecases/get_supplier_payments_usecase.dart';
import '../../features/supplier_payments/domain/usecases/watch_supplier_payments_usecase.dart';
import '../../features/supplier_payments/presentation/cubit/supplier_payments_cubit.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/watch_dashboard_data_usecase.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_data_usecase.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../theme/theme_cubit.dart';
import '../database/app_database.dart';
import '../database/daos/sync_queue_dao.dart';
import '../network/network_info.dart';
import '../sync/sync_service.dart';
import '../sync/sync_dispatcher.dart';
import '../../features/update/data/datasources/update_local_datasource.dart';
import '../../features/update/data/datasources/update_remote_datasource.dart';
import '../../features/update/data/repositories/update_repository_impl.dart';
import '../../features/update/domain/repositories/update_repository.dart';
import '../../features/update/domain/usecases/apply_update_usecase.dart';
import '../../features/update/domain/usecases/check_for_update_usecase.dart';
import '../../features/update/domain/usecases/download_update_usecase.dart';
import '../../features/update/domain/usecases/get_current_version_usecase.dart';
import '../../features/update/presentation/cubit/update_cubit.dart';

final getIt = GetIt.instance;

Future<void> initDependencies({AppDatabase? database}) async {
  // 1. Database
  final db = database ?? AppDatabase();
  if (!getIt.isRegistered<AppDatabase>()) {
    getIt.registerSingleton<AppDatabase>(db);
  }

  // Initialize unique deviceId for sync
  try {
    final deviceSetting = await (db.select(db.settings)
          ..where((tbl) => tbl.key.equals('device_id')))
        .getSingleOrNull();

    if (deviceSetting != null && deviceSetting.value.isNotEmpty) {
      SyncDispatcher.deviceId = deviceSetting.value;
    } else {
      final generatedId = 'pos_${const Uuid().v4().substring(0, 8)}';
      SyncDispatcher.deviceId = generatedId;
      await db.into(db.settings).insertOnConflictUpdate(
            SettingsCompanion.insert(
              key: 'device_id',
              value: generatedId,
              updatedAt: Value(DateTime.now()),
            ),
          );
    }
  } catch (_) {
    // Non-blocking fallback
  }

  // 2. DAOs
  if (!getIt.isRegistered<ProductsDao>()) {
    getIt.registerLazySingleton<ProductsDao>(() => ProductsDao(getIt<AppDatabase>()));
  }
  if (!getIt.isRegistered<InventoryMovementsDao>()) {
    getIt.registerLazySingleton<InventoryMovementsDao>(
      () => InventoryMovementsDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<CustomersDao>()) {
    getIt.registerLazySingleton<CustomersDao>(
      () => CustomersDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<SuppliersDao>()) {
    getIt.registerLazySingleton<SuppliersDao>(
      () => SuppliersDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<PurchasesDao>()) {
    getIt.registerLazySingleton<PurchasesDao>(
      () => PurchasesDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<SalesDao>()) {
    getIt.registerLazySingleton<SalesDao>(
      () => SalesDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<ReturnsDao>()) {
    getIt.registerLazySingleton<ReturnsDao>(
      () => ReturnsDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<AuditLogDao>()) {
    getIt.registerLazySingleton<AuditLogDao>(
      () => AuditLogDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<CashboxDao>()) {
    getIt.registerLazySingleton<CashboxDao>(
      () => CashboxDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<ExpensesDao>()) {
    getIt.registerLazySingleton<ExpensesDao>(
      () => ExpensesDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<CustomerPaymentsDao>()) {
    getIt.registerLazySingleton<CustomerPaymentsDao>(
      () => CustomerPaymentsDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<SupplierPaymentsDao>()) {
    getIt.registerLazySingleton<SupplierPaymentsDao>(
      () => SupplierPaymentsDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<SyncQueueDao>()) {
    getIt.registerLazySingleton<SyncQueueDao>(
      () => SyncQueueDao(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<NetworkInfo>()) {
    getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  }
  if (!getIt.isRegistered<SyncDispatcher>()) {
    getIt.registerLazySingleton<SyncDispatcher>(
      () => SyncDispatcher(
        syncQueueDao: getIt<SyncQueueDao>(),
        db: getIt<AppDatabase>(),
      ),
    );
  }
  if (!getIt.isRegistered<SyncService>()) {
    getIt.registerLazySingleton<SyncService>(
      () => SyncService(
        db: getIt<AppDatabase>(),
        syncQueueDao: getIt<SyncQueueDao>(),
        networkInfo: getIt<NetworkInfo>(),
        syncDispatcher: getIt<SyncDispatcher>(),
      ),
    );
  }

  // 3. Repositories
  if (!getIt.isRegistered<ProductRepository>()) {
    getIt.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(
        db: getIt<AppDatabase>(),
        dao: getIt<ProductsDao>(),
        syncDispatcher: getIt<SyncDispatcher>(),
      ),
    );
  }
  if (!getIt.isRegistered<InventoryRepository>()) {
    getIt.registerLazySingleton<InventoryRepository>(
      () => InventoryRepositoryImpl(
        db: getIt<AppDatabase>(),
        dao: getIt<InventoryMovementsDao>(),
        syncDispatcher: getIt<SyncDispatcher>(),
      ),
    );
  }
  if (!getIt.isRegistered<CustomerRepository>()) {
    getIt.registerLazySingleton<CustomerRepository>(
      () => CustomerRepositoryImpl(
        db: getIt<AppDatabase>(),
        dao: getIt<CustomersDao>(),
        syncDispatcher: getIt<SyncDispatcher>(),
      ),
    );
  }
  if (!getIt.isRegistered<SupplierRepository>()) {
    getIt.registerLazySingleton<SupplierRepository>(
      () => SupplierRepositoryImpl(
        db: getIt<AppDatabase>(),
        dao: getIt<SuppliersDao>(),
        syncDispatcher: getIt<SyncDispatcher>(),
      ),
    );
  }
  if (!getIt.isRegistered<PurchaseRepository>()) {
    getIt.registerLazySingleton<PurchaseRepository>(
      () => PurchaseRepositoryImpl(
        db: getIt<AppDatabase>(),
        dao: getIt<PurchasesDao>(),
        syncDispatcher: getIt<SyncDispatcher>(),
      ),
    );
  }
  if (!getIt.isRegistered<SaleRepository>()) {
    getIt.registerLazySingleton<SaleRepository>(
      () => SaleRepositoryImpl(
        db: getIt<AppDatabase>(),
        dao: getIt<SalesDao>(),
        syncDispatcher: getIt<SyncDispatcher>(),
      ),
    );
  }
  if (!getIt.isRegistered<ReturnRepository>()) {
    getIt.registerLazySingleton<ReturnRepository>(
      () => ReturnRepositoryImpl(
        db: getIt<AppDatabase>(),
        dao: getIt<ReturnsDao>(),
        syncDispatcher: getIt<SyncDispatcher>(),
      ),
    );
  }
  if (!getIt.isRegistered<OpeningBalanceRepository>()) {
    getIt.registerLazySingleton<OpeningBalanceRepository>(
      () => OpeningBalanceRepositoryImpl(
        getIt<AppDatabase>(),
        getIt<SyncDispatcher>(),
      ),
    );
  }
  if (!getIt.isRegistered<CashboxRepository>()) {
    getIt.registerLazySingleton<CashboxRepository>(
      () => CashboxRepositoryImpl(getIt<CashboxDao>()),
    );
  }
  if (!getIt.isRegistered<ExpenseRepository>()) {
    getIt.registerLazySingleton<ExpenseRepository>(
      () => ExpenseRepositoryImpl(
        db: getIt<AppDatabase>(),
        dao: getIt<ExpensesDao>(),
        syncDispatcher: getIt<SyncDispatcher>(),
      ),
    );
  }
  if (!getIt.isRegistered<CustomerPaymentRepository>()) {
    getIt.registerLazySingleton<CustomerPaymentRepository>(
      () => CustomerPaymentRepositoryImpl(
        db: getIt<AppDatabase>(),
        dao: getIt<CustomerPaymentsDao>(),
        syncDispatcher: getIt<SyncDispatcher>(),
      ),
    );
  }
  if (!getIt.isRegistered<SupplierPaymentRepository>()) {
    getIt.registerLazySingleton<SupplierPaymentRepository>(
      () => SupplierPaymentRepositoryImpl(
        db: getIt<AppDatabase>(),
        dao: getIt<SupplierPaymentsDao>(),
        syncDispatcher: getIt<SyncDispatcher>(),
      ),
    );
  }

  // Services
  if (!getIt.isRegistered<BackupService>()) {
    getIt.registerLazySingleton<BackupService>(
      () => BackupService(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<RestoreService>()) {
    getIt.registerLazySingleton<RestoreService>(
      () => RestoreService(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<PrintService>()) {
    getIt.registerLazySingleton<PrintService>(
      () => const PrintService(),
    );
  }

  // Audit Log & Backup Repositories
  if (!getIt.isRegistered<AuditLogRepository>()) {
    getIt.registerLazySingleton<AuditLogRepository>(
      () => AuditLogRepositoryImpl(getIt<AuditLogDao>()),
    );
  }
  if (!getIt.isRegistered<BackupRepository>()) {
    getIt.registerLazySingleton<BackupRepository>(
      () => BackupRepositoryImpl(
        db: getIt<AppDatabase>(),
        backupService: getIt<BackupService>(),
        restoreService: getIt<RestoreService>(),
      ),
    );
  }

  // 4. Products UseCases
  if (!getIt.isRegistered<GetProductsUseCase>()) {
    getIt.registerLazySingleton<GetProductsUseCase>(
      () => GetProductsUseCase(getIt<ProductRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchProductsUseCase>()) {
    getIt.registerLazySingleton<WatchProductsUseCase>(
      () => WatchProductsUseCase(getIt<ProductRepository>()),
    );
  }
  if (!getIt.isRegistered<AddProductUseCase>()) {
    getIt.registerLazySingleton<AddProductUseCase>(
      () => AddProductUseCase(getIt<ProductRepository>()),
    );
  }
  if (!getIt.isRegistered<UpdateProductUseCase>()) {
    getIt.registerLazySingleton<UpdateProductUseCase>(
      () => UpdateProductUseCase(getIt<ProductRepository>()),
    );
  }
  if (!getIt.isRegistered<ToggleProductStatusUseCase>()) {
    getIt.registerLazySingleton<ToggleProductStatusUseCase>(
      () => ToggleProductStatusUseCase(getIt<ProductRepository>()),
    );
  }

  // 5. Inventory UseCases
  if (!getIt.isRegistered<GetInventoryMovementsUseCase>()) {
    getIt.registerLazySingleton<GetInventoryMovementsUseCase>(
      () => GetInventoryMovementsUseCase(getIt<InventoryRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchInventoryMovementsUseCase>()) {
    getIt.registerLazySingleton<WatchInventoryMovementsUseCase>(
      () => WatchInventoryMovementsUseCase(getIt<InventoryRepository>()),
    );
  }
  if (!getIt.isRegistered<RecordStockAdjustmentUseCase>()) {
    getIt.registerLazySingleton<RecordStockAdjustmentUseCase>(
      () => RecordStockAdjustmentUseCase(getIt<InventoryRepository>()),
    );
  }

  // 6. Customers UseCases
  if (!getIt.isRegistered<GetCustomersUseCase>()) {
    getIt.registerLazySingleton<GetCustomersUseCase>(
      () => GetCustomersUseCase(getIt<CustomerRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchCustomersUseCase>()) {
    getIt.registerLazySingleton<WatchCustomersUseCase>(
      () => WatchCustomersUseCase(getIt<CustomerRepository>()),
    );
  }
  if (!getIt.isRegistered<AddCustomerUseCase>()) {
    getIt.registerLazySingleton<AddCustomerUseCase>(
      () => AddCustomerUseCase(getIt<CustomerRepository>()),
    );
  }
  if (!getIt.isRegistered<UpdateCustomerUseCase>()) {
    getIt.registerLazySingleton<UpdateCustomerUseCase>(
      () => UpdateCustomerUseCase(getIt<CustomerRepository>()),
    );
  }
  if (!getIt.isRegistered<ToggleCustomerStatusUseCase>()) {
    getIt.registerLazySingleton<ToggleCustomerStatusUseCase>(
      () => ToggleCustomerStatusUseCase(getIt<CustomerRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchCustomerLedgerUseCase>()) {
    getIt.registerLazySingleton<WatchCustomerLedgerUseCase>(
      () => WatchCustomerLedgerUseCase(getIt<CustomerRepository>()),
    );
  }

  // 7. Suppliers UseCases
  if (!getIt.isRegistered<GetSuppliersUseCase>()) {
    getIt.registerLazySingleton<GetSuppliersUseCase>(
      () => GetSuppliersUseCase(getIt<SupplierRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchSuppliersUseCase>()) {
    getIt.registerLazySingleton<WatchSuppliersUseCase>(
      () => WatchSuppliersUseCase(getIt<SupplierRepository>()),
    );
  }
  if (!getIt.isRegistered<AddSupplierUseCase>()) {
    getIt.registerLazySingleton<AddSupplierUseCase>(
      () => AddSupplierUseCase(getIt<SupplierRepository>()),
    );
  }
  if (!getIt.isRegistered<UpdateSupplierUseCase>()) {
    getIt.registerLazySingleton<UpdateSupplierUseCase>(
      () => UpdateSupplierUseCase(getIt<SupplierRepository>()),
    );
  }
  if (!getIt.isRegistered<ToggleSupplierStatusUseCase>()) {
    getIt.registerLazySingleton<ToggleSupplierStatusUseCase>(
      () => ToggleSupplierStatusUseCase(getIt<SupplierRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchSupplierLedgerUseCase>()) {
    getIt.registerLazySingleton<WatchSupplierLedgerUseCase>(
      () => WatchSupplierLedgerUseCase(getIt<SupplierRepository>()),
    );
  }

  // 8. Opening Balances UseCases
  if (!getIt.isRegistered<CheckOpeningBalanceStatusUseCase>()) {
    getIt.registerLazySingleton<CheckOpeningBalanceStatusUseCase>(
      () => CheckOpeningBalanceStatusUseCase(getIt<OpeningBalanceRepository>()),
    );
  }
  if (!getIt.isRegistered<SaveOpeningBalancesUseCase>()) {
    getIt.registerLazySingleton<SaveOpeningBalancesUseCase>(
      () => SaveOpeningBalancesUseCase(getIt<OpeningBalanceRepository>()),
    );
  }

  // 9. Purchases UseCases
  if (!getIt.isRegistered<CreatePurchaseUseCase>()) {
    getIt.registerLazySingleton<CreatePurchaseUseCase>(
      () => CreatePurchaseUseCase(getIt<PurchaseRepository>()),
    );
  }
  if (!getIt.isRegistered<GetPurchasesUseCase>()) {
    getIt.registerLazySingleton<GetPurchasesUseCase>(
      () => GetPurchasesUseCase(getIt<PurchaseRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchPurchasesUseCase>()) {
    getIt.registerLazySingleton<WatchPurchasesUseCase>(
      () => WatchPurchasesUseCase(getIt<PurchaseRepository>()),
    );
  }
  if (!getIt.isRegistered<ReversePurchaseUseCase>()) {
    getIt.registerLazySingleton<ReversePurchaseUseCase>(
      () => ReversePurchaseUseCase(getIt<PurchaseRepository>()),
    );
  }

  // 10. Sales UseCases
  if (!getIt.isRegistered<CreateSaleUseCase>()) {
    getIt.registerLazySingleton<CreateSaleUseCase>(
      () => CreateSaleUseCase(getIt<SaleRepository>()),
    );
  }
  if (!getIt.isRegistered<GetSalesUseCase>()) {
    getIt.registerLazySingleton<GetSalesUseCase>(
      () => GetSalesUseCase(getIt<SaleRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchSalesUseCase>()) {
    getIt.registerLazySingleton<WatchSalesUseCase>(
      () => WatchSalesUseCase(getIt<SaleRepository>()),
    );
  }
  if (!getIt.isRegistered<GetSaleByIdUseCase>()) {
    getIt.registerLazySingleton<GetSaleByIdUseCase>(
      () => GetSaleByIdUseCase(getIt<SaleRepository>()),
    );
  }
  if (!getIt.isRegistered<ReverseSaleUseCase>()) {
    getIt.registerLazySingleton<ReverseSaleUseCase>(
      () => ReverseSaleUseCase(getIt<SaleRepository>()),
    );
  }

  // 11. Returns UseCases
  if (!getIt.isRegistered<CreateCustomerReturnUseCase>()) {
    getIt.registerLazySingleton<CreateCustomerReturnUseCase>(
      () => CreateCustomerReturnUseCase(getIt<ReturnRepository>()),
    );
  }
  if (!getIt.isRegistered<CreateSupplierReturnUseCase>()) {
    getIt.registerLazySingleton<CreateSupplierReturnUseCase>(
      () => CreateSupplierReturnUseCase(getIt<ReturnRepository>()),
    );
  }
  if (!getIt.isRegistered<GetCustomerReturnsUseCase>()) {
    getIt.registerLazySingleton<GetCustomerReturnsUseCase>(
      () => GetCustomerReturnsUseCase(getIt<ReturnRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchCustomerReturnsUseCase>()) {
    getIt.registerLazySingleton<WatchCustomerReturnsUseCase>(
      () => WatchCustomerReturnsUseCase(getIt<ReturnRepository>()),
    );
  }
  if (!getIt.isRegistered<GetSupplierReturnsUseCase>()) {
    getIt.registerLazySingleton<GetSupplierReturnsUseCase>(
      () => GetSupplierReturnsUseCase(getIt<ReturnRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchSupplierReturnsUseCase>()) {
    getIt.registerLazySingleton<WatchSupplierReturnsUseCase>(
      () => WatchSupplierReturnsUseCase(getIt<ReturnRepository>()),
    );
  }

  // 12. Audit Log UseCases
  if (!getIt.isRegistered<GetAuditLogsUseCase>()) {
    getIt.registerLazySingleton<GetAuditLogsUseCase>(
      () => GetAuditLogsUseCase(getIt<AuditLogRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchAuditLogsUseCase>()) {
    getIt.registerLazySingleton<WatchAuditLogsUseCase>(
      () => WatchAuditLogsUseCase(getIt<AuditLogRepository>()),
    );
  }

  // 13. Backup & Restore UseCases
  if (!getIt.isRegistered<CreateManualBackupUseCase>()) {
    getIt.registerLazySingleton<CreateManualBackupUseCase>(
      () => CreateManualBackupUseCase(getIt<BackupRepository>()),
    );
  }
  if (!getIt.isRegistered<ExportBackupUseCase>()) {
    getIt.registerLazySingleton<ExportBackupUseCase>(
      () => ExportBackupUseCase(getIt<BackupRepository>()),
    );
  }
  if (!getIt.isRegistered<CreateAutoBackupUseCase>()) {
    getIt.registerLazySingleton<CreateAutoBackupUseCase>(
      () => CreateAutoBackupUseCase(getIt<BackupRepository>()),
    );
  }
  if (!getIt.isRegistered<RestoreBackupUseCase>()) {
    getIt.registerLazySingleton<RestoreBackupUseCase>(
      () => RestoreBackupUseCase(getIt<BackupRepository>()),
    );
  }
  if (!getIt.isRegistered<GetBackupHistoryUseCase>()) {
    getIt.registerLazySingleton<GetBackupHistoryUseCase>(
      () => GetBackupHistoryUseCase(getIt<BackupRepository>()),
    );
  }
  if (!getIt.isRegistered<ManageBackupSettingsUseCase>()) {
    getIt.registerLazySingleton<ManageBackupSettingsUseCase>(
      () => ManageBackupSettingsUseCase(getIt<BackupRepository>()),
    );
  }

  // 14. Cashbox UseCases
  if (!getIt.isRegistered<WatchCashboxTransactionsUseCase>()) {
    getIt.registerLazySingleton<WatchCashboxTransactionsUseCase>(
      () => WatchCashboxTransactionsUseCase(getIt<CashboxRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchCashboxBalanceUseCase>()) {
    getIt.registerLazySingleton<WatchCashboxBalanceUseCase>(
      () => WatchCashboxBalanceUseCase(getIt<CashboxRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchCashboxSummaryUseCase>()) {
    getIt.registerLazySingleton<WatchCashboxSummaryUseCase>(
      () => WatchCashboxSummaryUseCase(getIt<CashboxRepository>()),
    );
  }
  if (!getIt.isRegistered<GetCashboxSummaryUseCase>()) {
    getIt.registerLazySingleton<GetCashboxSummaryUseCase>(
      () => GetCashboxSummaryUseCase(getIt<CashboxRepository>()),
    );
  }

  // 15. Expenses UseCases
  if (!getIt.isRegistered<RecordExpenseUseCase>()) {
    getIt.registerLazySingleton<RecordExpenseUseCase>(
      () => RecordExpenseUseCase(getIt<ExpenseRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchExpensesUseCase>()) {
    getIt.registerLazySingleton<WatchExpensesUseCase>(
      () => WatchExpensesUseCase(getIt<ExpenseRepository>()),
    );
  }
  if (!getIt.isRegistered<GetExpensesUseCase>()) {
    getIt.registerLazySingleton<GetExpensesUseCase>(
      () => GetExpensesUseCase(getIt<ExpenseRepository>()),
    );
  }

  // 16. Reports Repository & UseCases
  if (!getIt.isRegistered<ReportRepository>()) {
    getIt.registerLazySingleton<ReportRepository>(
      () => ReportRepositoryImpl(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<GetSalesReportUseCase>()) {
    getIt.registerLazySingleton<GetSalesReportUseCase>(
      () => GetSalesReportUseCase(getIt<ReportRepository>()),
    );
  }
  if (!getIt.isRegistered<GetCollectionsReportUseCase>()) {
    getIt.registerLazySingleton<GetCollectionsReportUseCase>(
      () => GetCollectionsReportUseCase(getIt<ReportRepository>()),
    );
  }
  if (!getIt.isRegistered<GetCustomerReportUseCase>()) {
    getIt.registerLazySingleton<GetCustomerReportUseCase>(
      () => GetCustomerReportUseCase(getIt<ReportRepository>()),
    );
  }
  if (!getIt.isRegistered<GetAllCustomerBalancesUseCase>()) {
    getIt.registerLazySingleton<GetAllCustomerBalancesUseCase>(
      () => GetAllCustomerBalancesUseCase(getIt<ReportRepository>()),
    );
  }
  if (!getIt.isRegistered<GetSupplierReportUseCase>()) {
    getIt.registerLazySingleton<GetSupplierReportUseCase>(
      () => GetSupplierReportUseCase(getIt<ReportRepository>()),
    );
  }
  if (!getIt.isRegistered<GetAllSupplierBalancesUseCase>()) {
    getIt.registerLazySingleton<GetAllSupplierBalancesUseCase>(
      () => GetAllSupplierBalancesUseCase(getIt<ReportRepository>()),
    );
  }
  if (!getIt.isRegistered<GetInventoryReportUseCase>()) {
    getIt.registerLazySingleton<GetInventoryReportUseCase>(
      () => GetInventoryReportUseCase(getIt<ReportRepository>()),
    );
  }
  if (!getIt.isRegistered<GetCashboxReportUseCase>()) {
    getIt.registerLazySingleton<GetCashboxReportUseCase>(
      () => GetCashboxReportUseCase(getIt<ReportRepository>()),
    );
  }
  if (!getIt.isRegistered<GetProfitReportUseCase>()) {
    getIt.registerLazySingleton<GetProfitReportUseCase>(
      () => GetProfitReportUseCase(getIt<ReportRepository>()),
    );
  }

  // 17. Reports Cubit
  if (!getIt.isRegistered<ReportsCubit>()) {
    getIt.registerFactory<ReportsCubit>(
      () => ReportsCubit(
        getSalesReport: getIt(),
        getCollectionsReport: getIt(),
        getCustomerReport: getIt(),
        getAllCustomerBalances: getIt(),
        getSupplierReport: getIt(),
        getAllSupplierBalances: getIt(),
        getInventoryReport: getIt(),
        getCashboxReport: getIt(),
        getProfitReport: getIt(),
      ),
    );
  }

  // 18. Customer & Supplier Payments
  if (!getIt.isRegistered<RecordCustomerPaymentUseCase>()) {
    getIt.registerLazySingleton<RecordCustomerPaymentUseCase>(
      () => RecordCustomerPaymentUseCase(getIt<CustomerPaymentRepository>()),
    );
  }
  if (!getIt.isRegistered<GetCustomerPaymentsUseCase>()) {
    getIt.registerLazySingleton<GetCustomerPaymentsUseCase>(
      () => GetCustomerPaymentsUseCase(getIt<CustomerPaymentRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchCustomerPaymentsUseCase>()) {
    getIt.registerLazySingleton<WatchCustomerPaymentsUseCase>(
      () => WatchCustomerPaymentsUseCase(getIt<CustomerPaymentRepository>()),
    );
  }
  if (!getIt.isRegistered<CustomerPaymentsCubit>()) {
    getIt.registerFactory<CustomerPaymentsCubit>(
      () => CustomerPaymentsCubit(
        recordPaymentUseCase: getIt<RecordCustomerPaymentUseCase>(),
        watchPaymentsUseCase: getIt<WatchCustomerPaymentsUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<RecordSupplierPaymentUseCase>()) {
    getIt.registerLazySingleton<RecordSupplierPaymentUseCase>(
      () => RecordSupplierPaymentUseCase(getIt<SupplierPaymentRepository>()),
    );
  }
  if (!getIt.isRegistered<GetSupplierPaymentsUseCase>()) {
    getIt.registerLazySingleton<GetSupplierPaymentsUseCase>(
      () => GetSupplierPaymentsUseCase(getIt<SupplierPaymentRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchSupplierPaymentsUseCase>()) {
    getIt.registerLazySingleton<WatchSupplierPaymentsUseCase>(
      () => WatchSupplierPaymentsUseCase(getIt<SupplierPaymentRepository>()),
    );
  }
  if (!getIt.isRegistered<SupplierPaymentsCubit>()) {
    getIt.registerFactory<SupplierPaymentsCubit>(
      () => SupplierPaymentsCubit(
        recordPaymentUseCase: getIt<RecordSupplierPaymentUseCase>(),
        watchPaymentsUseCase: getIt<WatchSupplierPaymentsUseCase>(),
      ),
    );
  }

  // 19. Theme Cubit
  if (!getIt.isRegistered<ThemeCubit>()) {
    getIt.registerLazySingleton<ThemeCubit>(
      () => ThemeCubit(getIt<AppDatabase>()),
    );
  }

  // 20. Dashboard
  if (!getIt.isRegistered<DashboardRepository>()) {
    getIt.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<GetDashboardDataUseCase>()) {
    getIt.registerLazySingleton<GetDashboardDataUseCase>(
      () => GetDashboardDataUseCase(getIt<DashboardRepository>()),
    );
  }
  if (!getIt.isRegistered<WatchDashboardDataUseCase>()) {
    getIt.registerLazySingleton<WatchDashboardDataUseCase>(
      () => WatchDashboardDataUseCase(getIt<DashboardRepository>()),
    );
  }
  if (!getIt.isRegistered<DashboardCubit>()) {
    getIt.registerFactory<DashboardCubit>(
      () => DashboardCubit(
        watchDashboardData: getIt<WatchDashboardDataUseCase>(),
        getDashboardData: getIt<GetDashboardDataUseCase>(),
      ),
    );
  }

  // 21. Remote Updates
  if (!getIt.isRegistered<UpdateRemoteDataSource>()) {
    getIt.registerLazySingleton<UpdateRemoteDataSource>(
      () => UpdateRemoteDataSourceImpl(),
    );
  }
  if (!getIt.isRegistered<UpdateLocalDataSource>()) {
    getIt.registerLazySingleton<UpdateLocalDataSource>(
      () => UpdateLocalDataSourceImpl(),
    );
  }
  if (!getIt.isRegistered<UpdateRepository>()) {
    getIt.registerLazySingleton<UpdateRepository>(
      () => UpdateRepositoryImpl(
        remote: getIt<UpdateRemoteDataSource>(),
        local: getIt<UpdateLocalDataSource>(),
      ),
    );
  }
  if (!getIt.isRegistered<CheckForUpdateUseCase>()) {
    getIt.registerLazySingleton<CheckForUpdateUseCase>(
      () => CheckForUpdateUseCase(getIt<UpdateRepository>()),
    );
  }
  if (!getIt.isRegistered<DownloadUpdateUseCase>()) {
    getIt.registerLazySingleton<DownloadUpdateUseCase>(
      () => DownloadUpdateUseCase(getIt<UpdateRepository>()),
    );
  }
  if (!getIt.isRegistered<ApplyUpdateUseCase>()) {
    getIt.registerLazySingleton<ApplyUpdateUseCase>(
      () => ApplyUpdateUseCase(getIt<UpdateRepository>()),
    );
  }
  if (!getIt.isRegistered<GetCurrentVersionUseCase>()) {
    getIt.registerLazySingleton<GetCurrentVersionUseCase>(
      () => GetCurrentVersionUseCase(getIt<UpdateRepository>()),
    );
  }
  if (!getIt.isRegistered<UpdateCubit>()) {
    getIt.registerLazySingleton<UpdateCubit>(
      () => UpdateCubit(
        checkForUpdateUseCase: getIt<CheckForUpdateUseCase>(),
        downloadUpdateUseCase: getIt<DownloadUpdateUseCase>(),
        applyUpdateUseCase: getIt<ApplyUpdateUseCase>(),
        getCurrentVersionUseCase: getIt<GetCurrentVersionUseCase>(),
      ),
    );
  }
}

