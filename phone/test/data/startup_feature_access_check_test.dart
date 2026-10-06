import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/data/data.dart';

import '../helpers/feature_access_factories.dart';

void main() {
  late StreamController<Object?> reads;
  late FeatureAccess started;
  late FeatureAccess offered;
  late int asked;

  StartupFeatureAccessCheck check() {
    return StartupFeatureAccessCheck(
      systemInfoReads: reads.stream,
      current: () async {
        asked++;
        return offered;
      },
    );
  }

  setUp(() {
    reads = StreamController<Object?>.broadcast();
    started = featureAccessFor(systemInfoWithSupported(['voicemail', 'voicemailForward']));
    offered = started;
    asked = 0;
  });

  tearDown(() => reads.close());

  test('says nothing until the backend has been read', () async {
    offered = featureAccessFor(systemInfoWithSupported(['voicemail']));
    var answered = false;
    unawaited(check().changedSince(started).then((_) => answered = true));

    await pumpEventQueue();

    expect(answered, isFalse);
    expect(asked, 0);
  });

  test('a read that changes nothing leaves the session as it is', () async {
    final answer = check().changedSince(started);

    reads.add(null);

    expect(await answer, isNull);
  });

  test('a read that offers another configuration hands it over', () async {
    offered = featureAccessFor(systemInfoWithSupported(['voicemail']));
    final answer = check().changedSince(started);

    reads.add(null);

    expect(await answer, same(offered));
  });

  test('answers the first session of the run only', () async {
    final startup = check();
    final first = startup.changedSince(started);
    reads.add(null);
    await first;

    // The session that replaced the first one, or one after a sign-in: the
    // backend moves again, and it is not asked.
    offered = featureAccessFor(systemInfoWithSupported(const []));
    final second = startup.changedSince(started);
    reads.add(null);

    expect(await second, isNull);
    expect(asked, 1);
  });

  test('a session that asked and was gone before the read still spends the answer', () async {
    final startup = check();
    unawaited(startup.changedSince(started));

    offered = featureAccessFor(systemInfoWithSupported(const []));

    expect(await startup.changedSince(started), isNull);
  });

  test('an app that shuts down before the read gets no answer and no error', () async {
    final answer = check().changedSince(started);

    await reads.close();

    expect(await answer, isNull);
  });

  test('a host that draws its own configuration is never behind', () async {
    expect(await StartupFeatureAccessCheck.never().changedSince(started), isNull);
  });
}
