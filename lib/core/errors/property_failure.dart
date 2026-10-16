enum PropertyFailureType {
  /// Document does not exist.
  notFound,

  /// Exists but must not be shown (not published / malformed / no permission).
  unavailable,
  network,
  unknown,
}

class PropertyFailure implements Exception {
  const PropertyFailure(this.type);
  final PropertyFailureType type;

  String get message => switch (type) {
        PropertyFailureType.notFound ||
        PropertyFailureType.unavailable =>
          'This property is no longer available.',
        PropertyFailureType.network => "Couldn't load this property. Check your connection and try again.",
        PropertyFailureType.unknown => 'Something went wrong while loading this property.',
      };

  @override
  String toString() => 'PropertyFailure($type)';
}
