import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/inventory_movement.dart';

sealed class ProductMovementsState extends Equatable {
  const ProductMovementsState();

  @override
  List<Object?> get props => [];
}

final class ProductMovementsInitial extends ProductMovementsState {
  const ProductMovementsInitial();
}

final class ProductMovementsLoading extends ProductMovementsState {
  const ProductMovementsLoading();
}

final class ProductMovementsEmpty extends ProductMovementsState {
  final String message;
  final bool hasFilter;

  const ProductMovementsEmpty({
    required this.message,
    this.hasFilter = false,
  });

  @override
  List<Object?> get props => [message, hasFilter];
}

final class ProductMovementsError extends ProductMovementsState {
  final String message;

  const ProductMovementsError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class ProductMovementsLoaded extends ProductMovementsState {
  final List<InventoryMovement> movements;
  final MovementType? filterType;

  const ProductMovementsLoaded({
    required this.movements,
    this.filterType,
  });

  Decimal get totalInflow {
    var sum = Decimal.zero;
    for (final m in movements) {
      if (m.isInflow) sum += m.quantityDelta;
    }
    return sum;
  }

  Decimal get totalOutflow {
    var sum = Decimal.zero;
    for (final m in movements) {
      if (m.isOutflow) sum += m.quantityDelta.abs();
    }
    return sum;
  }

  int get count => movements.length;

  @override
  List<Object?> get props => [movements, filterType];
}
