import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../../../contacts.dart';

part 'contacts_local_tab_event.dart';

part 'contacts_local_tab_state.dart';

class ContactsLocalTabBloc extends Bloc<ContactsLocalTabEvent, ContactsLocalTabState> {
  ContactsLocalTabBloc({
    required this.contactsRepository,
    required this.contactsSearchBloc,
    required this.localContactsSyncCubit,
  }) : super(const ContactsLocalTabState()) {
    on<ContactsLocalTabStarted>(_onStarted, transformer: restartable());
  }

  final ContactsRepository contactsRepository;
  final ContactsBloc contactsSearchBloc;
  final LocalContactsSyncCubit localContactsSyncCubit;

  /// Completes after device contacts are persisted, rejected, failed or cancelled.
  Future<void> refresh() => localContactsSyncCubit.refresh();

  Future<void> _onStarted(ContactsLocalTabStarted event, Emitter<ContactsLocalTabState> emit) async {
    final watchContactsForEachFuture = emit.forEach(
      contactsRepository.watchContacts(event.search, ContactSourceType.local),
      onData: (List<Contact> contacts) => state.copyWith(
        status: _mapLocalContactsSyncStateToStatus(localContactsSyncCubit.state),
        contacts: contacts,
        searching: event.search.isNotEmpty,
      ),
    );

    final contactsSearchSateOnEachFuture = emit.onEach(
      contactsSearchBloc.stream,
      onData: (state) {
        add(ContactsLocalTabStarted(search: state.search));
      },
    );

    final localContactsSyncStateForEachFuture = emit.forEach(
      localContactsSyncCubit.stream,
      onData: (LocalContactsSyncState localContactsSyncState) =>
          state.copyWith(status: _mapLocalContactsSyncStateToStatus(localContactsSyncState)),
    );

    await Future.wait([
      watchContactsForEachFuture,
      contactsSearchSateOnEachFuture,
      localContactsSyncStateForEachFuture,
    ]);
  }

  ContactsLocalTabStatus _mapLocalContactsSyncStateToStatus(LocalContactsSyncState localContactsSyncState) {
    if (localContactsSyncState is LocalContactsSyncRefreshInProgress) {
      return ContactsLocalTabStatus.inProgress;
    } else if (localContactsSyncState is LocalContactsSyncSuccess) {
      return ContactsLocalTabStatus.success;
    } else if (localContactsSyncState is LocalContactsSyncPermissionFailure) {
      return ContactsLocalTabStatus.permissionFailure;
    } else if (localContactsSyncState is ContactsAgreementMissingException) {
      return ContactsLocalTabStatus.contactsAgreementFailure;
    } else {
      return ContactsLocalTabStatus.failure;
    }
  }
}
