import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../properties/domain/entities/property.dart';
import '../data/my_listings_repository.dart';

final myListingsRepositoryProvider = Provider<MyListingsRepository>(
  (ref) => MyListingsRepository(ref.watch(firestoreProvider)),
);

/// Live list of the signed-in user's listings. Resets on logout.
final myListingsProvider = StreamProvider.autoDispose<List<Property>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(myListingsRepositoryProvider).watchMine(user.id);
});