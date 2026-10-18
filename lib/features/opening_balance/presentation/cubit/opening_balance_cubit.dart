import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money.dart';
import '../../../customers/domain/usecases/get_customers_usecase.dart';
import '../../../products/domain/usecases/get_products_usecase.dart';
import '../../../suppliers/domain/usecases/get_suppliers_usecase.dart';
import '../../domain/entities/opening_balance_input.dart';
import '../../domain/usecases/check_opening_balance_status_usecase.dart';
import '../../domain/usecases/save_opening_balances_usecase.dart';
import 'opening_balance_state.dart';

class OpeningBalanceCubit extends Cubit<OpeningBalanceState> {
  final CheckOpeningBalanceStatusUseCase _checkStatusUseCase;
  final SaveOpeningBalancesUseCase _saveOpeningBalancesUseCase;
  final GetProductsUseCase _getProductsUseCase;
  final GetCustomersUseCase _getCustomersUseCase;
  final GetSuppliersUseCase _getSuppliersUseCase;

  OpeningBalanceCubit({
    required CheckOpeningBalanceStatusUseCase checkStatusUseCase,
    required SaveOpeningBalancesUseCase saveOpeningBalancesUseCase,
    required GetProductsUseCase getProductsUseCase,
    required GetCustomersUseCase getCustomersUseCase,
    required GetSuppliersUseCase getSuppliersUseCase,
  })  : _checkStatusUseCase = checkStatusUseCase,
        _saveOpeningBalancesUseCase = saveOpeningBalancesUseCase,
        _getProductsUseCase = getProductsUseCase,
        _getCustomersUseCase = getCustomersUseCase,
        _getSuppliersUseCase = getSuppliersUseCase,
        super(const OpeningBalanceInitial());

  Future<void> init() async {
    emit(const OpeningBalanceLoading());

    // 1. Check if already committed
    final statusResult = await _checkStatusUseCase();
    if (statusResult.isSuccess && statusResult.dataOrNull == true) {
      emit(const OpeningBalanceAlreadySaved());
      return;
    }

    // 2. Fetch active products, customers, suppliers
    final productsResult = await _getProductsUseCase(isActiveOnly: true);
    final customersResult = await _getCustomersUseCase(isActiveOnly: true);
    final suppliersResult = await _getSuppliersUseCase(isActiveOnly: true);

    if (productsResult.isFailure) {
      emit(OpeningBalanceError(
        message: productsResult.failureOrNull?.message ?? 'فشل في تحميل قائمة المنتجات',
      ));
      return;
    }

    if (customersResult.isFailure) {
      emit(OpeningBalanceError(
        message: customersResult.failureOrNull?.message ?? 'فشل في تحميل قائمة العملاء',
      ));
      return;
    }

    if (suppliersResult.isFailure) {
      emit(OpeningBalanceError(
        message: suppliersResult.failureOrNull?.message ?? 'فشل في تحميل قائمة الموردين',
      ));
      return;
    }

    final productRows = productsResult.dataOrNull!
        .map((p) => ProductOpeningBalance(
              productId: p.id,
              productName: p.name,
              code: p.code,
              unit: p.unit,
              initialQuantity: Decimal.zero,
            ))
        .toList();

    final customerRows = customersResult.dataOrNull!
        .map((c) => StakeholderOpeningBalance(
              stakeholderId: c.id,
              name: c.name,
              phone: c.phone,
              balance: Money.zero,
            ))
        .toList();

    final supplierRows = suppliersResult.dataOrNull!
        .map((s) => StakeholderOpeningBalance(
              stakeholderId: s.id,
              name: s.name,
              phone: s.phone,
              balance: Money.zero,
            ))
        .toList();

    emit(OpeningBalanceReady(
      input: OpeningBalanceInput(
        cashboxBalance: Money.zero,
        products: productRows,
        customers: customerRows,
        suppliers: supplierRows,
      ),
    ));
  }

  void setTab(int index) {
    final currentState = state;
    if (currentState is OpeningBalanceReady) {
      emit(currentState.copyWith(activeTabIndex: index));
    }
  }

  void setCashboxBalance(Money balance) {
    final currentState = state;
    if (currentState is OpeningBalanceReady) {
      emit(currentState.copyWith(
        input: currentState.input.copyWith(cashboxBalance: balance),
        submitError: () => null,
      ));
    }
  }

  void updateProductQuantity(int productId, Decimal quantity) {
    final currentState = state;
    if (currentState is OpeningBalanceReady) {
      final updatedList = currentState.input.products.map((p) {
        if (p.productId == productId) {
          return p.copyWith(initialQuantity: quantity);
        }
        return p;
      }).toList();

      emit(currentState.copyWith(
        input: currentState.input.copyWith(products: updatedList),
        submitError: () => null,
      ));
    }
  }

  void updateCustomerBalance(int customerId, Money balance) {
    final currentState = state;
    if (currentState is OpeningBalanceReady) {
      final updatedList = currentState.input.customers.map((c) {
        if (c.stakeholderId == customerId) {
          return c.copyWith(balance: balance);
        }
        return c;
      }).toList();

      emit(currentState.copyWith(
        input: currentState.input.copyWith(customers: updatedList),
        submitError: () => null,
      ));
    }
  }

  void updateSupplierBalance(int supplierId, Money balance) {
    final currentState = state;
    if (currentState is OpeningBalanceReady) {
      final updatedList = currentState.input.suppliers.map((s) {
        if (s.stakeholderId == supplierId) {
          return s.copyWith(balance: balance);
        }
        return s;
      }).toList();

      emit(currentState.copyWith(
        input: currentState.input.copyWith(suppliers: updatedList),
        submitError: () => null,
      ));
    }
  }

  Future<void> submit({String createdBy = 'admin'}) async {
    final currentState = state;
    if (currentState is! OpeningBalanceReady || currentState.isSubmitting) {
      return;
    }

    emit(currentState.copyWith(
      isSubmitting: true,
      submitError: () => null,
    ));

    final result = await _saveOpeningBalancesUseCase(
      currentState.input,
      createdBy: createdBy,
    );

    if (result.isSuccess) {
      emit(const OpeningBalanceSuccess());
    } else {
      emit(currentState.copyWith(
        isSubmitting: false,
        submitError: () => result.failureOrNull?.message ?? 'حدث خطأ أثناء حفظ الأرصدة الافتتاحية',
      ));
    }
  }
}
