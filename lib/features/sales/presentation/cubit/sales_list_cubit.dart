import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/watch_sales_usecase.dart';
import 'sales_list_state.dart';

class SalesListCubit extends Cubit<SalesListState> {
  final WatchSalesUseCase _watchSalesUseCase;
  StreamSubscription<List<Sale>>? _salesSubscription;

  SalesListCubit(this._watchSalesUseCase) : super(const SalesListInitial());

  void init() {
    emit(const SalesListLoading());
    _salesSubscription?.cancel();
    _salesSubscription = _watchSalesUseCase().listen(
      (sales) {
        if (sales.isEmpty) {
          emit(const SalesListEmpty());
        } else {
          final currentLoaded = state is SalesListLoaded
              ? state as SalesListLoaded
              : null;
          emit(SalesListLoaded(
            sales: sales,
            searchQuery: currentLoaded?.searchQuery ?? '',
            statusFilter: currentLoaded?.statusFilter,
            customerIdFilter: currentLoaded?.customerIdFilter,
          ));
        }
      },
      onError: (Object error) {
        emit(SalesListError(message: 'حدث خطأ أثناء تحميل قائمة المبيعات: $error'));
      },
    );
  }

  void search(String query) {
    if (state is SalesListLoaded) {
      final current = state as SalesListLoaded;
      emit(current.copyWith(searchQuery: query));
    }
  }

  void filterByStatus(SaleStatus? status) {
    if (state is SalesListLoaded) {
      final current = state as SalesListLoaded;
      emit(current.copyWith(statusFilter: () => status));
    }
  }

  void filterByCustomer(int? customerId) {
    if (state is SalesListLoaded) {
      final current = state as SalesListLoaded;
      emit(current.copyWith(customerIdFilter: () => customerId));
    }
  }

  @override
  Future<void> close() {
    _salesSubscription?.cancel();
    return super.close();
  }
}
