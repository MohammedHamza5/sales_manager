import 'package:decimal/decimal.dart';

import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/opening_balance_input.dart';
import '../repositories/opening_balance_repository.dart';

class SaveOpeningBalancesUseCase {
  final OpeningBalanceRepository _repository;

  const SaveOpeningBalancesUseCase(this._repository);

  Future<Result<void>> call(
    OpeningBalanceInput input, {
    String createdBy = 'admin',
  }) async {
    // 1. Verify that opening balance was not saved before
    final checkResult = await _repository.isOpeningBalanceSaved();
    if (checkResult.isFailure) {
      return checkResult;
    }

    if (checkResult.dataOrNull == true) {
      return const FailureResult(
        ValidationFailure(
          field: 'opening_balance',
          message:
              'تم حفظ الأرصدة الافتتاحية للنظام بالفعل سابقاً، ولا يمكن إعادة إدخالها.',
        ),
      );
    }

    // 2. Validate non-negative quantities and amounts
    if (input.cashboxBalance.piastres < 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'cashbox',
          message: 'رصيد الخزينة الافتتاحي لا يمكن أن يكون سالباً.',
        ),
      );
    }

    for (final p in input.products) {
      if (p.initialQuantity < Decimal.zero) {
        return FailureResult(
          ValidationFailure(
            field: 'product_${p.productId}',
            message:
                'الكمية الافتتاحية للمنتج "${p.productName}" لا يمكن أن تكون سالبة.',
          ),
        );
      }
    }

    for (final c in input.customers) {
      if (c.balance.piastres < 0) {
        return FailureResult(
          ValidationFailure(
            field: 'customer_${c.stakeholderId}',
            message:
                'مديونية العميل "${c.name}" الافتتاحية لا يمكن أن تكون سالبة.',
          ),
        );
      }
    }

    for (final s in input.suppliers) {
      if (s.balance.piastres < 0) {
        return FailureResult(
          ValidationFailure(
            field: 'supplier_${s.stakeholderId}',
            message:
                'مستحقات المورد "${s.name}" الافتتاحية لا يمكن أن تكون سالبة.',
          ),
        );
      }
    }

    // 3. Delegate to repository for atomic commit
    return _repository.saveOpeningBalances(input, createdBy: createdBy);
  }
}
