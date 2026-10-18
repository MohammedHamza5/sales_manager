import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/supplier_payment.dart';
import '../../domain/usecases/record_supplier_payment_usecase.dart';
import '../../domain/usecases/watch_supplier_payments_usecase.dart';
import 'supplier_payments_state.dart';

class SupplierPaymentsCubit extends Cubit<SupplierPaymentsState> {
  final RecordSupplierPaymentUseCase _recordPaymentUseCase;
  final WatchSupplierPaymentsUseCase _watchPaymentsUseCase;

  StreamSubscription<List<SupplierPayment>>? _subscription;

  SupplierPaymentsCubit({
    required RecordSupplierPaymentUseCase recordPaymentUseCase,
    required WatchSupplierPaymentsUseCase watchPaymentsUseCase,
  })  : _recordPaymentUseCase = recordPaymentUseCase,
        _watchPaymentsUseCase = watchPaymentsUseCase,
        super(const SupplierPaymentsInitial());

  void init({int? supplierId}) {
    emit(const SupplierPaymentsLoading());
    _subscription?.cancel();
    _subscription = _watchPaymentsUseCase(supplierId: supplierId).listen(
      (payments) {
        if (payments.isEmpty) {
          emit(SupplierPaymentsEmpty(filteredSupplierId: supplierId));
        } else {
          final total = payments.fold<int>(
            0,
            (sum, item) => sum + item.amount.piastres,
          );
          emit(
            SupplierPaymentsLoaded(
              allPayments: payments,
              filteredPayments: payments,
              selectedSupplierId: supplierId,
              totalPaid: Money(total),
            ),
          );
        }
      },
      onError: (Object error) {
        emit(SupplierPaymentsError(error.toString()));
      },
    );
  }

  void search(String query) {
    final currentState = state;
    if (currentState is! SupplierPaymentsLoaded) return;

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      emit(currentState.copyWith(
        filteredPayments: currentState.allPayments,
        searchQuery: '',
      ));
      return;
    }

    final filtered = currentState.allPayments.where((payment) {
      final nameMatches = payment.supplierName.toLowerCase().contains(trimmed);
      final noteMatches = payment.note?.toLowerCase().contains(trimmed) ?? false;
      final invoiceMatches =
          payment.linkedPurchaseInvoiceNo?.toString().contains(trimmed) ?? false;
      return nameMatches || noteMatches || invoiceMatches;
    }).toList();

    emit(currentState.copyWith(
      filteredPayments: filtered,
      searchQuery: query,
    ));
  }

  Future<Result<SupplierPayment>> recordPayment({
    required int supplierId,
    required Money amount,
    required DateTime paymentDate,
    int? linkedPurchaseId,
    String? note,
  }) async {
    return _recordPaymentUseCase(
      supplierId: supplierId,
      amount: amount,
      paymentDate: paymentDate,
      linkedPurchaseId: linkedPurchaseId,
      note: note,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
