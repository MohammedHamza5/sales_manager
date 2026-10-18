import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/cashbox_summary.dart';
import '../../domain/entities/cashbox_transaction_entity.dart';

sealed class CashboxState extends Equatable {
  const CashboxState();

  @override
  List<Object?> get props => [];
}

final class CashboxInitial extends CashboxState {
  const CashboxInitial();
}

final class CashboxLoading extends CashboxState {
  const CashboxLoading();
}

final class CashboxLoaded extends CashboxState {
  final List<CashboxTransactionEntity> transactions;
  final Money currentBalance;
  final CashboxSummary dailySummary;
  final String? directionFilter; // 'in' | 'out' | null
  final String? typeFilter;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String searchQuery;

  const CashboxLoaded({
    required this.transactions,
    required this.currentBalance,
    required this.dailySummary,
    this.directionFilter,
    this.typeFilter,
    this.fromDate,
    this.toDate,
    this.searchQuery = '',
  });

  List<CashboxTransactionEntity> get filteredTransactions {
    return transactions.where((tx) {
      if (directionFilter != null && tx.direction != directionFilter) {
        return false;
      }
      if (typeFilter != null && tx.transactionType != typeFilter) {
        return false;
      }
      if (fromDate != null && tx.createdAt.isBefore(fromDate!)) {
        return false;
      }
      if (toDate != null && tx.createdAt.isAfter(toDate!)) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchesNote = tx.note?.toLowerCase().contains(q) ?? false;
        final matchesType = tx.transactionTypeArabic.toLowerCase().contains(q);
        final matchesAmount = tx.amount.formatArabic().contains(q) || tx.amount.pounds.toString().contains(q);
        if (!matchesNote && !matchesType && !matchesAmount) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  CashboxLoaded copyWith({
    List<CashboxTransactionEntity>? transactions,
    Money? currentBalance,
    CashboxSummary? dailySummary,
    String? Function()? directionFilter,
    String? Function()? typeFilter,
    DateTime? Function()? fromDate,
    DateTime? Function()? toDate,
    String? searchQuery,
  }) {
    return CashboxLoaded(
      transactions: transactions ?? this.transactions,
      currentBalance: currentBalance ?? this.currentBalance,
      dailySummary: dailySummary ?? this.dailySummary,
      directionFilter: directionFilter != null ? directionFilter() : this.directionFilter,
      typeFilter: typeFilter != null ? typeFilter() : this.typeFilter,
      fromDate: fromDate != null ? fromDate() : this.fromDate,
      toDate: toDate != null ? toDate() : this.toDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        transactions,
        currentBalance,
        dailySummary,
        directionFilter,
        typeFilter,
        fromDate,
        toDate,
        searchQuery,
      ];
}

final class CashboxError extends CashboxState {
  final String message;

  const CashboxError({required this.message});

  @override
  List<Object?> get props => [message];
}
