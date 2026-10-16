import '../../features/properties/domain/entities/property.dart';

class PriceFormatter {
  PriceFormatter._();

  /// `850,000 TND` for sales, `1,200 TND / month` for rentals.
  static String format(num price, String currency, TransactionType type) {
    final base = '${_group(price)} $currency';
    return type == TransactionType.rent ? '$base / month' : base;
  }

  static String _group(num value) {
    final s = value.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
