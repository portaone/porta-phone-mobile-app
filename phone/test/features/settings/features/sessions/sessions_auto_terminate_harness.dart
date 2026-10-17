import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:webtrit_phone/features/settings/features/sessions/sessions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../../../../helpers/helpers.dart';

/// A core that answers the session list with [autoTerminate] and holds what a
/// PUT sets, or answers a PUT with [refusal] / [failure] when one is set.
class FakeSessionsRepository implements SessionsRepository {
  FakeSessionsRepository(this.autoTerminate, {this.sessions = const [ActiveSession(id: 'a', current: true)]});

  SessionAutoTerminate? autoTerminate;

  final List<ActiveSession> sessions;

  final puts = <int?>[];

  SessionAutoTerminateRefusal? refusal;

  Object? failure;

  Object? revokeFailure;

  /// When set, a PUT waits for it before answering.
  Completer<void>? gate;

  @override
  Future<SessionList> getSessions() async {
    return SessionList(sessions: sessions, autoTerminate: autoTerminate);
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    if (revokeFailure case final failure?) throw failure;
  }

  @override
  Future<SessionAutoTerminate> setInactivityTimeout(int? days) async {
    puts.add(days);
    await gate?.future;
    if (refusal case final refusal?) throw SessionAutoTerminateRefusedException(refusal);
    if (failure case final failure?) throw failure;
    final max = autoTerminate?.installationMaxDays;
    return autoTerminate = SessionAutoTerminate(inactivityTimeoutDays: days ?? max, installationMaxDays: max);
  }
}

class SessionsAutoTerminateHarness {
  SessionsAutoTerminateHarness(
    SessionAutoTerminate? autoTerminate, {
    this.selectable = true,
    List<ActiveSession> sessions = const [ActiveSession(id: 'a', current: true)],
  }) : repository = FakeSessionsRepository(autoTerminate, sessions: sessions);

  final FakeSessionsRepository repository;

  final bool selectable;

  late final SessionsCubit cubit = SessionsCubit(repository);

  final autoTerminateSnackBar = SessionAutoTerminateSnackBar();

  Future<void> pump(WidgetTester tester) async {
    await cubit.fetch();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: withRootStackRouter(
          BlocProvider.value(
            value: cubit,
            child: SessionsScreen(
              dateFormat: DateFormat('yyyy-MM-dd HH:mm'),
              autoTerminateSelectable: selectable,
              autoTerminateSnackBar: autoTerminateSnackBar,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(cubit.close);
  }
}
