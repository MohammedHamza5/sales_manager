import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/customer_ledger_entry.dart';
import '../../domain/usecases/watch_customer_ledger_usecase.dart';
import 'customer_ledger_state.dart';

class CustomerLedgerCubit extends Cubit<CustomerLedgerState> {
  final WatchCustomerLedgerUseCase _watchCustomerLedgerUseCase;
  final int customerId;

  StreamSubscription<List<CustomerLedgerEntry>>? _subscription;
  CustomerLedgerEntryType? _currentFilterType;

  CustomerLedgerCubit({
    required WatchCustomerLedgerUseCase watchCustomerLedgerUseCase,
    required this.customerId,
  })  : _watchCustomerLedgerUseCase = watchCustomerLedgerUseCase,
        super(const CustomerLedgerInitial());

  void init() {
    emit(const CustomerLedgerLoading());
    _subscription?.cancel();
    _subscription = _watchCustomerLedgerUseCase(customerId).listen(
      _onEntriesEmitted,
      onError: (Object error) {
        emit(CustomerLedgerError(message: 'فشل في تحميل كشف الحساب: $error'));
      },
    );
  }

  void _onEntriesEmitted(List<CustomerLedgerEntry> entries) {
    if (entries.isEmpty) {
      emit(
        CustomerLedgerEmpty(
          message: _currentFilterType != null
              ? 'لا توجد حركات مسجلة لهذا النوع المحدد'
              : 'لا توجد حركات مسجلة بكشف حساب العميل حتى الآن',
          hasFilter: _currentFilterType != null,
        ),
      );
      return;
    }

    emit(
      CustomerLedgerLoaded(
        entries: entries,
        filterEntryType: _currentFilterType,
      ),
    );
  }

  void setFilterType(CustomerLedgerEntryType? type) {
    _currentFilterType = type;
    final currentState = state;
    if (currentState is CustomerLedgerLoaded) {
      emit(currentState.copyWith(filterEntryType: () => type));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
