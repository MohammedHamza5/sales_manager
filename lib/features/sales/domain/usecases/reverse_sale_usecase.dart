import '../../../../core/result/result.dart';
import '../entities/sale.dart';
import '../repositories/sale_repository.dart';

class ReverseSaleUseCase {
  final SaleRepository _repository;

  const ReverseSaleUseCase(this._repository);

  Future<Result<Sale>> call(int saleId, {String? reason}) {
    return _repository.reverseSale(saleId, reason: reason);
  }
}
