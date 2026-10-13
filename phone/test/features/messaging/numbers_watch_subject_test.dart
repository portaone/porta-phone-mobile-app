import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockSmsRepository extends Mock implements SmsRepository {}

/// The user's own SMS numbers are watched once per repository and shared by
/// every screen that shows them.
void main() {
  _MockSmsRepository repositoryWith(List<String> numbers) {
    final repository = _MockSmsRepository();
    when(() => repository.watchUserSmsNumbers()).thenAnswer((_) => Stream.value(numbers));
    return repository;
  }

  test('screens of one repository share one subject', () {
    final repository = repositoryWith(const ['+16042000001']);

    expect(identical(NumbersWatchSubject(repository), NumbersWatchSubject(repository)), isTrue);
  });

  test('a new repository is read instead of the one that came first', () async {
    // A new main shell after signing in again brings a new repository; the
    // subject used to keep reading the first one it was ever given.
    final first = repositoryWith(const ['+16042000001']);
    final second = repositoryWith(const ['+16042000002']);
    expect(await NumbersWatchSubject(first).stream.first, ['+16042000001']);

    expect(await NumbersWatchSubject(second).stream.first, ['+16042000002']);
  });
}
