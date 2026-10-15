enum FavoriteFailureType {
  /// Firestore rules refused the operation (not signed in, wrong user...).
  permissionDenied,
  network,

  /// Empty user / property id.
  invalidInput,
  unknown,
}

/// The only exception the favorites repository throws (same idea as
/// `PropertyFailure` / `AuthFailure`), so the UI never sees Firebase types.
class FavoriteFailure implements Exception {
  const FavoriteFailure(this.type);
  final FavoriteFailureType type;

  String get message => switch (type) {
        FavoriteFailureType.permissionDenied => "You can't change favorites right now. Please sign in again.",
        FavoriteFailureType.network => "Couldn't reach the server. Check your connection and try again.",
        FavoriteFailureType.invalidInput => 'This property cannot be saved.',
        FavoriteFailureType.unknown => 'Something went wrong with your favorites.',
      };

  @override
  String toString() => 'FavoriteFailure($type)';
}