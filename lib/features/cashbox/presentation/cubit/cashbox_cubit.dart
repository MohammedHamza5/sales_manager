import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/cashbox_summary.dart';
import '../../domain/entities/cashbox_transaction_entity.dart';
import '../../domain/usecases/watch_cashbox_balance_usecase.dart';
import '../../domain/usecases/watch_cashbox_summary_usecase.dart';
import '../../domain/usecases/watch_cashbox_transactions_usecase.dart';
import 'cashbox_state.dart';

class CashboxCubit extends Cubit<CashboxState> {
  final WatchCashboxTransactionsUseCase _watchTransactions;
  final WatchCashboxBalanceUseCase _watchBalance;
  final WatchCashboxSummaryUseCase _watchSummary;

  StreamSubscription<List<CashboxTransactionEntity>>? _transactionsSub;
  StreamSubscription<Money>? _balanceSub;
  StreamSubscription<CashboxSummary>? _summarySub;

  List<CashboxTransactionEntity> _currentTransactions = [];
  Money _currentBalance = Money.zero;
  CashboxSummary _currentSummary = CashboxSummary.empty;

  CashboxCubit({
    required WatchCashboxTransactionsUseCase watchTransactions,
    required WatchCashboxBalanceUseCase watchBalance,
    required WatchCashboxSummaryUseCase watchSummary,
  })  : _watchTransactions = watchTransactions,
        _watchBalance = watchBalance,
        _watchSummary = watchSummary,
        super(const CashboxInitial());

  void init() {
    emit(const CashboxLoading());

    _cancelSubscriptions();

    // 1. Watch Balance
    _balanceSub = _watchBalance().listen(
      (balance) {
        _currentBalance = balance;
        _emitLoaded();
      },
      onError: (Object error) {
        emit(CashboxError(message: 'حدث خطأ أثناء متابعة رصيد الخزينة: $error'));
      },
    );

    // 2. Watch Today's Summary
    _summarySub = _watchSummary(DateTime.now()).listen(
      (summary) {
        _currentSummary = summary;
        _emitLoaded();
      },
      onError: (Object error) {
        emit(CashboxError(message: 'حدث خطأ أثناء متابعة ملخص الخزينة: $error'));
      },
    );

    // 3. Watch Transactions
    _transactionsSub = _watchTransactions().listen(
      (transactions) {
        _currentTransactions = transactions;
        _emitLoaded();
      },
      onError: (Object error) {
        emit(CashboxError(message: 'حدث خطأ أثناء متابعة حركات الخزينة: $error'));
      },
    );
  }

  void _emitLoaded() {
    final currentState = state;
    if (currentState is CashboxLoaded) {
      emit(currentState.copyWith(
        transactions: _currentTransactions,
        currentBalance: _currentBalance,
        dailySummary: _currentSummary,
      ));
    } else {
      emit(CashboxLoaded(
        transactions: _currentTransactions,
        currentBalance: _currentBalance,
        dailySummary: _currentSummary,
      ));
    }
  }

  void setDirectionFilter(String? direction) {
    final currentState = state;
    if (currentState is CashboxLoaded) {
      emit(currentState.copyWith(directionFilter: () => direction));
    }
  }

  void setTypeFilter(String? type) {
    final currentState = state;
    if (currentState is CashboxLoaded) {
      emit(currentState.copyWith(typeFilter: () => type));
    }
  }

  void setDateRange(DateTime? from, DateTime? to) {
    final currentState = state;
    if (currentState is CashboxLoaded) {
      emit(currentState.copyWith(
        fromDate: () => from,
        toDate: () => to,
      ));
    }
  }

  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is CashboxLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void resetFilters() {
    final currentState = state;
    if (currentState is CashboxLoaded) {
      emit(currentState.copyWith(
        directionFilter: () => null,
        typeFilter: () => null,
        fromDate: () => null,
        toDate: () => null,
        searchQuery: '',
      ));
    }
  }

  void _cancelSubscriptions() {
    _transactionsSub?.cancel();
    _transactionsSub = null;
    _balanceSub?.cancel();
    _balanceSub = null;
    _summarySub?.cancel();
    _summarySub = null;
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
