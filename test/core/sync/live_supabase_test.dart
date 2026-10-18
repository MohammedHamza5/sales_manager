import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sales_manager/core/config/supabase_config.dart';

void main() {
  late SupabaseClient client;
  const uuid = Uuid();
  final testDeviceId = 'test_device_${uuid.v4().substring(0, 8)}';

  setUpAll(() {
    client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);
  });

  group('Live Supabase Online Integration Tests', () {
    test('1. Product full lifecycle (insert, update, select, delete)', () async {
      final productId = uuid.v4();
      final productCode = 'PROD_${uuid.v4().substring(0, 6)}';

      // Insert
      final insertData = {
        'id': productId,
        'name': 'اختبار منتج حقيقي',
        'code': productCode,
        'unit': 'قطعة',
        'current_sale_price': 15000,
        'current_purchase_price': 10000,
        'current_quantity': 25.5,
        'low_stock_threshold': 5.0,
        'is_active': true,
        'device_id': testDeviceId,
        'created_by': 'tester',
      };

      await client.from('products').upsert(insertData);

      // Verify Select
      final fetched = await client
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      expect(fetched['id'], equals(productId));
      expect(fetched['name'], equals('اختبار منتج حقيقي'));
      expect(fetched['device_id'], equals(testDeviceId));
      expect(fetched['current_sale_price'], equals(15000));

      // Update
      await client
          .from('products')
          .update({'current_sale_price': 18000, 'current_quantity': 30.0})
          .eq('id', productId);

      final updated = await client
          .from('products')
          .select()
          .eq('id', productId)
          .single();

      expect(updated['current_sale_price'], equals(18000));

      // Clean up
      await client.from('products').delete().eq('id', productId);
    });

    test('2. Customer lifecycle (insert, update, select, delete)', () async {
      final customerId = uuid.v4();
      final phone = '010${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      final insertData = {
        'id': customerId,
        'name': 'عميل تجريبي أونلاين',
        'phone': phone,
        'address': 'القاهرة',
        'notes': 'ملاحظات تجريبية',
        'current_balance': 5000,
        'is_active': true,
        'device_id': testDeviceId,
        'created_by': 'tester',
      };

      await client.from('customers').upsert(insertData);

      final fetched = await client
          .from('customers')
          .select()
          .eq('id', customerId)
          .single();

      expect(fetched['id'], equals(customerId));
      expect(fetched['name'], equals('عميل تجريبي أونلاين'));
      expect(fetched['current_balance'], equals(5000));
      expect(fetched['device_id'], equals(testDeviceId));

      // Clean up
      await client.from('customers').delete().eq('id', customerId);
    });

    test('3. Supplier lifecycle (insert, update, select, delete)', () async {
      final supplierId = uuid.v4();
      final phone = '011${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

      final insertData = {
        'id': supplierId,
        'name': 'مورد تجريبي أونلاين',
        'phone': phone,
        'address': 'الإسكندرية',
        'notes': 'ملاحظات تجريبية للمورد',
        'current_balance': 12000,
        'is_active': true,
        'device_id': testDeviceId,
        'created_by': 'tester',
      };

      await client.from('suppliers').upsert(insertData);

      final fetched = await client
          .from('suppliers')
          .select()
          .eq('id', supplierId)
          .single();

      expect(fetched['id'], equals(supplierId));
      expect(fetched['name'], equals('مورد تجريبي أونلاين'));
      expect(fetched['current_balance'], equals(12000));

      // Clean up
      await client.from('suppliers').delete().eq('id', supplierId);
    });

    test('4. End-to-end Sales & Sale Items with Foreign Keys', () async {
      final customerId = uuid.v4();
      final productId = uuid.v4();
      final saleId = uuid.v4();
      final saleItemId = uuid.v4();

      // 1. Create parent customer
      await client.from('customers').insert({
        'id': customerId,
        'name': 'عميل الفاتورة',
        'device_id': testDeviceId,
      });

      // 2. Create parent product
      await client.from('products').insert({
        'id': productId,
        'name': 'منتج الفاتورة',
        'unit': 'قطعة',
        'current_sale_price': 5000,
        'current_purchase_price': 3000,
        'current_quantity': 100,
        'device_id': testDeviceId,
      });

      // 3. Insert sale
      await client.from('sales').insert({
        'id': saleId,
        'invoice_no': DateTime.now().millisecondsSinceEpoch,
        'customer_id': customerId,
        'sale_date': DateTime.now().toUtc().toIso8601String(),
        'total_amount': 15000,
        'paid_amount_at_creation': 10000,
        'status': 'confirmed',
        'device_id': testDeviceId,
        'created_by': 'tester',
      });

      // 4. Insert sale_item
      await client.from('sale_items').insert({
        'id': saleItemId,
        'sale_id': saleId,
        'product_id': productId,
        'quantity': 3.0,
        'unit_price_at_sale': 5000,
        'line_total': 15000,
        'device_id': testDeviceId,
      });

      // Verify Sale with items
      final saleRow = await client
          .from('sales')
          .select('*, sale_items(*)')
          .eq('id', saleId)
          .single();

      expect(saleRow['id'], equals(saleId));
      expect(saleRow['total_amount'], equals(15000));
      final items = saleRow['sale_items'] as List;
      expect(items.length, equals(1));
      expect(items.first['unit_price_at_sale'], equals(5000));

      // Clean up in reverse FK order
      await client.from('sale_items').delete().eq('id', saleItemId);
      await client.from('sales').delete().eq('id', saleId);
      await client.from('products').delete().eq('id', productId);
      await client.from('customers').delete().eq('id', customerId);
    });

    test('5. Purchases & Purchase Items with Foreign Keys', () async {
      final supplierId = uuid.v4();
      final productId = uuid.v4();
      final purchaseId = uuid.v4();
      final purchaseItemId = uuid.v4();

      await client.from('suppliers').insert({
        'id': supplierId,
        'name': 'مورد المشتريات',
        'device_id': testDeviceId,
      });

      await client.from('products').insert({
        'id': productId,
        'name': 'منتج الشراء',
        'unit': 'كرتونة',
        'current_sale_price': 8000,
        'current_purchase_price': 6000,
        'device_id': testDeviceId,
      });

      await client.from('purchases').insert({
        'id': purchaseId,
        'invoice_no': DateTime.now().millisecondsSinceEpoch,
        'supplier_id': supplierId,
        'purchase_date': DateTime.now().toUtc().toIso8601String(),
        'total_amount': 60000,
        'paid_amount_at_creation': 30000,
        'status': 'confirmed',
        'device_id': testDeviceId,
        'created_by': 'tester',
      });

      await client.from('purchase_items').insert({
        'id': purchaseItemId,
        'purchase_id': purchaseId,
        'product_id': productId,
        'quantity': 10.0,
        'unit_cost_at_purchase': 6000,
        'line_total': 60000,
        'device_id': testDeviceId,
      });

      final purchaseRow = await client
          .from('purchases')
          .select('*, purchase_items(*)')
          .eq('id', purchaseId)
          .single();

      expect(purchaseRow['id'], equals(purchaseId));
      final items = purchaseRow['purchase_items'] as List;
      expect(items.length, equals(1));

      // Clean up
      await client.from('purchase_items').delete().eq('id', purchaseItemId);
      await client.from('purchases').delete().eq('id', purchaseId);
      await client.from('products').delete().eq('id', productId);
      await client.from('suppliers').delete().eq('id', supplierId);
    });

    test('6. Customer Returns & Items with Foreign Keys', () async {
      final customerId = uuid.v4();
      final productId = uuid.v4();
      final returnId = uuid.v4();
      final returnItemId = uuid.v4();

      await client.from('customers').insert({
        'id': customerId,
        'name': 'عميل المرتجع',
        'device_id': testDeviceId,
      });

      await client.from('products').insert({
        'id': productId,
        'name': 'منتج المرتجع',
        'unit': 'قطعة',
        'current_sale_price': 2000,
        'current_purchase_price': 1500,
        'device_id': testDeviceId,
      });

      await client.from('returns_customer').insert({
        'id': returnId,
        'customer_id': customerId,
        'return_date': DateTime.now().toUtc().toIso8601String(),
        'total_amount': 4000,
        'device_id': testDeviceId,
        'created_by': 'tester',
      });

      await client.from('return_customer_items').insert({
        'id': returnItemId,
        'return_id': returnId,
        'product_id': productId,
        'quantity': 2.0,
        'unit_price': 2000,
        'line_total': 4000,
        'device_id': testDeviceId,
      });

      final retRow = await client
          .from('returns_customer')
          .select('*, return_customer_items(*)')
          .eq('id', returnId)
          .single();

      expect(retRow['total_amount'], equals(4000));
      final items = retRow['return_customer_items'] as List;
      expect(items.length, equals(1));

      // Clean up
      await client.from('return_customer_items').delete().eq('id', returnItemId);
      await client.from('returns_customer').delete().eq('id', returnId);
      await client.from('products').delete().eq('id', productId);
      await client.from('customers').delete().eq('id', customerId);
    });

    test('7. Supplier Returns & Items with Foreign Keys', () async {
      final supplierId = uuid.v4();
      final productId = uuid.v4();
      final returnId = uuid.v4();
      final returnItemId = uuid.v4();

      await client.from('suppliers').insert({
        'id': supplierId,
        'name': 'مورد المرتجع',
        'device_id': testDeviceId,
      });

      await client.from('products').insert({
        'id': productId,
        'name': 'منتج مرتجع المورد',
        'unit': 'قطعة',
        'current_sale_price': 4000,
        'current_purchase_price': 3000,
        'device_id': testDeviceId,
      });

      await client.from('returns_supplier').insert({
        'id': returnId,
        'supplier_id': supplierId,
        'return_date': DateTime.now().toUtc().toIso8601String(),
        'total_amount': 9000,
        'device_id': testDeviceId,
        'created_by': 'tester',
      });

      await client.from('return_supplier_items').insert({
        'id': returnItemId,
        'return_id': returnId,
        'product_id': productId,
        'quantity': 3.0,
        'unit_price': 3000,
        'line_total': 9000,
        'device_id': testDeviceId,
      });

      final retRow = await client
          .from('returns_supplier')
          .select('*, return_supplier_items(*)')
          .eq('id', returnId)
          .single();

      expect(retRow['total_amount'], equals(9000));

      // Clean up
      await client.from('return_supplier_items').delete().eq('id', returnItemId);
      await client.from('returns_supplier').delete().eq('id', returnId);
      await client.from('products').delete().eq('id', productId);
      await client.from('suppliers').delete().eq('id', supplierId);
    });

    test('8. Customer Payments & Supplier Payments', () async {
      final customerId = uuid.v4();
      final supplierId = uuid.v4();
      final custPayId = uuid.v4();
      final suppPayId = uuid.v4();

      await client.from('customers').insert({
        'id': customerId,
        'name': 'عميل السداد',
        'device_id': testDeviceId,
      });

      await client.from('suppliers').insert({
        'id': supplierId,
        'name': 'مورد السداد',
        'device_id': testDeviceId,
      });

      // Customer Payment
      await client.from('customer_payments').insert({
        'id': custPayId,
        'customer_id': customerId,
        'amount': 2500,
        'payment_date': DateTime.now().toUtc().toIso8601String(),
        'note': 'سداد قسط',
        'device_id': testDeviceId,
        'created_by': 'tester',
      });

      // Supplier Payment
      await client.from('supplier_payments').insert({
        'id': suppPayId,
        'supplier_id': supplierId,
        'amount': 7000,
        'payment_date': DateTime.now().toUtc().toIso8601String(),
        'note': 'دفعة تحت الحساب',
        'device_id': testDeviceId,
        'created_by': 'tester',
      });

      final cp = await client.from('customer_payments').select().eq('id', custPayId).single();
      expect(cp['amount'], equals(2500));

      final sp = await client.from('supplier_payments').select().eq('id', suppPayId).single();
      expect(sp['amount'], equals(7000));

      // Clean up
      await client.from('customer_payments').delete().eq('id', custPayId);
      await client.from('supplier_payments').delete().eq('id', suppPayId);
      await client.from('customers').delete().eq('id', customerId);
      await client.from('suppliers').delete().eq('id', supplierId);
    });

    test('9. Expenses, Stock Adjustments, and Pull filters', () async {
      final expenseId = uuid.v4();
      final productId = uuid.v4();
      final adjId = uuid.v4();

      await client.from('expenses').insert({
        'id': expenseId,
        'category': 'كهرباء',
        'amount': 35000,
        'expense_date': DateTime.now().toUtc().toIso8601String(),
        'note': 'فاتورة شهر مايو',
        'device_id': testDeviceId,
        'created_by': 'tester',
      });

      await client.from('products').insert({
        'id': productId,
        'name': 'منتج للتسوية',
        'unit': 'قطعة',
        'current_sale_price': 1000,
        'current_purchase_price': 700,
        'device_id': testDeviceId,
      });

      await client.from('stock_adjustments').insert({
        'id': adjId,
        'product_id': productId,
        'quantity_delta': -2.5,
        'reason': 'تلف أثناء النقل',
        'adjustment_date': DateTime.now().toUtc().toIso8601String(),
        'device_id': testDeviceId,
        'created_by': 'tester',
      });

      final exp = await client.from('expenses').select().eq('id', expenseId).single();
      expect(exp['amount'], equals(35000));

      final adj = await client.from('stock_adjustments').select().eq('id', adjId).single();
      expect(adj['reason'], equals('تلف أثناء النقل'));

      // Test pull query with updated_at filter using server time
      final serverTimeStr = await client.rpc<String>('get_server_time');
      final serverNow = DateTime.parse(serverTimeStr);
      final pastTime = serverNow.subtract(const Duration(hours: 1));

      final pullResults = await client
          .from('expenses')
          .select()
          .gt('updated_at', pastTime.toIso8601String())
          .eq('id', expenseId);
      expect(pullResults.length, equals(1));

      // Clean up
      await client.from('expenses').delete().eq('id', expenseId);
      await client.from('stock_adjustments').delete().eq('id', adjId);
      await client.from('products').delete().eq('id', productId);
    });
  });
}
