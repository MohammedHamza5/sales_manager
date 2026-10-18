import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class UpdateSupplierUseCase {
  final SupplierRepository _repository;

  const UpdateSupplierUseCase(this._repository);

  Future<Result<Supplier>> call(Supplier supplier) async {
    final cleanName = supplier.name.trim();
    if (cleanName.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          field: 'name',
          message: 'اسم المورد مطلوب ولا يمكن تركه فارغاً',
        ),
      );
    }

    final cleanPhone = supplier.phone?.trim();
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

    return _repository.updateSupplier(
      supplier.copyWith(
        name: cleanName,
        phone: cleanPhone != null && cleanPhone.isNotEmpty ? cleanPhone : null,
        address: supplier.address?.trim().isNotEmpty == true
            ? supplier.address!.trim()
            : null,
        notes: supplier.notes?.trim().isNotEmpty == true
            ? supplier.notes!.trim()
            : null,
      ),
    );
  }
}
