import 'package:decimal/decimal.dart';

/// Helper utilities for handling fractional quantities with arbitrary precision via [Decimal].
/// Double math is strictly prohibited for stock quantities.
abstract final class QuantityHelper {
  static Decimal zero = Decimal.zero;

  static Decimal? tryParse(String input) {
    final sanitized = input.trim().replaceAll(',', '.').replaceAll(' ', '');
    if (sanitized.isEmpty) return null;
    return Decimal.tryParse(sanitized);
  }

  static String format(Decimal quantity, {String? unit}) {
    final formatted = quantity.toString();
    if (unit != null && unit.isNotEmpty) {
      return '$formatted $unit';
    }
    return formatted;
  }
}
