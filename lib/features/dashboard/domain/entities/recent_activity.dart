import 'package:equatable/equatable.dart';
import '../../../../core/money/money.dart';

class RecentActivity extends Equatable {
  final String id;
  final String type; // 'sale', 'purchase', 'customer_payment', 'supplier_payment', 'expense', 'customer_return', 'supplier_return'
  final String description;
  final Money amount;
  final DateTime time;
  final String direction; // 'in' or 'out'
  final int? referenceId;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.time,
    required this.direction,
    this.referenceId,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        description,
        amount,
        time,
        direction,
        referenceId,
      ];
}
