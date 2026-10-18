import '../../../../core/result/result.dart';
import '../entities/sale.dart';
import '../repositories/sale_repository.dart';

class GetSaleByIdUseCase {
  final SaleRepository _repository;

  const GetSaleByIdUseCase(this._repository);

  Future<Result<Sale>> call(int id) {
    return _repository.getSaleById(id);
  }
}
