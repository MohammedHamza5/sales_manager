import 'package:equatable/equatable.dart';
import '../../domain/entities/inventory_movement.dart';

sealed class StockAdjustmentState extends Equatable {
  const StockAdjustmentState();

  @override
  List<Object?> get props => [];
}

class StockAdjustmentInitial extends StockAdjustmentState {
  const StockAdjustmentInitial();
}

class StockAdjustmentSubmitting extends StockAdjustmentState {
  const StockAdjustmentSubmitting();
}

class StockAdjustmentSuccess extends StockAdjustmentState {
  final InventoryMovement movement;

  const StockAdjustmentSuccess(this.movement);

  @override
  List<Object?> get props => [movement];
}

class StockAdjustmentError extends StockAdjustmentState {
  final String message;

  const StockAdjustmentError(this.message);

  @override
  List<Object?> get props => [message];
}
