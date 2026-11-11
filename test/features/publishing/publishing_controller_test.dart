import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:team_app/features/auth/providers/auth_provider.dart';
import 'package:team_app/features/properties/domain/entities/property.dart';
import 'package:team_app/features/publishing/domain/services/listing_validator.dart';
import 'package:team_app/features/publishing/presentation/providers/publishing_provider.dart';
import 'test_support.dart';

ProviderContainer _container(FakeListingRepository repo, {user = owner}) {
  final c = ProviderContainer(overrides: [
    listingRepositoryProvider.overrideWithValue(repo),
    currentUserProvider.overrideWithValue(user),
  ]);
  addTearDown(c.dispose);
  return c;
}

void _fill(PublishingController n) {
  n
    ..setPropertyType(PropertyType.apartment)
    ..setTransactionType(TransactionType.rent)
    ..setGovernorate('Tunis')
    ..setCity('La Marsa')
    ..setPriceText('1800')
    ..setSurfaceText('110')
    ..setBedrooms(2)
    ..setBathrooms(1)
    ..setTitle('Bright S+2 apartment in La Marsa')
    ..setDescription('Apartment with balcony and parking, close to the beach.')
    ..addPhotosForTest();
}

extension on PublishingController {
  void addPhotosForTest() {
    // Reuse the controller API: photos arrive through addPhotos in the app.
    // (kept tiny: the picker itself needs the platform, the controller does not)
    // ignore: invalid_use_of_protected_member
    state = state.copyWith(draft: state.draft.copyWith(photos: [photo('p1'), photo('p2')]));
  }
}

void main() {
  test('cannot move on while the current step is invalid; errors appear', () {
    final c = _container(FakeListingRepository());
    final n = c.read(publishingControllerProvider.notifier);
    n.next();
    final s = c.read(publishingControllerProvider);
    expect(s.step, PublishStep.type);
    expect(s.errors, isNotEmpty);
    n.setPropertyType(PropertyType.villa);
    n.setTransactionType(TransactionType.buy);
    n.next();
    expect(c.read(publishingControllerProvider).step, PublishStep.location);
  });

  test('full submission ends in success and creates exactly one listing', () async {
    final repo = FakeListingRepository();
    final c = _container(repo);
    final n = c.read(publishingControllerProvider.notifier);
    _fill(n);
    await n.submit();
    expect(c.read(publishingControllerProvider).isSuccess, isTrue);
    expect(repo.created, hasLength(1));
  });

  test('a second submit while busy / after success is ignored (no duplicates)', () async {
    final repo = FakeListingRepository();
    final c = _container(repo);
    final n = c.read(publishingControllerProvider.notifier);
    _fill(n);
    await Future.wait([n.submit(), n.submit()]);
    await n.submit();
    expect(repo.created, hasLength(1));
  });

  test('upload failure keeps the form, flags the photo and a retry succeeds', () async {
    final repo = FakeListingRepository()..failUploads.add('p2');
    final c = _container(repo);
    final n = c.read(publishingControllerProvider.notifier);
    _fill(n);
    await n.submit();
    var s = c.read(publishingControllerProvider);
    expect(s.isSuccess, isFalse);
    expect(s.failedPhotoIds, {'p2'});
    expect(s.message, isNotNull);
    expect(s.draft.title, isNotEmpty); // nothing lost
    expect(repo.created, isEmpty);

    repo.failUploads.clear();
    await n.submit();
    s = c.read(publishingControllerProvider);
    expect(s.isSuccess, isTrue);
    expect(repo.created.single['id'], s.listingId); // same document id on every attempt
  });

  test('a non-publisher account can never submit', () async {
    final repo = FakeListingRepository();
    final c = _container(repo, user: plainUser);
    final n = c.read(publishingControllerProvider.notifier);
    _fill(n);
    await n.submit();
    expect(c.read(publishingControllerProvider).isSuccess, isFalse);
    expect(repo.created, isEmpty);
  });

  test('editing from the preview returns straight to the preview', () {
    final c = _container(FakeListingRepository());
    final n = c.read(publishingControllerProvider.notifier);
    _fill(n);
    n.editFromPreview(PublishStep.details);
    n.setPriceText('2000');
    n.next();
    expect(c.read(publishingControllerProvider).step, PublishStep.preview);
  });

  test('changing to a type without rooms clears stale values; making a photo the cover reorders', () {
    final c = _container(FakeListingRepository());
    final n = c.read(publishingControllerProvider.notifier);
    _fill(n);
    n.setPropertyType(PropertyType.land);
    expect(c.read(publishingControllerProvider).draft.bedrooms, 0);
    n.makeCover('p2');
    expect(c.read(publishingControllerProvider).draft.photos.first.id, 'p2');
  });
}
