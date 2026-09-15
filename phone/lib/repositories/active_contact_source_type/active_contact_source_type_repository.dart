import 'package:webtrit_phone/data/app_preferences.dart';
import 'package:webtrit_phone/models/contact_source_type.dart';

/// What the contacts section was left showing: the address book, and - where
/// the section offers them in the same chooser - whether the favourites entry
/// is the one picked.
///
/// Two values rather than one, because they answer different questions and
/// both are needed at once: leaving the favourites has to land on the book
/// that was left behind rather than on a default.
abstract interface class ActiveContactSourceTypeRepository {
  ContactSourceType getActiveContactSourceType({ContactSourceType defaultValue});

  Future<void> setActiveContactSourceType(ContactSourceType value);

  /// Whether the favourites entry of the chooser was the one picked.
  bool getFavoritesPicked({bool defaultValue});

  Future<void> setFavoritesPicked(bool value);

  Future<void> clear();
}

class ActiveContactSourceTypeRepositoryPrefsImpl implements ActiveContactSourceTypeRepository {
  ActiveContactSourceTypeRepositoryPrefsImpl(this._appPreferences);

  final AppPreferences _appPreferences;
  // Both strings are what already sits on people's devices, not names to be
  // tidied: the older one says "source type" and the newer one says
  // "contacts" because they shipped years apart. Renaming either reads as a
  // rename and behaves as a wipe - everyone would quietly lose what they had
  // chosen, because nothing would look under the old name again.
  final _prefsKey = 'active-contact-source-type';
  final _favoritesPrefsKey = 'active-contacts-favorites-picked';

  @override
  ContactSourceType getActiveContactSourceType({ContactSourceType defaultValue = ContactSourceType.external}) {
    final activeContactSourceTypeString = _appPreferences.getString(_prefsKey);
    if (activeContactSourceTypeString != null) {
      try {
        return ContactSourceType.values.byName(activeContactSourceTypeString);
      } catch (_) {
        return defaultValue;
      }
    } else {
      return defaultValue;
    }
  }

  @override
  Future<void> setActiveContactSourceType(ContactSourceType value) => _appPreferences.setString(_prefsKey, value.name);

  @override
  bool getFavoritesPicked({bool defaultValue = false}) => _appPreferences.getBool(_favoritesPrefsKey) ?? defaultValue;

  @override
  Future<void> setFavoritesPicked(bool value) => _appPreferences.setBool(_favoritesPrefsKey, value);

  /// Both keys go, and neither failing may keep the other: teardown wraps
  /// this in a suppressor precisely so one failure costs only itself, and
  /// awaiting them in turn would smuggle that abort back in a level down -
  /// the next account would open on the previous one's favourites.
  @override
  Future<void> clear() => Future.wait([_appPreferences.remove(_prefsKey), _appPreferences.remove(_favoritesPrefsKey)]);
}
