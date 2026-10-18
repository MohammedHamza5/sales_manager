import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/record_stock_adjustment_usecase.dart';
import 'stock_adjustment_state.dart';

class StockAdjustmentCubit extends Cubit<StockAdjustmentState> {
  final RecordStockAdjustmentUseCase _recordStockAdjustmentUseCase;

  StockAdjustmentCubit({
    required RecordStockAdjustmentUseCase recordStockAdjustmentUseCase,
  })  : _recordStockAdjustmentUseCase = recordStockAdjustmentUseCase,
        super(const StockAdjustmentInitial());

  Future<void> submitAdjustment({
    required int productId,
    required Decimal quantityDelta,
    required String reason,
    String createdBy = 'admin',
  }) async {
    emit(const StockAdjustmentSubmitting());

    final result = await _recordStockAdjustmentUseCase(
      productId: productId,
      quantityDelta: quantityDelta,
      reason: reason,
      createdBy: createdBy,
    );

    result.fold(
      onSuccess: (movement) {
        emit(StockAdjustmentSuccess(movement));
      },
      onFailure: (failure) {
        emit(StockAdjustmentError(failure.message));
      },
    );
  }

  void reset() {
    emit(const StockAdjustmentInitial());
  }
}
