import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

part 'recents_bloc.freezed.dart';

part 'recents_event.dart';

part 'recents_state.dart';

final _logger = Logger('RecentsBloc');

class RecentsBloc extends Bloc<RecentsEvent, RecentsState> {
  RecentsBloc({
    required this.recentsRepository,
    required this.activeRecentsVisibilityFilterRepository,
    required this.dateFormat,
  }) : super(RecentsState(filter: activeRecentsVisibilityFilterRepository.getActiveRecentsVisibilityFilter())) {
    on<RecentsStarted>(_onStarted, transformer: restartable());
    on<RecentsFiltered>(_onFiltered);
    on<RecentsDeleted>(_onDeleted);
    on<RecentsCleared>(_onCleared);
  }

  final RecentsRepository recentsRepository;
  final ActiveRecentsVisibilityFilterRepository activeRecentsVisibilityFilterRepository;
  final DateFormat dateFormat;

  Future<void> _onStarted(RecentsStarted event, Emitter<RecentsState> emit) async {
    await emit.forEach(
      recentsRepository.watchRecents(),
      onData: (List<Recent> recents) => state.copyWith(recents: recents),
    );
  }

  Future<void> _onDeleted(RecentsDeleted event, Emitter<RecentsState> emit) async {
    await recentsRepository.deleteByCallId(event.recent.callLogEntry.id);
  }

  // The list itself follows the database it watches; the status is only for
  // the screen to say how the clear went.
  Future<void> _onCleared(RecentsCleared event, Emitter<RecentsState> emit) async {
    if (state.clearStatus == RecentsClearStatus.clearing) return;
    emit(state.copyWith(clearStatus: RecentsClearStatus.clearing));
    try {
      await recentsRepository.deleteAll();
    } catch (e, s) {
      _logger.warning('Clearing the call log failed', e, s);
      emit(state.copyWith(clearStatus: RecentsClearStatus.failed));
      return;
    }
    emit(state.copyWith(clearStatus: RecentsClearStatus.cleared));
  }

  Future<void> _onFiltered(RecentsFiltered event, Emitter<RecentsState> emit) async {
    await activeRecentsVisibilityFilterRepository.setActiveRecentsVisibilityFilter(event.filter);

    emit(state.copyWith(filter: event.filter));
  }
}
