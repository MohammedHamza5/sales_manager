import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_sale_by_id_usecase.dart';
import '../../domain/usecases/reverse_sale_usecase.dart';
import 'sale_detail_state.dart';

class SaleDetailCubit extends Cubit<SaleDetailState> {
  final GetSaleByIdUseCase _getSaleByIdUseCase;
  final ReverseSaleUseCase _reverseSaleUseCase;

  SaleDetailCubit({
    required GetSaleByIdUseCase getSaleByIdUseCase,
    required ReverseSaleUseCase reverseSaleUseCase,
  })  : _getSaleByIdUseCase = getSaleByIdUseCase,
        _reverseSaleUseCase = reverseSaleUseCase,
        super(const SaleDetailInitial());

  Future<void> loadSale(int id) async {
    emit(const SaleDetailLoading());
    final result = await _getSaleByIdUseCase(id);
    result.fold(
      onSuccess: (sale) => emit(SaleDetailLoaded(sale: sale)),
      onFailure: (failure) => emit(SaleDetailError(message: failure.message)),
    );
  }

  Future<void> reverseSale(int saleId, {String? reason}) async {
    if (state is! SaleDetailLoaded) return;
    final current = state as SaleDetailLoaded;

    emit(current.copyWith(isReversing: true, errorMessage: () => null));

    final result = await _reverseSaleUseCase(saleId, reason: reason);
    result.fold(
      onSuccess: (updatedSale) {
        emit(SaleDetailLoaded(
          sale: updatedSale,
          isReversing: false,
          reverseSuccess: true,
        ));
      },
      onFailure: (failure) {
        emit(current.copyWith(
          isReversing: false,
          errorMessage: () => failure.message,
        ));
      },
    );
  }
}
