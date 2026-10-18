import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/inventory_tables.dart';
import '../../../../core/database/tables/products_table.dart';

part 'inventory_movements_dao.g.dart';

@DriftAccessor(tables: [InventoryMovements, Products])
class InventoryMovementsDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryMovementsDaoMixin {
  InventoryMovementsDao(super.db);

  JoinedSelectStatement<HasResultSet, dynamic> _buildMovementsQuery({
    int? productId,
    String? movementType,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final query = select(inventoryMovements).join([
      innerJoin(products, products.id.equalsExp(inventoryMovements.productId)),
    ]);

    if (productId != null) {
      query.where(inventoryMovements.productId.equals(productId));
    }

    if (movementType != null) {
      query.where(inventoryMovements.movementType.equals(movementType));
    }

    if (fromDate != null) {
      query.where(inventoryMovements.createdAt.isBiggerOrEqualValue(fromDate));
    }

    if (toDate != null) {
      query.where(inventoryMovements.createdAt.isSmallerOrEqualValue(toDate));
    }

    query.orderBy([
      OrderingTerm(
        expression: inventoryMovements.createdAt,
        mode: OrderingMode.desc,
      ),
      OrderingTerm(
        expression: inventoryMovements.id,
        mode: OrderingMode.desc,
      ),
    ]);

    return query;
  }

  Future<List<TypedResult>> getMovementsList({
    int? productId,
    String? movementType,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _buildMovementsQuery(
      productId: productId,
      movementType: movementType,
      fromDate: fromDate,
      toDate: toDate,
    ).get();
  }

  Stream<List<TypedResult>> watchMovementsList({
    int? productId,
    String? movementType,
  }) {
    return _buildMovementsQuery(
      productId: productId,
      movementType: movementType,
    ).watch();
  }

  Future<int> insertMovement(InventoryMovementsCompanion companion) {
    return into(inventoryMovements).insert(companion);
  }
}
