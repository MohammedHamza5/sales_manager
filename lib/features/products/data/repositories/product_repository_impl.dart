import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/money/money.dart';
import '../../../../core/result/failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/sync/sync_dispatcher.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../daos/products_dao.dart';
import '../models/product_mapper.dart';

class ProductRepositoryImpl implements ProductRepository {
  final AppDatabase _db;
  final ProductsDao _dao;
  final SyncDispatcher? _syncDispatcher;

  ProductRepositoryImpl({
    required AppDatabase db,
    required ProductsDao dao,
    SyncDispatcher? syncDispatcher,
  })  : _db = db,
        _dao = dao,
        _syncDispatcher = syncDispatcher;

  @override
  Future<Result<List<Product>>> getProducts({
    String? query,
    bool? isActiveOnly,
    bool? isLowStockOnly,
  }) async {
    try {
      final entries = await _dao.getProductsList(
        query: query,
        isActiveOnly: isActiveOnly,
      );

      var products = entries.map(ProductMapper.toDomain).toList();

      if (isLowStockOnly == true) {
        products = products.where((p) => p.isLowStock).toList();
      }

      return Success(products);
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في جلب قائمة المنتجات',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Stream<List<Product>> watchProducts({
    String? query,
    bool? isActiveOnly,
  }) {
    return _dao
        .watchProductsList(query: query, isActiveOnly: isActiveOnly)
        .map((entries) => entries.map(ProductMapper.toDomain).toList());
  }

