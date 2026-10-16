enum DiscoveryFailureType { network, permissionDenied, unknown }

/// Error surfaced by the discovery data layer. Never carries raw Firebase text.
class DiscoveryFailure implements Exception {
  const DiscoveryFailure(this.type);
  final DiscoveryFailureType type;

  String get message => switch (type) {
        DiscoveryFailureType.network => "Couldn't load properties. Check your connection and try again.",
        DiscoveryFailureType.permissionDenied => "You don't have access to these listings right now.",
        DiscoveryFailureType.unknown => 'Something went wrong while loading properties.',
      };

  @override
  String toString() => 'DiscoveryFailure($type)';
}
