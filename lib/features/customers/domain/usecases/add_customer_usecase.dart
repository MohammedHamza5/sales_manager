import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class AddCustomerUseCase {
  final CustomerRepository _repository;

  const AddCustomerUseCase(this._repository);

  Future<Result<Customer>> call({
    required String name,
    String? phone,
    String? address,
    String? notes,
    Money initialBalance = Money.zero,
    String createdBy = 'admin',
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          field: 'name',
          message: 'اسم العميل مطلوب ولا يمكن تركه فارغاً',
        ),
      );
    }

    final cleanPhone = phone?.trim();
    if (cleanPhone != null && cleanPhone.isNotEmpty) {
      // Basic phone format check: must contain only digits, plus, dashes, spaces
      if (!RegExp(r'^[0-9+\-\s]{6,20}$').hasMatch(cleanPhone)) {
        return const FailureResult(
          ValidationFailure(
            field: 'phone',
            message: 'رقم الهاتف غير صالح، يجب أن يتكون من أرقام صحيحة',
          ),
        );
      }
    }

    return _repository.addCustomer(
      name: cleanName,
      phone: cleanPhone != null && cleanPhone.isNotEmpty ? cleanPhone : null,
      address: address?.trim().isNotEmpty == true ? address!.trim() : null,
      notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      initialBalance: initialBalance,
      createdBy: createdBy,
    );
  }
}
