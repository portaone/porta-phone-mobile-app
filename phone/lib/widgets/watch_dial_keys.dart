import 'package:adaptive_kit/adaptive_kit.dart';

import 'package:webtrit_phone/models/models.dart';

/// The dial keys as `WatchKeyGrid` draws them; a watch shows no captions.
final List<WatchKey> watchDialKeys = [
  for (final key in KeypadKey.numbers) WatchKey(key.text, alternate: key.alternate),
];
