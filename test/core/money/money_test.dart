import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_manager/core/money/money.dart';
import 'package:sales_manager/core/money/quantity.dart';

void main() {
  group('Money Value Object tests', () {
    test('Zero money has 0 piastres', () {
      expect(Money.zero.piastres, 0);
    });

    test('Pounds to piastres conversion is exact without floating point errors', () {
      final money = Money.fromPounds(150, 75);
      expect(money.piastres, 15075);
      expect(money.pounds, 150);
      expect(money.remainingPiastres, 75);
    });

    test('String parsing handles decimals and integers accurately', () {
      expect(Money.tryParse('100')?.piastres, 10000);
      expect(Money.tryParse('100.5')?.piastres, 10050);
      expect(Money.tryParse('100.50')?.piastres, 10050);
      expect(Money.tryParse('100.05')?.piastres, 10005);
      expect(Money.tryParse('100,25')?.piastres, 10025);
      expect(Money.tryParse('-50.25')?.piastres, -5025);
    });

    test('Addition, subtraction and scalar multiplication', () {
      const m1 = Money.fromPiastres(10050); // 100.50
      const m2 = Money.fromPiastres(2025);  // 20.25

      expect((m1 + m2).piastres, 12075);
      expect((m1 - m2).piastres, 8025);
      expect((m2 * 3).piastres, 6075);
    });
  });

  group('QuantityHelper tests', () {
    test('Decimal parsing preserves exact fractional values', () {
      final q1 = QuantityHelper.tryParse('1.250');
      expect(q1, Decimal.parse('1.25'));

      final q2 = QuantityHelper.tryParse('0.005');
      expect(q2, Decimal.parse('0.005'));
    });
  });
}
