import 'dart:typed_data';

/// What a chat bubble shows under a link: the page's title, description and image.
final class LinkPreview {
  const LinkPreview({this.title, this.description, this.image});

  final String? title;
  final String? description;

  /// The image, already downloaded - encoded bytes (PNG, JPEG, GIF, WebP...), ready for
  /// `Image.memory`.
  ///
  /// Bytes rather than an address: the fetcher checks where every request goes, and an address
  /// handed to `Image.network` would be fetched again, with redirects nobody checks.
  final Uint8List? image;

  @override
  bool operator ==(Object other) =>
      other is LinkPreview &&
      other.title == title &&
      other.description == description &&
      _sameBytes(other.image, image);

  @override
  int get hashCode => Object.hash(title, description, image?.length);

  @override
  String toString() =>
      'LinkPreview(title: $title, description: $description, image: ${image == null ? null : '${image!.length} bytes'})';

  static bool _sameBytes(Uint8List? a, Uint8List? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
