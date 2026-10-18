import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_movement.dart';
import '../../domain/usecases/watch_inventory_movements_usecase.dart';
import 'product_movements_state.dart';

class ProductMovementsCubit extends Cubit<ProductMovementsState> {
  final WatchInventoryMovementsUseCase _watchMovementsUseCase;
  final int? productId;

  StreamSubscription<List<InventoryMovement>>? _movementsSubscription;
  MovementType? _currentFilterType;

  ProductMovementsCubit({
    required WatchInventoryMovementsUseCase watchMovementsUseCase,
    this.productId,
  })  : _watchMovementsUseCase = watchMovementsUseCase,
        super(const ProductMovementsInitial());

  void init() {
    _subscribe();
  }

  void setFilterType(MovementType? type) {
    _currentFilterType = type;
    _subscribe();
  }

  void _subscribe() {
    emit(const ProductMovementsLoading());
    _movementsSubscription?.cancel();

    _movementsSubscription = _watchMovementsUseCase(
      productId: productId,
      type: _currentFilterType,
    ).listen(
      (movements) {
        if (movements.isEmpty) {
          emit(
            ProductMovementsEmpty(
              message: _currentFilterType != null
                  ? 'لا توجد حركات مخزنية مسجلة لهذا النوع'
                  : 'لا توجد حركات مخزنية مسجلة حتى الآن',
              hasFilter: _currentFilterType != null,
            ),
          );
        } else {
          emit(
            ProductMovementsLoaded(
              movements: movements,
              filterType: _currentFilterType,
            ),
          );
        }
      },
      onError: (Object error) {
        emit(ProductMovementsError(message: 'فشل في تحميل حركات المخزون: $error'));
      },
    );
  }

  @override
  Future<void> close() {
    _movementsSubscription?.cancel();
    return super.close();
  }
}
