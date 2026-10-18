import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class AddSupplierUseCase {
  final SupplierRepository _repository;

  const AddSupplierUseCase(this._repository);

  Future<Result<Supplier>> call({
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
          message: 'اسم المورد مطلوب ولا يمكن تركه فارغاً',
        ),
      );
    }

    final cleanPhone = phone?.trim();
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

    return _repository.addSupplier(
      name: cleanName,
      phone: cleanPhone != null && cleanPhone.isNotEmpty ? cleanPhone : null,
      address: address?.trim().isNotEmpty == true ? address!.trim() : null,
      notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      initialBalance: initialBalance,
      createdBy: createdBy,
    );
  }
}
