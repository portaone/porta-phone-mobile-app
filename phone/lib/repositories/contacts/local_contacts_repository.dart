import 'dart:async';

import 'package:webtrit_phone/models/models.dart';

export 'local_contacts_repository_io.dart' if (dart.library.html) 'local_contacts_repository_html.dart';

abstract class ILocalContactsRepository {
  Future<bool> requestPermission();

  /// Reports invalidations; the sync owner decides when to read again.
  Stream<void> watchChanges();

  /// Reads the current device snapshot without publishing it on another stream.
  Future<List<LocalContact>> fetchContacts();
}
