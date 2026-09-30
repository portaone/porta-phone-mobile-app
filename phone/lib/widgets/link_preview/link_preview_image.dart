import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

/// The image of a link preview, from the bytes the preview fetcher downloaded.
///
/// Decoded no wider than a phone screen: a few compressed kilobytes can be a huge bitmap, and a
/// smaller image is not scaled up.
class LinkPreviewImage extends StatelessWidget {
  const LinkPreviewImage(this.bytes, {super.key});

  final Uint8List bytes;

  static const decodeWidth = 1080;

  @override
  Widget build(BuildContext context) => Image.memory(bytes, cacheWidth: decodeWidth);
}
