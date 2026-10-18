import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/add_customer_usecase.dart';
import '../../domain/usecases/toggle_customer_status_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import '../../domain/usecases/watch_customers_usecase.dart';
import 'customers_state.dart';

class CustomersCubit extends Cubit<CustomersState> {
  final WatchCustomersUseCase _watchCustomersUseCase;
  final AddCustomerUseCase _addCustomerUseCase;
  final UpdateCustomerUseCase _updateCustomerUseCase;
  final ToggleCustomerStatusUseCase _toggleCustomerStatusUseCase;

  StreamSubscription<List<Customer>>? _subscription;

  CustomersCubit({
    required WatchCustomersUseCase watchCustomersUseCase,
    required AddCustomerUseCase addCustomerUseCase,
    required UpdateCustomerUseCase updateCustomerUseCase,
    required ToggleCustomerStatusUseCase toggleCustomerStatusUseCase,
  })  : _watchCustomersUseCase = watchCustomersUseCase,
        _addCustomerUseCase = addCustomerUseCase,
        _updateCustomerUseCase = updateCustomerUseCase,
        _toggleCustomerStatusUseCase = toggleCustomerStatusUseCase,
        super(const CustomersInitial());

  void init() {
    emit(const CustomersLoading());
    _subscription?.cancel();
    _subscription = _watchCustomersUseCase().listen(
      _onCustomersEmitted,
      onError: (Object error) {
        emit(CustomersError(message: error.toString()));
      },
    );
  }

  void _onCustomersEmitted(List<Customer> customers) {
    if (customers.isEmpty) {
      emit(const CustomersEmpty(
        message: 'لا يوجد عملاء مسجلون بالنظام حتى الآن',
        hasActiveFilters: false,
      ));
      return;
    }

    // Compute totals
    var totalDebtPiastres = 0;
    var debtorsCount = 0;
    var totalCreditPiastres = 0;
    var creditorsCount = 0;

    for (final c in customers) {
      if (c.hasDebt) {
        totalDebtPiastres += c.currentBalance.piastres;
        debtorsCount++;
      } else if (c.isCreditor) {
        totalCreditPiastres += c.currentBalance.abs().piastres;
        creditorsCount++;
      }
    }

    final currentState = state;
    if (currentState is CustomersLoaded) {
      emit(currentState.copyWith(
        customers: customers,
        totalDebtAmount: Money.fromPiastres(totalDebtPiastres),
        totalDebtorsCount: debtorsCount,
        totalCreditAmount: Money.fromPiastres(totalCreditPiastres),
        totalCreditorsCount: creditorsCount,
      ));
    } else {
      emit(CustomersLoaded(
        customers: customers,
        totalDebtAmount: Money.fromPiastres(totalDebtPiastres),
        totalDebtorsCount: debtorsCount,
        totalCreditAmount: Money.fromPiastres(totalCreditPiastres),
        totalCreditorsCount: creditorsCount,
      ));
    }
  }

  void search(String query) {
    final currentState = state;
    if (currentState is CustomersLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void toggleDebtorsFilter() {
    final currentState = state;
    if (currentState is CustomersLoaded) {
      emit(currentState.copyWith(
        showDebtorsOnly: !currentState.showDebtorsOnly,
        showCreditorsOnly: false,
      ));
    }
  }

  void toggleCreditorsFilter() {
    final currentState = state;
    if (currentState is CustomersLoaded) {
      emit(currentState.copyWith(
        showCreditorsOnly: !currentState.showCreditorsOnly,
        showDebtorsOnly: false,
      ));
    }
  }

  void setActiveFilter(bool? activeFilter) {
    final currentState = state;
    if (currentState is CustomersLoaded) {
      emit(currentState.copyWith(activeFilter: () => activeFilter));
    }
  }

  Future<Result<Customer>> addCustomer({
    required String name,
    String? phone,
    String? address,
    String? notes,
    Money initialBalance = Money.zero,
    String createdBy = 'admin',
  }) {
    return _addCustomerUseCase(
      name: name,
      phone: phone,
      address: address,
      notes: notes,
      initialBalance: initialBalance,
      createdBy: createdBy,
    );
  }

  Future<Result<Customer>> updateCustomer(Customer customer) {
    return _updateCustomerUseCase(customer);
  }

  Future<Result<void>> toggleCustomerStatus(int id, bool isActive) {
    return _toggleCustomerStatusUseCase(id, isActive);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
