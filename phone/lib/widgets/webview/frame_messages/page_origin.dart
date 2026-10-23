/// The origin a page at [uri] runs in, as a browser writes it in a message.
///
/// An http or https page runs in its scheme, host and port. Anything else - an
/// inline `data:` page, `about:blank` - has no origin of its own and is
/// written `null`.
String pageOrigin(Uri uri) => uri.isScheme('http') || uri.isScheme('https') ? uri.origin : 'null';
