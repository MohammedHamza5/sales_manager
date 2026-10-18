import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/supplier_ledger_entry.dart';
import '../../domain/usecases/watch_supplier_ledger_usecase.dart';
import 'supplier_ledger_state.dart';

class SupplierLedgerCubit extends Cubit<SupplierLedgerState> {
  final WatchSupplierLedgerUseCase _watchSupplierLedgerUseCase;
  final int supplierId;

  StreamSubscription<List<SupplierLedgerEntry>>? _subscription;
  SupplierLedgerEntryType? _currentFilterType;

  SupplierLedgerCubit({
    required WatchSupplierLedgerUseCase watchSupplierLedgerUseCase,
    required this.supplierId,
  })  : _watchSupplierLedgerUseCase = watchSupplierLedgerUseCase,
        super(const SupplierLedgerInitial());

  void init() {
    emit(const SupplierLedgerLoading());
    _subscription?.cancel();
    _subscription = _watchSupplierLedgerUseCase(supplierId).listen(
      _onEntriesEmitted,
      onError: (Object error) {
        emit(SupplierLedgerError(message: 'فشل في تحميل كشف الحساب: $error'));
      },
    );
  }

  void _onEntriesEmitted(List<SupplierLedgerEntry> entries) {
    if (entries.isEmpty) {
      emit(
        SupplierLedgerEmpty(
          message: _currentFilterType != null
              ? 'لا توجد حركات مسجلة لهذا النوع المحدد'
              : 'لا توجد حركات مسجلة بكشف حساب المورد حتى الآن',
          hasFilter: _currentFilterType != null,
        ),
      );
      return;
    }

    emit(
      SupplierLedgerLoaded(
        entries: entries,
        filterEntryType: _currentFilterType,
      ),
    );
  }

  void setFilterType(SupplierLedgerEntryType? type) {
    _currentFilterType = type;
    final currentState = state;
    if (currentState is SupplierLedgerLoaded) {
      emit(currentState.copyWith(filterEntryType: () => type));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
