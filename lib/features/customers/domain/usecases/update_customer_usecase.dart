import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class UpdateCustomerUseCase {
  final CustomerRepository _repository;

  const UpdateCustomerUseCase(this._repository);

  Future<Result<Customer>> call(Customer customer) async {
    if (customer.id <= 0) {
      return const FailureResult(
        ValidationFailure(
          field: 'id',
          message: 'معرف العميل غير صالح',
        ),
      );
    }

    final cleanName = customer.name.trim();
    if (cleanName.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          field: 'name',
          message: 'اسم العميل مطلوب ولا يمكن تركه فارغاً',
        ),
      );
    }

    final cleanPhone = customer.phone?.trim();
    if (cleanPhone != null && cleanPhone.isNotEmpty) {
      if (!RegExp(r'^[0-9+\-\s]{6,20}$').hasMatch(cleanPhone)) {
        return const FailureResult(
          ValidationFailure(
            field: 'phone',
            message: 'رقم الهاتف غير صالح، يجب أن يتكون من أرقام صحيحة',
          ),
        );
      }
    }

    return _repository.updateCustomer(
      customer.copyWith(
        name: cleanName,
        phone: cleanPhone != null && cleanPhone.isNotEmpty ? cleanPhone : null,
        address: customer.address?.trim().isNotEmpty == true
            ? customer.address!.trim()
            : null,
        notes: customer.notes?.trim().isNotEmpty == true
            ? customer.notes!.trim()
            : null,
      ),
    );
  }
}
