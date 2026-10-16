/// Case- and accent-insensitive text for search ("Béja" == "beja", "Gabès" == "gabes").
class TextNormalizer {
  TextNormalizer._();

  static const _from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ';
  static const _to = 'aaaaaaceeeeiiiinooooouuuuyyoa';

  static String normalize(String? input) {
    if (input == null) return '';
    final b = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      final i = _from.indexOf(ch);
      b.write(i >= 0 ? _to[i] : ch);
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Words of a query, normalised; empty list for a blank query.
  static List<String> tokens(String? input) {
    final n = normalize(input);
    return n.isEmpty ? const [] : n.split(' ');
  }
}
