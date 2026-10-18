import '../../../../core/result/result.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class GetCustomersUseCase {
  final CustomerRepository _repository;

  const GetCustomersUseCase(this._repository);

  Future<Result<List<Customer>>> call({
    String? query,
    bool? isActiveOnly,
  }) {
    return _repository.getCustomers(
      query: query,
      isActiveOnly: isActiveOnly,
    );
  }
}
