import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

class DailyStats extends Equatable {
  final Money todaySales;
  final Money todayCollections;
  final Money todayPurchases;
  final Money todayExpenses;
  final Money todayReturns;
  final int todaySalesCount;
  final int todayCollectionsCount;
  final int todayReturnsCount;

  const DailyStats({
    required this.todaySales,
    required this.todayCollections,
    required this.todayPurchases,
    required this.todayExpenses,
    this.todayReturns = Money.zero,
    required this.todaySalesCount,
    required this.todayCollectionsCount,
    this.todayReturnsCount = 0,
  });

  static const empty = DailyStats(
    todaySales: Money.zero,
    todayCollections: Money.zero,
    todayPurchases: Money.zero,
    todayExpenses: Money.zero,
    todayReturns: Money.zero,
    todaySalesCount: 0,
    todayCollectionsCount: 0,
    todayReturnsCount: 0,
  );

  @override
  List<Object?> get props => [
        todaySales,
        todayCollections,
        todayPurchases,
        todayExpenses,
        todayReturns,
        todaySalesCount,
        todayCollectionsCount,
        todayReturnsCount,
      ];
}