  @override
  Future<Result<Product>> getProductById(int id) async {
    try {
      final entry = await _dao.getProductById(id);
      if (entry == null) {
        return FailureResult(
          NotFoundFailure(message: 'المنتج برقم $id غير موجود'),
        );
      }
      return Success(ProductMapper.toDomain(entry));
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في البحث عن المنتج',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<Product?>> getProductByCode(String code) async {
    try {
      final entry = await _dao.getProductByCode(code);
      if (entry == null) return const Success(null);
      return Success(ProductMapper.toDomain(entry));
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في التحقق من كود المنتج',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<Product>> addProduct({
    required String name,
    String? code,
    required String unit,
    required Money salePrice,
    required Money purchasePrice,
    Decimal? initialQuantity,
    Decimal? lowStockThreshold,
    String createdBy = 'admin',
  }) async {
    final qty = initialQuantity ?? Decimal.zero;

    try {
      return await _db.transaction(() async {
        // 1. Insert Product
        final companion = ProductMapper.toInsertCompanion(
          name: name,
          code: code,
          unit: unit,
          salePrice: salePrice,
          purchasePrice: purchasePrice,
          initialQuantity: qty,
          lowStockThreshold: lowStockThreshold,
          createdBy: createdBy,
        );

        final productId = await _dao.insertProduct(companion);

        // 2. If initialQuantity > 0, atomically insert opening balance inventory movement
        if (qty > Decimal.zero) {
          await _db.into(_db.inventoryMovements).insert(
                InventoryMovementsCompanion.insert(
                  productId: productId,
                  movementType: 'opening_balance',
                  quantityDelta: qty,
                  balanceAfter: qty,
                  referenceType: const Value('product_creation'),
                  referenceId: Value(productId),
                  note: const Value('رصيد افتتاحي عند إنشاء المنتج'),
                  createdBy: Value(createdBy),
                ),
              );
        }

        // 3. Atomically write Audit Log inside the exact same transaction
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'product',
                entityId: productId,
                action: 'create',
                payloadAfter: Value(
                  jsonEncode({
                    'name': name,
                    'code': code,
                    'unit': unit,
                    'sale_price': salePrice.piastres,
                    'purchase_price': purchasePrice.piastres,
                    'initial_quantity': qty.toString(),
                  }),
                ),
                userId: Value(createdBy),
              ),
            );

        // 4. Dispatch to Sync Queue
        await _syncDispatcher?.dispatchInsert(
          entityType: 'product',
          localId: productId,
          data: {
            'name': name,
            'code': code,
            'unit': unit,
            'current_sale_price': salePrice.piastres,
            'current_purchase_price': purchasePrice.piastres,
            'current_quantity': qty.toDouble(),
            'low_stock_threshold': lowStockThreshold?.toDouble(),
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'created_by': createdBy,
          },
        );

        final createdEntry = await _dao.getProductById(productId);
        return Success(ProductMapper.toDomain(createdEntry!));
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في حفظ المنتج الجديد',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<Product>> updateProduct(Product product) async {
    try {
      return await _db.transaction(() async {
        final existingEntry = await _dao.getProductById(product.id);
        if (existingEntry == null) {
          return const FailureResult(
            NotFoundFailure(message: 'المنتج المراد تعديله غير موجود'),
          );
        }

        final companion = ProductsCompanion(
          id: Value(product.id),
          name: Value(product.name),
          code: Value(product.code),
          unit: Value(product.unit),
          currentSalePrice: Value(product.currentSalePrice.piastres),
          currentPurchasePrice: Value(product.currentPurchasePrice.piastres),
          currentQuantity: Value(product.currentQuantity),
          lowStockThreshold: Value(product.lowStockThreshold),
          isActive: Value(product.isActive),
          createdBy: Value(product.createdBy),
        );

        await _dao.updateProductEntry(companion);

        // Audit Log inside transaction
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'product',
                entityId: product.id,
                action: 'update',
                payloadBefore: Value(
                  jsonEncode({
                    'name': existingEntry.name,
                    'code': existingEntry.code,
                    'sale_price': existingEntry.currentSalePrice,
                    'purchase_price': existingEntry.currentPurchasePrice,
                  }),
                ),
                payloadAfter: Value(
                  jsonEncode({
                    'name': product.name,
                    'code': product.code,
                    'sale_price': product.currentSalePrice.piastres,
                    'purchase_price': product.currentPurchasePrice.piastres,
                  }),
                ),
                userId: Value(product.createdBy),
              ),
            );

        // Dispatch to Sync Queue
        await _syncDispatcher?.dispatchUpdate(
          entityType: 'product',
          localId: product.id,
          data: {
            'name': product.name,
            'code': product.code,
            'unit': product.unit,
            'current_sale_price': product.currentSalePrice.piastres,
            'current_purchase_price': product.currentPurchasePrice.piastres,
            'current_quantity': product.currentQuantity.toDouble(),
            'low_stock_threshold': product.lowStockThreshold?.toDouble(),
            'is_active': product.isActive,
            'created_by': product.createdBy,
          },
        );

        final updatedEntry = await _dao.getProductById(product.id);
        return Success(ProductMapper.toDomain(updatedEntry!));
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في تحديث بيانات المنتج',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }

  @override
  Future<Result<void>> toggleProductStatus(int id, bool isActive) async {
    try {
      return await _db.transaction(() async {
        final rowsAffected = await _dao.toggleProductStatus(id, isActive);
        if (rowsAffected == 0) {
          return const FailureResult(
            NotFoundFailure(message: 'المنتج غير موجود'),
          );
        }

        // Audit log
        await _db.into(_db.auditLog).insert(
              AuditLogCompanion.insert(
                entityType: 'product',
                entityId: id,
                action: isActive ? 'activate' : 'deactivate',
                note: Value(isActive ? 'تفعيل المنتج' : 'إيقاف المنتج مؤقتًا'),
              ),
            );

        // Dispatch status update to Sync Queue
        await _syncDispatcher?.dispatchUpdate(
          entityType: 'product',
          localId: id,
          data: {
            'is_active': isActive,
          },
        );

        return const Success(null);
      });
    } catch (e, stack) {
      return FailureResult(
        DatabaseFailure(
          message: 'فشل في تعديل حالة المنتج',
          technicalDetails: '$e\n$stack',
        ),
      );
    }
  }
}
