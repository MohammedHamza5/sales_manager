import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/supplier_ledger_entry.dart';

sealed class SupplierLedgerState extends Equatable {
  const SupplierLedgerState();

  @override
  List<Object?> get props => [];
}

final class SupplierLedgerInitial extends SupplierLedgerState {
  const SupplierLedgerInitial();
}

final class SupplierLedgerLoading extends SupplierLedgerState {
  const SupplierLedgerLoading();
}

final class SupplierLedgerEmpty extends SupplierLedgerState {
  final String message;
  final bool hasFilter;

  const SupplierLedgerEmpty({
    required this.message,
    this.hasFilter = false,
  });

  @override
  List<Object?> get props => [message, hasFilter];
}

final class SupplierLedgerError extends SupplierLedgerState {
  final String message;

  const SupplierLedgerError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class SupplierLedgerLoaded extends SupplierLedgerState {
  final List<SupplierLedgerEntry> entries;
  final SupplierLedgerEntryType? filterEntryType;

  const SupplierLedgerLoaded({
    required this.entries,
    this.filterEntryType,
  });

  List<SupplierLedgerEntry> get filteredEntries {
    if (filterEntryType == null) {
      return entries;
    }
    return entries.where((e) => e.entryType == filterEntryType).toList();
  }

  /// إجمالي المشتريات والمستحقات للمورد (دائن +)
  Money get totalCredit {
    var sum = 0;
    for (final e in entries) {
      if (e.isDueIncrease) {
        sum += e.amount.piastres;
      }
    }
    return Money.fromPiastres(sum);
  }

  /// إجمالي المدفوعات والسدادات للمورد (مدين -)
  Money get totalDebit {
    var sum = 0;
    for (final e in entries) {
      if (e.isDueDecrease) {
        sum += e.amount.piastres;
      }
    }
    return Money.fromPiastres(sum);
  }

  /// صافي الرصيد الحالي للمورد (المستحق له ناقص المدفوع)
  Money get netBalance => Money.fromPiastres(totalCredit.piastres - totalDebit.piastres);

  int get count => filteredEntries.length;

  SupplierLedgerLoaded copyWith({
    List<SupplierLedgerEntry>? entries,
    SupplierLedgerEntryType? Function()? filterEntryType,
  }) {
    return SupplierLedgerLoaded(
      entries: entries ?? this.entries,
      filterEntryType:
          filterEntryType != null ? filterEntryType() : this.filterEntryType,
    );
  }

  @override
  List<Object?> get props => [entries, filterEntryType];
}
