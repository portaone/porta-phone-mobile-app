import 'package:flutter/foundation.dart';

import 'package:link_preview/link_preview.dart';

export 'package:link_preview/link_preview.dart' show LinkPreview;

/// Fetches the preview of [url] on a background isolate, within the bounds `LinkPreviewFetcher` sets.
///
/// Parsing even a capped HTML page is too much work for the UI thread, which is why the fetch
/// leaves it.
Future<LinkPreview?> fetchLinkPreview(Uri url) => compute(_fetch, url);

Future<LinkPreview?> _fetch(Uri url) => LinkPreviewFetcher().fetch(url);
