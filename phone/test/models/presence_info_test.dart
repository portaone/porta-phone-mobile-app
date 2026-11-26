import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/models/models.dart';

PresenceInfo _presence({
  required String id,
  required PresenceInfoSource source,
  bool available = true,
  String note = '',
  String? statusIcon,
  List<PresenceActivity> activities = const [],
  DateTime? timestamp,
}) => PresenceInfo(
  id: id,
  number: '1001',
  available: available,
  note: note,
  statusIcon: statusIcon,
  device: null,
  timeOffsetMin: null,
  timestamp: timestamp,
  activities: activities,
  source: source,
  // As Core stamps it: a moment after the state began on the device.
  arrivalTime: (timestamp ?? DateTime(2026, 11, 24)).add(const Duration(seconds: 1)),
);

void main() {
  final earlier = DateTime(2026, 11, 24, 10);
  final later = DateTime(2026, 11, 24, 11);

  group('the source that answers first: direct, then SIP', () {
    test('only the direct records are left when both sources have some', () {
      final app = _presence(id: 'app', source: PresenceInfoSource.direct);
      final pbx = _presence(id: 'pbx', source: PresenceInfoSource.sip);

      expect([pbx, app].leadingSource, [app]);
    });

    test('the SIP records are used when there is no direct one', () {
      final pbx = _presence(id: 'pbx', source: PresenceInfoSource.sip);

      expect([pbx].leadingSource, [pbx]);
    });

    test('nothing in, nothing out', () {
      expect(const <PresenceInfo>[].leadingSource, isEmpty);
    });
  });

  group('whether a contact can be reached', () {
    test('is what was published, whatever the registration says', () {
      final closed = _presence(id: 'pbx', source: PresenceInfoSource.sip, available: false);
      final open = _presence(id: 'pbx', source: PresenceInfoSource.sip, available: true);

      expect([closed].reachable(registered: true), isFalse);
      expect([open].reachable(registered: false), isTrue);
    });

    test('is what the direct record says when a SIP record disagrees', () {
      final app = _presence(id: 'app', source: PresenceInfoSource.direct, available: false);
      final pbx = _presence(id: 'pbx', source: PresenceInfoSource.sip, available: true);

      expect([pbx, app].reachable(registered: true), isFalse);
    });

    test('is the registration when nothing was published', () {
      expect(const <PresenceInfo>[].reachable(registered: true), isTrue);
      expect(const <PresenceInfo>[].reachable(registered: false), isFalse);
    });

    test('is no when nothing is known at all', () {
      expect(const <PresenceInfo>[].reachable(registered: null), isFalse);
    });
  });

  group('the record a contact is described by', () {
    test('is the direct one even when the SIP one is available and newer', () {
      // Without an order the available record won, so somebody who had set
      // themselves unavailable in the app showed as available as long as the
      // PBX still held an old publication from any device of theirs.
      final app = _presence(id: 'app', source: PresenceInfoSource.direct, available: false, timestamp: earlier);
      final pbx = _presence(id: 'pbx', source: PresenceInfoSource.sip, available: true, timestamp: later);

      expect([pbx, app].primary, app);
    });

    test('takes its activity from the direct record, not from a SIP record on the phone', () {
      final app = _presence(id: 'app', source: PresenceInfoSource.direct, activities: const [PresenceActivity.away]);
      final pbx = _presence(id: 'pbx', source: PresenceInfoSource.sip, activities: const [PresenceActivity.onThePhone]);

      expect([pbx, app].primaryActivity, PresenceActivity.away);
    });

    test('takes its note and icon from the direct record', () {
      final app = _presence(id: 'app', source: PresenceInfoSource.direct, note: 'From the app', statusIcon: 'A');
      final pbx = _presence(id: 'pbx', source: PresenceInfoSource.sip, note: 'From the desk', statusIcon: 'D');

      expect([pbx, app].primaryNote, 'From the app');
      expect([pbx, app].primaryStatusIcon, 'A');
    });

    test('is the SIP one when nothing direct is known', () {
      final pbx = _presence(id: 'pbx', source: PresenceInfoSource.sip, activities: const [PresenceActivity.meeting]);

      expect([pbx].primary, pbx);
      expect([pbx].primaryActivity, PresenceActivity.meeting);
    });
  });

  group('with several records of one source the newest state is the contact\'s status', () {
    PresenceInfo app(
      String id,
      DateTime since, {
      bool available = true,
      List<PresenceActivity> activities = const [],
    }) => _presence(
      id: id,
      source: PresenceInfoSource.direct,
      available: available,
      activities: activities,
      timestamp: since,
    );

    test('away set last hides an earlier available on another device', () {
      final phone = app('phone', earlier);
      final web = app('web', later, available: false, activities: const [PresenceActivity.away]);

      expect([phone, web].primary, web);
      expect([phone, web].primaryActivity, PresenceActivity.away);
      expect([phone, web].reachable(registered: true), isFalse);
    });

    test('do not disturb set last is not outvoted by a device still saying available', () {
      // Somebody who has just asked not to be called must not show as free
      // because their other device was left on its default.
      final phone = app('phone', earlier);
      final web = app('web', later, available: false, activities: const [PresenceActivity.doNotDisturb]);

      expect([phone, web].primaryActivity, PresenceActivity.doNotDisturb);
    });

    test('unavailable set last hides an earlier available', () {
      final phone = app('phone', earlier);
      final web = app('web', later, available: false);

      expect([phone, web].primary, web);
      expect([phone, web].reachable(registered: true), isFalse);
    });

    test('available set last clears an activity left on another device', () {
      final phone = app('phone', earlier, activities: const [PresenceActivity.meeting]);
      final web = app('web', later);

      expect([phone, web].primary, web);
      expect([phone, web].primaryActivity, isNull);
      expect([phone, web].reachable(registered: false), isTrue);
    });

    test('unavailable set last clears an earlier away', () {
      final phone = app('phone', earlier, available: false, activities: const [PresenceActivity.away]);
      final web = app('web', later, available: false);

      expect([phone, web].primaryActivity, isNull);
    });

    test('the order of the list does not matter, only the times do', () {
      final phone = app('phone', later, available: false);
      final web = app('web', earlier);

      expect([phone, web].primary, phone);
      expect([web, phone].primary, phone);
    });

    test('a call on any device still outranks whatever was set last', () {
      final phone = app('phone', earlier, activities: const [PresenceActivity.onThePhone]);
      final web = app('web', later, available: false, activities: const [PresenceActivity.away]);

      expect([phone, web].primaryActivity, PresenceActivity.onThePhone);
    });

    test('a device whose clock runs ahead does not win by that', () {
      // A state cannot have begun after Core heard of it, so a time from the
      // future is cut back to the arrival. Otherwise a phone set a day ahead
      // would describe its owner for good, whatever they did elsewhere.
      PresenceInfo at(String id, DateTime claimed, DateTime arrived, {required bool available}) => PresenceInfo(
        id: id,
        number: '1001',
        available: available,
        note: '',
        statusIcon: null,
        device: null,
        timeOffsetMin: null,
        timestamp: claimed,
        activities: const [],
        source: PresenceInfoSource.direct,
        arrivalTime: arrived,
      );
      final phone = at('phone', later.add(const Duration(days: 1)), earlier, available: true);
      final web = at('web', later, later, available: false);

      expect([phone, web].primary, web);
    });

    test('two states that began together go by which Core heard of later', () {
      PresenceInfo at(String id, DateTime arrived) => PresenceInfo(
        id: id,
        number: '1001',
        available: id == 'second',
        note: '',
        statusIcon: null,
        device: null,
        timeOffsetMin: null,
        timestamp: earlier,
        activities: const [],
        source: PresenceInfoSource.direct,
        arrivalTime: arrived,
      );
      final first = at('first', later);
      final second = at('second', later.add(const Duration(seconds: 5)));

      expect([first, second].primary, second);
      expect([second, first].primary, second);
    });

    test('a record that carries no time of its own is placed by when Core received it', () {
      final dated = app('dated', earlier);
      final undated = PresenceInfo(
        id: 'undated',
        number: '1001',
        available: false,
        note: '',
        statusIcon: null,
        device: null,
        timeOffsetMin: null,
        timestamp: null,
        activities: const [],
        source: PresenceInfoSource.direct,
        arrivalTime: later,
      );

      expect([dated, undated].primary, undated);
    });
  });
}
