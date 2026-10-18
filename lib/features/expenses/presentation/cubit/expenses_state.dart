import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/expense.dart';

sealed class ExpensesState extends Equatable {
  const ExpensesState();

  @override
  List<Object?> get props => [];
}

final class ExpensesInitial extends ExpensesState {
  const ExpensesInitial();
}

final class ExpensesLoading extends ExpensesState {
  const ExpensesLoading();
}

final class ExpensesLoaded extends ExpensesState {
  final List<Expense> expenses;
  final String? categoryFilter;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String searchQuery;

  const ExpensesLoaded({
    required this.expenses,
    this.categoryFilter,
    this.fromDate,
    this.toDate,
    this.searchQuery = '',
  });

  /// Filtered expenses based on category, date range, and search query.
  List<Expense> get filteredExpenses {
    return expenses.where((e) {
      if (categoryFilter != null && e.category != categoryFilter) {
        return false;
      }
      if (fromDate != null && e.expenseDate.isBefore(fromDate!)) {
        return false;
      }
      if (toDate != null && e.expenseDate.isAfter(toDate!)) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchesCategory = e.category.toLowerCase().contains(q);
        final matchesNote = e.note?.toLowerCase().contains(q) ?? false;
        final matchesAmount =
            e.amount.formatArabic().contains(q) || e.amount.pounds.toString().contains(q);
        if (!matchesCategory && !matchesNote && !matchesAmount) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Total sum of all currently filtered expenses.
  Money get totalFilteredAmount {
    var sum = 0;
    for (final e in filteredExpenses) {
      sum += e.amount.piastres;
    }
    return Money.fromPiastres(sum);
  }

  /// Total expenses recorded today.
  Money get todayTotalAmount {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    var sum = 0;
    for (final e in expenses) {
      if (e.expenseDate.isAfter(startOfToday.subtract(const Duration(milliseconds: 1))) &&
          e.expenseDate.isBefore(endOfToday.add(const Duration(milliseconds: 1)))) {
        sum += e.amount.piastres;
      }
    }
    return Money.fromPiastres(sum);
  }

  /// Total expenses recorded this calendar month.
  Money get thisMonthTotalAmount {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

    var sum = 0;
    for (final e in expenses) {
      if (e.expenseDate.isAfter(startOfMonth.subtract(const Duration(milliseconds: 1))) &&
          e.expenseDate.isBefore(endOfMonth.add(const Duration(milliseconds: 1)))) {
        sum += e.amount.piastres;
      }
    }
    return Money.fromPiastres(sum);
  }

  /// Distinct categories present in expenses plus predefined categories.
  List<String> get allCategories {
    final defaultCategories = [
      'إيجار',
      'كهرباء',
      'مرتبات',
      'بوفيه وضيافة',
      'نقل وشحن',
      'صيانة',
      'أدوات ومهمات',
      'متنوعات',
    ];
    final categorySet = Set<String>.from(defaultCategories);
    for (final e in expenses) {
      if (e.category.trim().isNotEmpty) {
        categorySet.add(e.category.trim());
      }
    }
    return categorySet.toList();
  }

  ExpensesLoaded copyWith({
    List<Expense>? expenses,
    String? Function()? categoryFilter,
    DateTime? Function()? fromDate,
    DateTime? Function()? toDate,
    String? searchQuery,
  }) {
    return ExpensesLoaded(
      expenses: expenses ?? this.expenses,
      categoryFilter: categoryFilter != null ? categoryFilter() : this.categoryFilter,
      fromDate: fromDate != null ? fromDate() : this.fromDate,
      toDate: toDate != null ? toDate() : this.toDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        expenses,
        categoryFilter,
        fromDate,
        toDate,
        searchQuery,
      ];
}

final class ExpensesError extends ExpensesState {
  final String message;

  const ExpensesError({required this.message});

  @override
  List<Object?> get props => [message];
}
