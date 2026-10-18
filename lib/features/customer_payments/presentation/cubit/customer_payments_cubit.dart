import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/customer_payment.dart';
import '../../domain/usecases/record_customer_payment_usecase.dart';
import '../../domain/usecases/watch_customer_payments_usecase.dart';
import 'customer_payments_state.dart';

class CustomerPaymentsCubit extends Cubit<CustomerPaymentsState> {
  final RecordCustomerPaymentUseCase _recordPaymentUseCase;
  final WatchCustomerPaymentsUseCase _watchPaymentsUseCase;

  StreamSubscription<List<CustomerPayment>>? _subscription;

  CustomerPaymentsCubit({
    required RecordCustomerPaymentUseCase recordPaymentUseCase,
    required WatchCustomerPaymentsUseCase watchPaymentsUseCase,
  })  : _recordPaymentUseCase = recordPaymentUseCase,
        _watchPaymentsUseCase = watchPaymentsUseCase,
        super(const CustomerPaymentsInitial());

  void init({int? customerId}) {
    emit(const CustomerPaymentsLoading());
    _subscription?.cancel();
    _subscription = _watchPaymentsUseCase(customerId: customerId).listen(
      (payments) {
        if (payments.isEmpty) {
          emit(CustomerPaymentsEmpty(filteredCustomerId: customerId));
        } else {
          final total = payments.fold<int>(
            0,
            (sum, item) => sum + item.amount.piastres,
          );
          emit(
            CustomerPaymentsLoaded(
              allPayments: payments,
              filteredPayments: payments,
              selectedCustomerId: customerId,
              totalCollected: Money(total),
            ),
          );
        }
      },
      onError: (Object error) {
        emit(CustomerPaymentsError(error.toString()));
      },
    );
  }

  void search(String query) {
    final currentState = state;
    if (currentState is! CustomerPaymentsLoaded) return;

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      emit(currentState.copyWith(
        filteredPayments: currentState.allPayments,
        searchQuery: '',
      ));
      return;
    }

    final filtered = currentState.allPayments.where((payment) {
      final nameMatches = payment.customerName.toLowerCase().contains(trimmed);
      final noteMatches = payment.note?.toLowerCase().contains(trimmed) ?? false;
      final invoiceMatches =
          payment.linkedSaleInvoiceNo?.toString().contains(trimmed) ?? false;
      return nameMatches || noteMatches || invoiceMatches;
    }).toList();

    emit(currentState.copyWith(
      filteredPayments: filtered,
      searchQuery: query,
    ));
  }

  Future<Result<CustomerPayment>> recordPayment({
    required int customerId,
    required Money amount,
    required DateTime paymentDate,
    int? linkedSaleId,
    String? note,
  }) async {
    return _recordPaymentUseCase(
      customerId: customerId,
      amount: amount,
      paymentDate: paymentDate,
      linkedSaleId: linkedSaleId,
      note: note,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
