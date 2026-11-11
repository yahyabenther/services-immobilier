import 'package:flutter_test/flutter_test.dart';

import 'package:team_app/features/publishing/domain/publishing_failure.dart';
import 'package:team_app/features/publishing/domain/usecases/submit_listing.dart';
import 'test_support.dart';

void main() {
  late FakeListingRepository repo;
  late SubmitListing submit;
  setUp(() {
    repo = FakeListingRepository();
    submit = SubmitListing(repo);
  });

  Future<PublishingFailure> failureOf(Future<void> Function() run) async {
    try {
      await run();
    } on PublishingFailure catch (e) {
      return e;
    }
    fail('expected a PublishingFailure');
  }

  test('happy path uploads every photo, then creates ONE document with ordered urls', () async {
    final uploaded = <String, String>{};
    await submit(listingId: 'L', user: owner, draft: validDraft(), uploaded: uploaded);
    expect(repo.created, hasLength(1));
    expect((repo.created.single['urls'] as List).map((u) => (u as String).split('/').last), ['p1.jpg', 'p2.jpg']);
  });

  test('refuses anonymous and non-publisher accounts without touching anything', () async {
    expect((await failureOf(() => submit(listingId: 'L', user: null, draft: validDraft(), uploaded: {}))).type, PublishingFailureType.notAuthenticated);
    expect((await failureOf(() => submit(listingId: 'L', user: plainUser, draft: validDraft(), uploaded: {}))).type, PublishingFailureType.notAllowed);
    expect(repo.uploadCalls, isEmpty);
    expect(repo.created, isEmpty);
  });

  test('invalid data: nothing is uploaded or written', () async {
    final f = await failureOf(() => submit(listingId: 'L', user: owner, draft: validDraft().copyWith(title: ''), uploaded: {}));
    expect(f.type, PublishingFailureType.invalidData);
    expect(f.fieldErrors, isNotEmpty);
    expect(repo.uploadCalls, isEmpty);
  });

  test('a failed photo blocks the submission, and the retry re-uploads only that photo', () async {
    final uploaded = <String, String>{};
    final draft = validDraft(photos: [photo('p1'), photo('p2'), photo('p3')]);
    repo.failUploads.add('p2');

    final f = await failureOf(() => submit(listingId: 'L', user: owner, draft: draft, uploaded: uploaded));
    expect(f.type, PublishingFailureType.uploadFailed);
    expect(f.failedPhotoIds, {'p2'});
    expect(repo.created, isEmpty); // never a listing with missing media

    repo.failUploads.clear();
    repo.uploadCalls.clear();
    await submit(listingId: 'L', user: owner, draft: draft, uploaded: uploaded);
    expect(repo.uploadCalls, ['p2']);
    expect(repo.created, hasLength(1));
  });

  test('progress is reported up to done == total', () async {
    final seen = <String>[];
    await submit(listingId: 'L', user: agent, draft: validDraft(), uploaded: {}, onProgress: (d, t) => seen.add('$d/$t'));
    expect(seen.first, '0/2');
    expect(seen.last, '2/2');
  });

  test('a failed Firestore write surfaces the failure and keeps uploaded urls for the retry', () async {
    final uploaded = <String, String>{};
    repo.createFails = true;
    final f = await failureOf(() => submit(listingId: 'L', user: owner, draft: validDraft(), uploaded: uploaded));
    expect(f.type, PublishingFailureType.network);
    expect(uploaded, hasLength(2));

    repo.createFails = false;
    repo.uploadCalls.clear();
    await submit(listingId: 'L', user: owner, draft: validDraft(), uploaded: uploaded);
    expect(repo.uploadCalls, isEmpty); // nothing uploaded twice
    expect(repo.created, hasLength(1));
  });
}
