/// Sort modes (spec §3.3).
enum SortOption {
  recommended('Recommended'),
  newest('Newest'),
  lowestPrice('Lowest price'),
  highestPrice('Highest price'),
  largestSurface('Largest surface'),
  closest('Closest');

  const SortOption(this.label);
  final String label;

  /// Recommended and Closest are ranked on the device, over a window of the most
  /// recent matches (Firestore cannot rank by these).
  bool get isWindowed => this == recommended || this == closest;
}

/// Bedroom choices (spec §3.2-F). `fourPlus` means "4 or more".
enum BedroomChoice {
  studio('Studio'),
  one('1'),
  two('2'),
  three('3'),
  fourPlus('4+');

  const BedroomChoice(this.label);
  final String label;
}

/// Bathroom choices (spec §3.2-G). `threePlus` means "3 or more".
enum BathroomChoice {
  one('1'),
  two('2'),
  threePlus('3+');

  const BathroomChoice(this.label);
  final String label;
}

/// The segment shown above the results: All / Buy / Rent / New.
enum ListingTab { all, buy, rent, newBuild }
