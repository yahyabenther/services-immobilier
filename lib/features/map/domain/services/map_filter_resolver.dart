import '../../../search/domain/entities/property_search_filter.dart';

/// Filter the map starts with.
///
/// - `/map?source=search` -> the filter currently applied in Module 04 (same semantics).
/// - Home entries (`governorate`, `lat`, `lng`, `transactionType`) go through the SAME
///   parser as Search, so both modules interpret route parameters identically.
PropertySearchFilter resolveMapFilter(
  Map<String, String> params, {
  required PropertySearchFilter searchFilter,
}) {
  final base = params['source'] == 'search' ? searchFilter : const PropertySearchFilter();
  return PropertySearchFilter.fromQueryParameters(params, base: base);
}
