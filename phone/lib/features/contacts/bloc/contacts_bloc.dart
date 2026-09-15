import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/active_contacts_list/active_contacts_list_repository.dart';
import 'package:webtrit_phone/utils/utils.dart';

part 'contacts_bloc.freezed.dart';

part 'contacts_event.dart';

part 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  ContactsBloc({required this.activeContactsListRepository})
    : super(
        ContactsState(
          sourceType: activeContactsListRepository.getSourceType(),
          favorites: activeContactsListRepository.getFavoritesPicked(),
        ),
      ) {
    on<ContactsSourceTypeChanged>(_onSourceTypeChanged, transformer: debounce());
    // Not debounced: this one is a tap on a menu entry, not typing. A quarter
    // second of the old list under a chooser that already closed reads as the
    // tap not working, and leaving the section inside that window would drop
    // the pick before it was ever written down.
    on<ContactsListSelectionChanged>(_onListSelectionChanged, transformer: sequential());
    on<ContactsSearchChanged>(_onSearchChanged, transformer: debounce());
    on<ContactsSearchSubmitted>(_onSearchSubmitted, transformer: sequential());
  }

  final ActiveContactsListRepository activeContactsListRepository;

  /// The arrangement that keeps favourites elsewhere: an address book is all
  /// this event ever states, so it leaves the favourites pick alone.
  Future<void> _onSourceTypeChanged(ContactsSourceTypeChanged event, Emitter<ContactsState> emit) async {
    await activeContactsListRepository.setSourceType(event.sourceType);

    emit(state.copyWith(sourceType: event.sourceType));
  }

  /// The chooser offers one list at a time, so its answer states both things
  /// at once: which list is shown, and - when it names an address book - the
  /// book to come back to once the favourites are left.
  ///
  /// Shown first and written down after: the screen draws what was picked on
  /// the next frame rather than after a round trip to the device's storage.
  Future<void> _onListSelectionChanged(ContactsListSelectionChanged event, Emitter<ContactsState> emit) async {
    final selection = event.selection;
    final favorites = selection is ContactsFavoritesSelection;
    final sourceType = selection is ContactsSourceSelection ? selection.sourceType : state.sourceType;

    emit(state.copyWith(sourceType: sourceType, favorites: favorites));

    await activeContactsListRepository.setFavoritesPicked(favorites);
    if (!favorites) await activeContactsListRepository.setSourceType(sourceType);
  }

  Future<void> _onSearchChanged(ContactsSearchChanged event, Emitter<ContactsState> emit) async {
    emit(state.copyWith(search: event.search));
  }

  Future<void> _onSearchSubmitted(ContactsSearchSubmitted event, Emitter<ContactsState> emit) async {
    emit(state.copyWith(search: event.search));
  }
}
