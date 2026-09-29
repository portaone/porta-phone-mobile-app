/// What a chat bubble shows under a link: the page's title, description and image.
final class LinkPreview {
  const LinkPreview({this.title, this.description, this.imageUrl});

  final String? title;
  final String? description;

  /// An absolute http(s) URL of the image, or of the link itself when the link is an image.
  final String? imageUrl;

  @override
  bool operator ==(Object other) =>
      other is LinkPreview && other.title == title && other.description == description && other.imageUrl == imageUrl;

  @override
  int get hashCode => Object.hash(title, description, imageUrl);

  @override
  String toString() => 'LinkPreview(title: $title, description: $description, imageUrl: $imageUrl)';
}
