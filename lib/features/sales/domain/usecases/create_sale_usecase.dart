import 'package:decimal/decimal.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/sale.dart';
import '../repositories/sale_repository.dart';

class CreateSaleUseCase {
  final SaleRepository _repository;

  const CreateSaleUseCase(this._repository);

  Future<Result<Sale>> call(CreateSaleParams params) async {
    if (params.items.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          field: 'items',
          message: 'يجب إضافة صنف واحد على الأقل في فاتورة البيع',
        ),
      );
    }

    for (int i = 0; i < params.items.length; i++) {
      final item = params.items[i];
      if (item.quantity <= Decimal.zero) {
        return FailureResult(
          ValidationFailure(
            field: 'quantity_$i',
            message: 'كمية الصنف رقم ${i + 1} يجب أن تكون أكبر من الصفر',
          ),
        );
      }
      if (item.unitPrice.piastres < 0) {
        return FailureResult(
          ValidationFailure(
            field: 'unitPrice_$i',
            message: 'سعر بيع الصنف رقم ${i + 1} لا يمكن أن يكون سالباً',
          ),
        );
      }
    }

    if (params.paidAmountAtCreation.piastres < 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'paidAmountAtCreation',
          message: 'المبلغ المدفوع لا يمكن أن يكون سالباً',
        ),
      );
    }

    if (params.paidAmountAtCreation > params.totalAmount) {
      return const FailureResult(
        ValidationFailure(
          field: 'paidAmountAtCreation',
          message: 'المبلغ المدفوع لا يمكن أن يتجاوز إجمالي الفاتورة',
        ),
      );
    }

    return _repository.createSale(params);
  }
}
