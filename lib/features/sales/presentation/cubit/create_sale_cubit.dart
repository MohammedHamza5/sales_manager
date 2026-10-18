import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/money/money.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/usecases/create_sale_usecase.dart';
import 'create_sale_state.dart';

class CreateSaleCubit extends Cubit<CreateSaleState> {
  final CreateSaleUseCase _createSaleUseCase;

  CreateSaleCubit(this._createSaleUseCase)
      : super(CreateSaleEditing(saleDate: DateTime.now()));

  void reset() {
    emit(CreateSaleEditing(saleDate: DateTime.now()));
  }

  void setCustomer(int customerId, String customerName) {
    if (state is! CreateSaleEditing) return;
    final current = state as CreateSaleEditing;
    emit(current.copyWith(
      customerId: customerId,
      customerName: customerName,
      errorMessage: () => null,
    ));
  }

  void setSaleDate(DateTime date) {
    if (state is! CreateSaleEditing) return;
    final current = state as CreateSaleEditing;
    emit(current.copyWith(saleDate: date));
  }

  void addProduct(
    Product product, {
    Decimal? quantity,
    Money? unitPrice,
  }) {
    if (state is! CreateSaleEditing) return;
    final current = state as CreateSaleEditing;

    final existingIndex =
        current.items.indexWhere((item) => item.productId == product.id);

    final initialQty = quantity ?? Decimal.one;
    final price = unitPrice ?? product.currentSalePrice;

    if (existingIndex >= 0) {
      final existing = current.items[existingIndex];
      final newQty = existing.quantity + initialQty;
      final updatedList = List<SaleItemDraft>.from(current.items);
      updatedList[existingIndex] = existing.copyWith(
        quantity: newQty,
        unitPrice: price,
        availableStock: product.currentQuantity,
      );
      emit(current.copyWith(items: updatedList, errorMessage: () => null));
    } else {
      final newItem = SaleItemDraft(
        productId: product.id,
        productName: product.name,
        productCode: product.code,
        productUnit: product.unit,
        quantity: initialQty,
        unitPrice: price,
        availableStock: product.currentQuantity,
      );
      final updatedList = List<SaleItemDraft>.from(current.items)..add(newItem);
      emit(current.copyWith(items: updatedList, errorMessage: () => null));
    }
  }

  void updateItemQuantity(int index, Decimal quantity) {
    if (state is! CreateSaleEditing) return;
    final current = state as CreateSaleEditing;
    if (index < 0 || index >= current.items.length) return;

    final updatedList = List<SaleItemDraft>.from(current.items);
    updatedList[index] = updatedList[index].copyWith(quantity: quantity);
    emit(current.copyWith(items: updatedList, errorMessage: () => null));
  }

  void updateItemPrice(int index, Money price) {
    if (state is! CreateSaleEditing) return;
    final current = state as CreateSaleEditing;
    if (index < 0 || index >= current.items.length) return;

    final updatedList = List<SaleItemDraft>.from(current.items);
    updatedList[index] = updatedList[index].copyWith(unitPrice: price);
    emit(current.copyWith(items: updatedList, errorMessage: () => null));
  }

  void removeItem(int index) {
    if (state is! CreateSaleEditing) return;
    final current = state as CreateSaleEditing;
    if (index < 0 || index >= current.items.length) return;

    final updatedList = List<SaleItemDraft>.from(current.items)..removeAt(index);
    emit(current.copyWith(items: updatedList, errorMessage: () => null));
  }

  void setPaidAmount(Money paid) {
    if (state is! CreateSaleEditing) return;
    final current = state as CreateSaleEditing;
    emit(current.copyWith(paidAmount: paid, errorMessage: () => null));
  }

  void setPaidFully() {
    if (state is! CreateSaleEditing) return;
    final current = state as CreateSaleEditing;
    emit(current.copyWith(
      paidAmount: current.totalAmount,
      errorMessage: () => null,
    ));
  }

  void setPaidZero() {
    if (state is! CreateSaleEditing) return;
    final current = state as CreateSaleEditing;
    emit(current.copyWith(paidAmount: Money.zero, errorMessage: () => null));
  }

  void setNote(String note) {
    if (state is! CreateSaleEditing) return;
    final current = state as CreateSaleEditing;
    emit(current.copyWith(note: note));
  }

  Future<void> submitSale() async {
    if (state is! CreateSaleEditing) return;
    final current = state as CreateSaleEditing;

    if (!current.canSubmit) {
      if (current.hasOverselling) {
        emit(current.copyWith(
          errorMessage: () =>
              'توجد أصناف تتجاوز الكمية المتاحة بالمخزن، يرجى تصحيح الكميات.',
        ));
      } else if (current.customerId == null) {
        emit(current.copyWith(
          errorMessage: () => 'يرجى اختيار العميل أولاً.',
        ));
      } else if (current.items.isEmpty) {
        emit(current.copyWith(
          errorMessage: () => 'يرجى إضافة صنف واحد على الأقل.',
        ));
      }
      return;
    }

    emit(current.copyWith(isSubmitting: true, errorMessage: () => null));

    final params = CreateSaleParams(
      customerId: current.customerId!,
      saleDate: current.saleDate,
      items: current.items.map((i) {
        return SaleItemParam(
          productId: i.productId,
          quantity: i.quantity,
          unitPrice: i.unitPrice,
        );
      }).toList(),
      paidAmountAtCreation: current.paidAmount,
      note: current.note,
    );

    final result = await _createSaleUseCase(params);

    result.fold(
      onSuccess: (sale) {
        emit(CreateSaleSuccess(sale));
      },
      onFailure: (failure) {
        emit(current.copyWith(
          isSubmitting: false,
          errorMessage: () => failure.message,
        ));
      },
    );
  }
}
