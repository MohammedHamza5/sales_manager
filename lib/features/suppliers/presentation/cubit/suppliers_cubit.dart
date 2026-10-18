import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/add_supplier_usecase.dart';
import '../../domain/usecases/toggle_supplier_status_usecase.dart';
import '../../domain/usecases/update_supplier_usecase.dart';
import '../../domain/usecases/watch_suppliers_usecase.dart';
import 'suppliers_state.dart';

class SuppliersCubit extends Cubit<SuppliersState> {
  final WatchSuppliersUseCase _watchSuppliersUseCase;
  final AddSupplierUseCase _addSupplierUseCase;
  final UpdateSupplierUseCase _updateSupplierUseCase;
  final ToggleSupplierStatusUseCase _toggleSupplierStatusUseCase;

  StreamSubscription<List<Supplier>>? _subscription;

  SuppliersCubit({
    required WatchSuppliersUseCase watchSuppliersUseCase,
    required AddSupplierUseCase addSupplierUseCase,
    required UpdateSupplierUseCase updateSupplierUseCase,
    required ToggleSupplierStatusUseCase toggleSupplierStatusUseCase,
  })  : _watchSuppliersUseCase = watchSuppliersUseCase,
        _addSupplierUseCase = addSupplierUseCase,
        _updateSupplierUseCase = updateSupplierUseCase,
        _toggleSupplierStatusUseCase = toggleSupplierStatusUseCase,
        super(const SuppliersInitial());

  void init() {
    emit(const SuppliersLoading());
    _subscription?.cancel();
    _subscription = _watchSuppliersUseCase().listen(
      _onSuppliersEmitted,
      onError: (Object error) {
        emit(SuppliersError(message: error.toString()));
      },
    );
  }

  void _onSuppliersEmitted(List<Supplier> suppliers) {
    if (suppliers.isEmpty) {
      emit(const SuppliersEmpty(
        message: 'لا يوجد موردون مسجلون بالنظام حتى الآن',
        hasActiveFilters: false,
      ));
      return;
    }

    // Compute totals
    var totalDuePiastres = 0;
    var dueCount = 0;

    for (final s in suppliers) {
      if (s.hasBalanceDue) {
        totalDuePiastres += s.currentBalance.piastres;
        dueCount++;
      }
    }

    final currentState = state;
    if (currentState is SuppliersLoaded) {
      emit(currentState.copyWith(
        suppliers: suppliers,
        totalDueAmount: Money.fromPiastres(totalDuePiastres),
        totalDueSuppliersCount: dueCount,
      ));
    } else {
      emit(SuppliersLoaded(
        suppliers: suppliers,
        totalDueAmount: Money.fromPiastres(totalDuePiastres),
        totalDueSuppliersCount: dueCount,
      ));
    }
  }

  void search(String query) {
    final currentState = state;
    if (currentState is SuppliersLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void toggleDueFilter() {
    final currentState = state;
    if (currentState is SuppliersLoaded) {
      emit(currentState.copyWith(showDueOnly: !currentState.showDueOnly));
    }
  }

  void setActiveFilter(bool? activeFilter) {
    final currentState = state;
    if (currentState is SuppliersLoaded) {
      emit(currentState.copyWith(activeFilter: () => activeFilter));
    }
  }

  Future<Result<Supplier>> addSupplier({
    required String name,
    String? phone,
    String? address,
    String? notes,
    Money initialBalance = Money.zero,
    String createdBy = 'admin',
  }) {
    return _addSupplierUseCase(
      name: name,
      phone: phone,
      address: address,
      notes: notes,
      initialBalance: initialBalance,
      createdBy: createdBy,
    );
  }

  Future<Result<Supplier>> updateSupplier(Supplier supplier) {
    return _updateSupplierUseCase(supplier);
  }

  Future<Result<void>> toggleSupplierStatus(int id, bool isActive) {
    return _toggleSupplierStatusUseCase(id, isActive);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
