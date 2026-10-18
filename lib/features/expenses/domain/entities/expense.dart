import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

/// Pure Dart entity representing an Expense (مصروف).
class Expense extends Equatable {
  final int id;
  final String category; // إيجار، كهرباء، مرتبات، بوفيه، نقل، صيانة، متنوعات
  final Money amount; // بالقرش
  final DateTime expenseDate;
  final String? note;
  final DateTime createdAt;
  final String createdBy;

  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.note,
    required this.createdAt,
    this.createdBy = 'admin',
  });

  @override
  List<Object?> get props => [
        id,
        category,
        amount,
        expenseDate,
        note,
        createdAt,
        createdBy,
      ];
}
