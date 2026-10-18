import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Represents money stored strictly as an [int] of smallest currency units (Piastres / قرش).
/// 1 Egyptian Pound (ج.م) = 100 Piastres.
/// Absolutely NO floating-point (double) math is permitted.
final class Money {
  /// The amount in piastres (قرش).
  final int piastres;

  const Money(this.piastres);

  const Money.fromPiastres(this.piastres);

  /// Formatted string with currency e.g. "150.50 ج.م"
  String get formatted => formatArabic(showCurrency: true);

  /// Formatted number without currency e.g. "150.50"
  String get formattedWithoutCurrency => formatArabic(showCurrency: false);

  /// Creates a Money instance from whole pounds and piastres without floating point math.
  factory Money.fromPounds(int pounds, [int piastres = 0]) {
    final total = (pounds * 100) + piastres;
    return Money.fromPiastres(total);
  }

  /// Parses an Arabic or Western string (e.g. "125.50" or "125,50" or "125") into Money.
  /// Does NOT use double parsing to avoid precision errors.
  static Money? tryParse(String input) {
    final sanitized = input.trim().replaceAll(',', '.').replaceAll(' ', '');
    if (sanitized.isEmpty) return null;

    final parts = sanitized.split('.');
    if (parts.length > 2) return null;

    final poundsStr = parts[0];
    final isNegative = poundsStr.startsWith('-');
    final cleanPounds = isNegative ? poundsStr.substring(1) : poundsStr;

    final pounds = cleanPounds.isEmpty ? 0 : int.tryParse(cleanPounds);
    if (pounds == null) return null;

    var piastres = 0;
    if (parts.length == 2) {
      var piastresStr = parts[1];
      if (piastresStr.length > 2) {
        piastresStr = piastresStr.substring(0, 2);
      } else if (piastresStr.length == 1) {
        piastresStr = '${piastresStr}0';
      }
      final parsedP = int.tryParse(piastresStr);
      if (parsedP == null) return null;
      piastres = parsedP;
    }

    final total = (pounds * 100) + piastres;
    return Money.fromPiastres(isNegative ? -total : total);
  }

  static const Money zero = Money.fromPiastres(0);

  int get pounds => piastres ~/ 100;
  int get remainingPiastres => (piastres % 100).abs();

  Money operator +(Money other) => Money.fromPiastres(piastres + other.piastres);
  Money operator -(Money other) => Money.fromPiastres(piastres - other.piastres);
  Money operator -() => Money.fromPiastres(-piastres);
  Money operator *(int factor) => Money.fromPiastres(piastres * factor);
  Money multiplyByQuantity(Decimal quantity) {
    final result = (Decimal.fromInt(piastres) * quantity).toBigInt().toInt();
    return Money.fromPiastres(result);
  }
  Money abs() => Money.fromPiastres(piastres.abs());
  Money clampToZero() => piastres < 0 ? Money.zero : this;

  bool operator >(Money other) => piastres > other.piastres;
  bool operator <(Money other) => piastres < other.piastres;
  bool operator >=(Money other) => piastres >= other.piastres;
  bool operator <=(Money other) => piastres <= other.piastres;

  /// Formatted string in Arabic e.g. "150.50 ج.م"
  String formatArabic({bool showCurrency = true}) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final formattedNumber = formatter.format(piastres / 100.0);
    return showCurrency ? '$formattedNumber ج.م' : formattedNumber;
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Money && other.piastres == piastres);

  @override
  int get hashCode => piastres.hashCode;

  @override
  String toString() => formatArabic();
}
