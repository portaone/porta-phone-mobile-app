import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/environment_config.dart';

void main() {
  group('EnvRegistry', () {
    late EnvRegistry registry;

    setUp(() => registry = EnvRegistry());

    test('string: override wins; empty and missing fall back to compile-time', () {
      registry.apply({'A': 'override'});
      expect(registry.string('A', 'default'), 'override');

      registry.apply({'A': ''});
      expect(registry.string('A', 'default'), 'default');

      registry.apply({});
      expect(registry.string('A', 'default'), 'default');
    });

    test('stringOrNull: empty and missing fall back (may be null)', () {
      registry.apply({'A': ''});
      expect(registry.stringOrNull('A', null), isNull);
      expect(registry.stringOrNull('A', 'd'), 'd');

      registry.apply({'A': 'x'});
      expect(registry.stringOrNull('A', 'd'), 'x');
    });

    test('boolean: true/false honoured; malformed and empty fall back', () {
      registry.apply({'B': 'TRUE'});
      expect(registry.boolean('B', false), isTrue);

      registry.apply({'B': 'false'});
      expect(registry.boolean('B', true), isFalse);

      registry.apply({'B': 'yes'}); // malformed -> compile-time
      expect(registry.boolean('B', true), isTrue);

      registry.apply({'B': ''}); // empty -> compile-time
      expect(registry.boolean('B', true), isTrue);

      registry.apply({});
      expect(registry.boolean('B', false), isFalse);
    });

    test('integer: numeric honoured; malformed and empty fall back', () {
      registry.apply({'N': '42'});
      expect(registry.integer('N', 1), 42);

      registry.apply({'N': 'abc'});
      expect(registry.integer('N', 7), 7);

      registry.apply({'N': ''});
      expect(registry.integer('N', 7), 7);
    });

    test('has / clear', () {
      registry.apply({'A': 'x'});
      expect(registry.has('A'), isTrue);

      registry.clear();
      expect(registry.has('A'), isFalse);
    });
  });

  group('EnvironmentConfig overrides', () {
    tearDown(EnvironmentConfig.clearOverrides);

    test('APP_NAME reflects an override and falls back when empty/cleared', () {
      EnvironmentConfig.applyOverrides({EnvironmentConfig.APP_NAME__NAME: 'Custom'});
      expect(EnvironmentConfig.APP_NAME, 'Custom');

      EnvironmentConfig.applyOverrides({EnvironmentConfig.APP_NAME__NAME: ''});
      expect(EnvironmentConfig.APP_NAME, 'PortaPhone');

      EnvironmentConfig.clearOverrides();
      expect(EnvironmentConfig.APP_NAME, 'PortaPhone');
    });

    test('a non-positive polling-interval override falls back to the default', () {
      const name = EnvironmentConfig.USER_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME;

      EnvironmentConfig.applyOverrides({name: '0'});
      expect(EnvironmentConfig.USER_REPOSITORY_POLLING_INTERVAL_SECONDS, 900);

      EnvironmentConfig.applyOverrides({name: '-5'});
      expect(EnvironmentConfig.USER_REPOSITORY_POLLING_INTERVAL_SECONDS, 900);

      EnvironmentConfig.applyOverrides({name: '30'});
      expect(EnvironmentConfig.USER_REPOSITORY_POLLING_INTERVAL_SECONDS, 30);
    });

    test('CDR polling interval is configurable and keeps its positive default', () {
      const name = EnvironmentConfig.CDRS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME;

      EnvironmentConfig.applyOverrides({name: '25'});
      expect(EnvironmentConfig.CDRS_REPOSITORY_POLLING_INTERVAL_SECONDS, 25);

      EnvironmentConfig.applyOverrides({name: '0'});
      expect(EnvironmentConfig.CDRS_REPOSITORY_POLLING_INTERVAL_SECONDS, 300);
    });

    group('call history walk', () {
      test('the slice widths are configurable in hours and reject a non-positive value', () {
        const firstName = EnvironmentConfig.CDRS_HISTORY_FIRST_WINDOW_HOURS__NAME;
        const maxName = EnvironmentConfig.CDRS_HISTORY_MAX_WINDOW_HOURS__NAME;

        EnvironmentConfig.applyOverrides({firstName: '48', maxName: '720'});
        expect(EnvironmentConfig.CDRS_HISTORY_FIRST_WINDOW_HOURS, 48);
        expect(EnvironmentConfig.CDRS_HISTORY_MAX_WINDOW_HOURS, 720);

        EnvironmentConfig.applyOverrides({firstName: '0', maxName: '-1'});
        expect(EnvironmentConfig.CDRS_HISTORY_FIRST_WINDOW_HOURS, 24 * 7);
        expect(EnvironmentConfig.CDRS_HISTORY_MAX_WINDOW_HOURS, 24 * 90);
      });

      test('the horizon takes zero, because zero is how the walk is switched off', () {
        const name = EnvironmentConfig.CDRS_HISTORY_HORIZON_DAYS__NAME;

        EnvironmentConfig.applyOverrides({name: '30'});
        expect(EnvironmentConfig.CDRS_HISTORY_HORIZON_DAYS, 30);

        EnvironmentConfig.applyOverrides({name: '0'});
        expect(EnvironmentConfig.CDRS_HISTORY_HORIZON_DAYS, 0);

        EnvironmentConfig.applyOverrides({name: '-5'});
        expect(EnvironmentConfig.CDRS_HISTORY_HORIZON_DAYS, 365);
      });
    });

    group('external contacts polling interval by presence mode', () {
      const offName = EnvironmentConfig.EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME;
      const onName = EnvironmentConfig.EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS__NAME;
      // Run this group with --dart-define=<name>=0 and =-1 as well: a non-positive
      // build value must clamp to the code default, never reach the scheduler as
      // a zero delay.
      const offConfigured = int.fromEnvironment(offName, defaultValue: 300);
      const onConfigured = int.fromEnvironment(onName, defaultValue: 1800);
      final offFallback = offConfigured > 0 ? offConfigured : 300;
      final onFallback = onConfigured > 0 ? onConfigured : 1800;

      test('the two env names are the documented keys', () {
        expect(offName, 'WEBTRIT_APP_EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS');
        expect(onName, 'WEBTRIT_APP_EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS');
      });

      test('a non-positive build value clamps to the positive code default', () {
        // Under a plain run both are the defaults; under --dart-define=...=0 or
        // -1 the getters must still be positive and equal the fallback.
        expect(EnvironmentConfig.EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS, offFallback);
        expect(EnvironmentConfig.EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS, greaterThan(0));
        expect(EnvironmentConfig.EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS, onFallback);
        expect(EnvironmentConfig.EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS, greaterThan(0));
      });

      test('presence-off interval honours a positive override and rejects a non-positive one', () {
        EnvironmentConfig.applyOverrides({offName: '120'});
        expect(EnvironmentConfig.EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS, 120);

        EnvironmentConfig.applyOverrides({offName: '0'});
        expect(EnvironmentConfig.EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS, offFallback);
      });

      test('hybrid-presence interval honours a positive override and rejects a non-positive one', () {
        EnvironmentConfig.applyOverrides({onName: '3600'});
        expect(EnvironmentConfig.EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS, 3600);

        EnvironmentConfig.applyOverrides({onName: '-1'});
        expect(EnvironmentConfig.EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS, onFallback);
      });

      test('the selector picks the interval for the presence mode', () {
        expect(EnvironmentConfig.externalContactsPollingSeconds(hybridPresence: false), offFallback);
        expect(EnvironmentConfig.externalContactsPollingSeconds(hybridPresence: true), onFallback);

        EnvironmentConfig.applyOverrides({offName: '90', onName: '2400'});
        expect(EnvironmentConfig.externalContactsPollingSeconds(hybridPresence: false), 90);
        expect(EnvironmentConfig.externalContactsPollingSeconds(hybridPresence: true), 2400);
      });
    });

    group('polling backoff cap', () {
      const name = EnvironmentConfig.POLLING_MAX_BACKOFF_SECONDS__NAME;
      // Run this group with --dart-define=$name=<value> as well to exercise
      // build-time parsing, including malformed and non-positive values.
      const configured = int.fromEnvironment('WEBTRIT_APP_POLLING_MAX_BACKOFF_SECONDS', defaultValue: 900);
      const fallback = configured > 0 ? configured : 900;

      test('uses the positive build value or the 900-second default', () {
        expect(name, 'WEBTRIT_APP_POLLING_MAX_BACKOFF_SECONDS');
        expect(EnvironmentConfig.POLLING_MAX_BACKOFF_SECONDS, fallback);
      });

      test('positive runtime values win and clearing restores the build value', () {
        for (final seconds in [1, 300, 1800]) {
          EnvironmentConfig.applyOverrides({name: '$seconds'});
          expect(EnvironmentConfig.POLLING_MAX_BACKOFF_SECONDS, seconds);
        }

        EnvironmentConfig.clearOverrides();
        expect(EnvironmentConfig.POLLING_MAX_BACKOFF_SECONDS, fallback);
      });

      for (final invalid in ['', 'abc', '1.5', '0', '-5']) {
        test('invalid runtime value "$invalid" falls back to the validated build value', () {
          EnvironmentConfig.applyOverrides({name: invalid});
          expect(EnvironmentConfig.POLLING_MAX_BACKOFF_SECONDS, fallback);
        });
      }
    });

    group('polling reachability ttl', () {
      const name = EnvironmentConfig.POLLING_REACHABILITY_TTL_SECONDS__NAME;
      const configured = int.fromEnvironment('WEBTRIT_APP_POLLING_REACHABILITY_TTL_SECONDS', defaultValue: 30);
      final fallback = configured > 0 ? configured : 30;

      test('uses the positive build value or the 30-second default', () {
        expect(name, 'WEBTRIT_APP_POLLING_REACHABILITY_TTL_SECONDS');
        expect(EnvironmentConfig.POLLING_REACHABILITY_TTL_SECONDS, fallback);
      });

      test('a positive runtime value wins and a non-positive one falls back', () {
        EnvironmentConfig.applyOverrides({name: '5'});
        expect(EnvironmentConfig.POLLING_REACHABILITY_TTL_SECONDS, 5);
        EnvironmentConfig.applyOverrides({name: '0'});
        expect(EnvironmentConfig.POLLING_REACHABILITY_TTL_SECONDS, fallback);
      });
    });

    group('polling jitter percent', () {
      const name = EnvironmentConfig.POLLING_JITTER_PERCENT__NAME;
      const configured = int.fromEnvironment('WEBTRIT_APP_POLLING_JITTER_PERCENT', defaultValue: 10);
      final fallback = configured >= 0 && configured <= 100 ? configured : 10;

      test('uses the in-range build value or the 10 percent default', () {
        expect(name, 'WEBTRIT_APP_POLLING_JITTER_PERCENT');
        expect(EnvironmentConfig.POLLING_JITTER_PERCENT, fallback);
      });

      test('runtime values include zero to disable jitter', () {
        for (final percent in [0, 5, 100]) {
          EnvironmentConfig.applyOverrides({name: '$percent'});
          expect(EnvironmentConfig.POLLING_JITTER_PERCENT, percent);
        }
      });

      for (final invalid in ['', 'abc', '1.5', '-1', '101']) {
        test('invalid runtime value "$invalid" uses the validated build value', () {
          EnvironmentConfig.applyOverrides({name: invalid});
          expect(EnvironmentConfig.POLLING_JITTER_PERCENT, fallback);
        });
      }
    });

    group('post-call refresh delay', () {
      const name = EnvironmentConfig.POST_CALL_REFRESH_DELAY_SECONDS__NAME;
      const configured = int.fromEnvironment('WEBTRIT_APP_POST_CALL_REFRESH_DELAY_SECONDS', defaultValue: 1);
      final fallback = configured > 0 ? configured : 1;

      test('uses the positive build value or the 1-second default', () {
        expect(name, 'WEBTRIT_APP_POST_CALL_REFRESH_DELAY_SECONDS');
        expect(EnvironmentConfig.POST_CALL_REFRESH_DELAY_SECONDS, fallback);
      });

      test('a positive runtime value wins and a non-positive one falls back', () {
        EnvironmentConfig.applyOverrides({name: '3'});
        expect(EnvironmentConfig.POST_CALL_REFRESH_DELAY_SECONDS, 3);
        EnvironmentConfig.applyOverrides({name: '-2'});
        expect(EnvironmentConfig.POST_CALL_REFRESH_DELAY_SECONDS, fallback);
      });
    });

    group('system notifications polling interval', () {
      const name = EnvironmentConfig.SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS__NAME;
      const configured = int.fromEnvironment(
        'WEBTRIT_APP_SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS',
        defaultValue: 10,
      );
      final fallback = configured > 0 ? configured : 10;

      test('uses the positive build value or the 10-second default', () {
        expect(name, 'WEBTRIT_APP_SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS');
        expect(EnvironmentConfig.SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS, fallback);
      });

      test('a positive runtime value wins and a non-positive one falls back', () {
        EnvironmentConfig.applyOverrides({name: '60'});
        expect(EnvironmentConfig.SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS, 60);
        EnvironmentConfig.applyOverrides({name: '0'});
        expect(EnvironmentConfig.SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS, fallback);
      });
    });

    group('system notifications outbox polling interval', () {
      const name = EnvironmentConfig.SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS__NAME;
      const configured = int.fromEnvironment(
        'WEBTRIT_APP_SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS',
        defaultValue: 300,
      );
      final fallback = configured > 0 ? configured : 300;

      test('uses the positive build value or the 300-second default', () {
        expect(name, 'WEBTRIT_APP_SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS');
        expect(EnvironmentConfig.SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS, fallback);
      });

      test('a positive runtime value wins and a non-positive one falls back', () {
        EnvironmentConfig.applyOverrides({name: '60'});
        expect(EnvironmentConfig.SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS, 60);
        EnvironmentConfig.applyOverrides({name: '-1'});
        expect(EnvironmentConfig.SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS, fallback);
      });
    });

    group('leading refresh min-age cap', () {
      const name = EnvironmentConfig.POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS__NAME;
      const configured = int.fromEnvironment(
        'WEBTRIT_APP_POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS',
        defaultValue: 30,
      );
      const fallback = configured >= 0 ? configured : 30;

      test('uses a non-negative build value or the 30-second default', () {
        expect(name, 'WEBTRIT_APP_POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS');
        expect(EnvironmentConfig.POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS, fallback);
      });

      test('runtime values include zero to disable the gate', () {
        for (final seconds in [0, 5, 60]) {
          EnvironmentConfig.applyOverrides({name: '$seconds'});
          expect(EnvironmentConfig.POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS, seconds);
        }
        EnvironmentConfig.clearOverrides();
        expect(EnvironmentConfig.POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS, fallback);
      });

      for (final invalid in ['', 'abc', '1.5', '-5']) {
        test('invalid runtime value "$invalid" uses the validated build value', () {
          EnvironmentConfig.applyOverrides({name: invalid});
          expect(EnvironmentConfig.POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS, fallback);
        });
      }
    });

    test('APP_LINK_DOMAIN is trimmed, so it matches the host the build put in the manifest', () {
      const name = EnvironmentConfig.APP_LINK_DOMAIN__NAME;

      EnvironmentConfig.applyOverrides({name: '  app.example.com  '});
      expect(EnvironmentConfig.APP_LINK_DOMAIN, 'app.example.com');

      // Whitespace only leaves deep links off here too, matching a build that declares no filter.
      EnvironmentConfig.applyOverrides({name: '   '});
      expect(EnvironmentConfig.APP_LINK_DOMAIN, isEmpty);
    });
  });
}
