import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/customer_return.dart';
import '../../domain/entities/supplier_return.dart';
import '../../domain/repositories/return_repository.dart';
import '../../domain/usecases/create_customer_return_usecase.dart';
import '../../domain/usecases/create_supplier_return_usecase.dart';
import '../../domain/usecases/watch_customer_returns_usecase.dart';
import '../../domain/usecases/watch_supplier_returns_usecase.dart';
import 'returns_state.dart';

class ReturnsCubit extends Cubit<ReturnsState> {
  final WatchCustomerReturnsUseCase _watchCustomerReturns;
  final WatchSupplierReturnsUseCase _watchSupplierReturns;
  final CreateCustomerReturnUseCase _createCustomerReturn;
  final CreateSupplierReturnUseCase _createSupplierReturn;

  StreamSubscription<List<CustomerReturn>>? _customerReturnsSub;
  StreamSubscription<List<SupplierReturn>>? _supplierReturnsSub;

  List<CustomerReturn> _latestCustomerReturns = [];
  List<SupplierReturn> _latestSupplierReturns = [];

  ReturnsCubit({
    required WatchCustomerReturnsUseCase watchCustomerReturns,
    required WatchSupplierReturnsUseCase watchSupplierReturns,
    required CreateCustomerReturnUseCase createCustomerReturn,
    required CreateSupplierReturnUseCase createSupplierReturn,
  })  : _watchCustomerReturns = watchCustomerReturns,
        _watchSupplierReturns = watchSupplierReturns,
        _createCustomerReturn = createCustomerReturn,
        _createSupplierReturn = createSupplierReturn,
        super(const ReturnsInitial());

  void init() {
    emit(const ReturnsLoading());

    _customerReturnsSub?.cancel();
    _customerReturnsSub = _watchCustomerReturns().listen(
      (customerReturns) {
        _latestCustomerReturns = customerReturns;
        _emitLoaded();
      },
      onError: (Object err) {
        emit(ReturnsError(message: 'فشل في تحميل مرتجعات العملاء: $err'));
      },
    );

    _supplierReturnsSub?.cancel();
    _supplierReturnsSub = _watchSupplierReturns().listen(
      (supplierReturns) {
        _latestSupplierReturns = supplierReturns;
        _emitLoaded();
      },
      onError: (Object err) {
        emit(ReturnsError(message: 'فشل في تحميل مرتجعات الموردين: $err'));
      },
    );
  }

  void _emitLoaded() {
    final current = state is ReturnsLoaded ? (state as ReturnsLoaded) : null;
    emit(ReturnsLoaded(
      customerReturns: _latestCustomerReturns,
      supplierReturns: _latestSupplierReturns,
      selectedTabIndex: current?.selectedTabIndex ?? 0,
      searchQuery: current?.searchQuery ?? '',
    ));
  }

  void setTab(int index) {
    if (state is ReturnsLoaded) {
      final current = state as ReturnsLoaded;
      emit(current.copyWith(selectedTabIndex: index));
    }
  }

  void search(String query) {
    if (state is ReturnsLoaded) {
      final current = state as ReturnsLoaded;
      emit(current.copyWith(searchQuery: query));
    }
  }

  Future<Result<CustomerReturn>> submitCustomerReturn(
    CreateCustomerReturnParams params,
  ) {
    return _createCustomerReturn(params);
  }

  Future<Result<SupplierReturn>> submitSupplierReturn(
    CreateSupplierReturnParams params,
  ) {
    return _createSupplierReturn(params);
  }

  @override
  Future<void> close() {
    _customerReturnsSub?.cancel();
    _supplierReturnsSub?.cancel();
    return super.close();
  }
}
