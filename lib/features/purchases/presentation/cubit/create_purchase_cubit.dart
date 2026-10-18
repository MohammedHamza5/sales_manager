import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/result.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/usecases/create_purchase_usecase.dart';
import 'create_purchase_state.dart';

class CreatePurchaseCubit extends Cubit<CreatePurchaseState> {
  final CreatePurchaseUseCase _createPurchaseUseCase;

  CreatePurchaseCubit({
    required CreatePurchaseUseCase createPurchaseUseCase,
  })  : _createPurchaseUseCase = createPurchaseUseCase,
        super(const CreatePurchaseInitial());

  void init({int? preselectedSupplierId, String? preselectedSupplierName}) {
    emit(
      CreatePurchaseEditing(
        supplierId: preselectedSupplierId,
        supplierName: preselectedSupplierName,
        purchaseDate: DateTime.now(),
        items: const [],
        paidAmount: Money.zero,
      ),
    );
  }

  void selectSupplier(int id, String name) {
    final currentState = state;
    if (currentState is CreatePurchaseEditing) {
      emit(
        currentState.copyWith(
          supplierId: id,
          supplierName: name,
          clearError: true,
        ),
      );
    }
  }

  void setPurchaseDate(DateTime date) {
    final currentState = state;
    if (currentState is CreatePurchaseEditing) {
      emit(currentState.copyWith(purchaseDate: date));
    }
  }

  void addItem(Product product, {Decimal? quantity, Money? unitCost}) {
    final currentState = state;
    if (currentState is CreatePurchaseEditing) {
      final existingIndex =
          currentState.items.indexWhere((it) => it.productId == product.id);

      final initialQty = quantity ?? Decimal.one;
      final initialCost = unitCost ?? product.currentPurchasePrice;

      if (existingIndex >= 0) {
        // Increment quantity of existing item
        final existingItem = currentState.items[existingIndex];
        final updatedItems = List<InvoiceItemDraft>.from(currentState.items);
        updatedItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + initialQty,
          unitCost: initialCost,
        );
        emit(
          currentState.copyWith(
            items: updatedItems,
            clearError: true,
          ),
        );
      } else {
        // Add new item
        final newItem = InvoiceItemDraft(
          productId: product.id,
          productName: product.name,
          productCode: product.code,
          productUnit: product.unit,
          quantity: initialQty,
          unitCost: initialCost,
          currentStock: product.currentQuantity,
        );
        emit(
          currentState.copyWith(
            items: [...currentState.items, newItem],
            clearError: true,
          ),
        );
      }
    }
  }

  void updateItemQuantity(int index, Decimal quantity) {
    final currentState = state;
    if (currentState is CreatePurchaseEditing &&
        index >= 0 &&
        index < currentState.items.length) {
      final updatedItems = List<InvoiceItemDraft>.from(currentState.items);
      updatedItems[index] = updatedItems[index].copyWith(quantity: quantity);
      emit(currentState.copyWith(items: updatedItems));
    }
  }

  void updateItemUnitCost(int index, Money unitCost) {
    final currentState = state;
    if (currentState is CreatePurchaseEditing &&
        index >= 0 &&
        index < currentState.items.length) {
      final updatedItems = List<InvoiceItemDraft>.from(currentState.items);
      updatedItems[index] = updatedItems[index].copyWith(unitCost: unitCost);
      emit(currentState.copyWith(items: updatedItems));
    }
  }

  void removeItem(int index) {
    final currentState = state;
    if (currentState is CreatePurchaseEditing &&
        index >= 0 &&
        index < currentState.items.length) {
      final updatedItems = List<InvoiceItemDraft>.from(currentState.items)
        ..removeAt(index);
      emit(currentState.copyWith(items: updatedItems));
    }
  }

  void setPaidAmount(Money paidAmount) {
    final currentState = state;
    if (currentState is CreatePurchaseEditing) {
      emit(currentState.copyWith(paidAmount: paidAmount));
    }
  }

  void setNote(String note) {
    final currentState = state;
    if (currentState is CreatePurchaseEditing) {
      emit(currentState.copyWith(note: note));
    }
  }

  Future<void> submitPurchase({String createdBy = 'admin'}) async {
    final currentState = state;
    if (currentState is! CreatePurchaseEditing || !currentState.canSubmit) {
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, clearError: true));

    final params = CreatePurchaseParams(
      supplierId: currentState.supplierId!,
      purchaseDate: currentState.purchaseDate,
      items: currentState.items
          .map(
            (it) => PurchaseItemParam(
              productId: it.productId,
              quantity: it.quantity,
              unitCost: it.unitCost,
            ),
          )
          .toList(),
      paidAmountAtCreation: currentState.paidAmount,
      note: currentState.note,
      createdBy: createdBy,
    );

    final result = await _createPurchaseUseCase(params);

    switch (result) {
      case Success(:final data):
        emit(CreatePurchaseSuccess(data));
      case FailureResult(:final failure):
        emit(
          currentState.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
