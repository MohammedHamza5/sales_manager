import 'package:decimal/decimal.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/customer_return.dart';
import '../repositories/return_repository.dart';

class CreateCustomerReturnUseCase {
  final ReturnRepository _repository;

  const CreateCustomerReturnUseCase(this._repository);

  Future<Result<CustomerReturn>> call(CreateCustomerReturnParams params) async {
    if (params.items.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          field: 'items',
          message: 'يجب إضافة صنف واحد على الأقل في إذن المرتجع',
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
            message: 'سعر الصنف رقم ${i + 1} لا يمكن أن يكون سالباً',
          ),
        );
      }
    }

    return _repository.createCustomerReturn(params);
  }
}
