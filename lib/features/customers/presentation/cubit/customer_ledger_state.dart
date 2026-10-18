import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/customer_ledger_entry.dart';

sealed class CustomerLedgerState extends Equatable {
  const CustomerLedgerState();

  @override
  List<Object?> get props => [];
}

final class CustomerLedgerInitial extends CustomerLedgerState {
  const CustomerLedgerInitial();
}

final class CustomerLedgerLoading extends CustomerLedgerState {
  const CustomerLedgerLoading();
}

final class CustomerLedgerEmpty extends CustomerLedgerState {
  final String message;
  final bool hasFilter;

  const CustomerLedgerEmpty({
    required this.message,
    this.hasFilter = false,
  });

  @override
  List<Object?> get props => [message, hasFilter];
}

final class CustomerLedgerError extends CustomerLedgerState {
  final String message;

  const CustomerLedgerError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class CustomerLedgerLoaded extends CustomerLedgerState {
  final List<CustomerLedgerEntry> entries;
  final CustomerLedgerEntryType? filterEntryType;

  const CustomerLedgerLoaded({
    required this.entries,
    this.filterEntryType,
  });

  List<CustomerLedgerEntry> get filteredEntries {
    if (filterEntryType == null) {
      return entries;
    }
    return entries.where((e) => e.entryType == filterEntryType).toList();
  }

  Money get totalDebit {
    var sum = 0;
    for (final e in entries) {
      if (e.isDebtIncrease) {
        sum += e.amount.piastres;
      }
    }
    return Money.fromPiastres(sum);
  }

  Money get totalCredit {
    var sum = 0;
    for (final e in entries) {
      if (e.isDebtDecrease) {
        sum += e.amount.piastres;
      }
    }
    return Money.fromPiastres(sum);
  }

  Money get netBalance => Money.fromPiastres(totalDebit.piastres - totalCredit.piastres);

  int get count => filteredEntries.length;

  CustomerLedgerLoaded copyWith({
    List<CustomerLedgerEntry>? entries,
    CustomerLedgerEntryType? Function()? filterEntryType,
  }) {
    return CustomerLedgerLoaded(
      entries: entries ?? this.entries,
      filterEntryType:
          filterEntryType != null ? filterEntryType() : this.filterEntryType,
    );
  }

  @override
  List<Object?> get props => [entries, filterEntryType];
}
