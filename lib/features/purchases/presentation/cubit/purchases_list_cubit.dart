import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/usecases/reverse_purchase_usecase.dart';
import '../../domain/usecases/watch_purchases_usecase.dart';
import 'purchases_list_state.dart';

class PurchasesListCubit extends Cubit<PurchasesListState> {
  final WatchPurchasesUseCase _watchPurchasesUseCase;
  final ReversePurchaseUseCase _reversePurchaseUseCase;
  StreamSubscription<List<Purchase>>? _subscription;

  PurchasesListCubit({
    required WatchPurchasesUseCase watchPurchasesUseCase,
    required ReversePurchaseUseCase reversePurchaseUseCase,
  })  : _watchPurchasesUseCase = watchPurchasesUseCase,
        _reversePurchaseUseCase = reversePurchaseUseCase,
        super(const PurchasesListInitial());

  void init() {
    emit(const PurchasesListLoading());
    _subscription?.cancel();
    _subscription = _watchPurchasesUseCase().listen(
      (purchases) {
        if (purchases.isEmpty) {
          emit(const PurchasesListEmpty());
        } else {
          final currentState = state;
          if (currentState is PurchasesListLoaded) {
            emit(currentState.copyWith(purchases: purchases));
          } else {
            emit(PurchasesListLoaded(purchases: purchases));
          }
        }
      },
      onError: (Object error) {
        emit(
          PurchasesListError(
            message: 'حدث خطأ أثناء تحميل فواتير المشتريات: $error',
          ),
        );
      },
    );
  }

  void search(String query) {
    final currentState = state;
    if (currentState is PurchasesListLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void filterByStatus(PurchaseStatus? status) {
    final currentState = state;
    if (currentState is PurchasesListLoaded) {
      emit(currentState.copyWith(statusFilter: () => status));
    }
  }

  void filterBySupplier(int? supplierId) {
    final currentState = state;
    if (currentState is PurchasesListLoaded) {
      emit(currentState.copyWith(supplierIdFilter: () => supplierId));
    }
  }

  Future<Result<Purchase>> reversePurchase(int purchaseId) async {
    return _reversePurchaseUseCase(purchaseId: purchaseId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
