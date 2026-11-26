import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';

import 'draggable_thumbnail.dart';

/// Where the floating thumbnail is on the screen, in global coordinates, while one is shown;
/// `null` while none is. What sits under it - the three dots of the room's tiles - steps aside
/// rather than be covered, while the window itself keeps where it was put.
final ValueNotifier<Rect?> floatingThumbnailArea = ValueNotifier<Rect?>(null);

/// Manages the lifecycle and state of a draggable thumbnail overlay.
///
/// This class handles inserting the [OverlayEntry], updating its content,
/// and preserving the thumbnail's position across different show/hide sessions.
class ThumbnailOverlayManager {
  ThumbnailOverlayManager({required this.stickyPadding});

  /// The padding used to constrain the draggable area within the overlay.
  final EdgeInsets stickyPadding;

  /// Last known position of the draggable thumbnail; preserved between show/hide.
  Offset? _lastOffset;

  /// Currently inserted overlay entry for the thumbnail, or null when hidden.
  OverlayEntry? _entry;

  /// Drives the content of the active overlay, allowing updates without
  /// removing and re-inserting the [OverlayEntry].
  final ValueNotifier<Widget?> _contentNotifier = ValueNotifier<Widget?>(null);

  /// Whether the overlay entry is currently inserted in the view hierarchy.
  bool get isShowing => _entry != null;

  /// Displays the provided [child] in an overlay.
  ///
  /// If the overlay is already active, this updates the content without
  /// re-inserting the entry, preventing flickering.
  void show(BuildContext context, {required Widget child}) {
    _contentNotifier.value = child;

    // If the entry already exists, ValueListenableBuilder inside it
    // will handle the UI update automatically.
    if (_entry != null) {
      return;
    }

    final entry = OverlayEntry(
      builder: (context) => _ThumbnailOverlayContent(
        contentNotifier: _contentNotifier,
        stickyPadding: stickyPadding,
        initialOffset: _lastOffset,
        onOffsetUpdate: _updateOffset,
      ),
    );

    _entry = entry;
    Overlay.of(context).insert(entry);
  }

  /// Removes the overlay entry from the view hierarchy.
  ///
  /// The last known position of the thumbnail is preserved for the next usage.
  void hide() {
    final entry = _entry;
    if (entry != null) {
      entry.remove();
      _entry = null;
      _contentNotifier.value = null;
      floatingThumbnailArea.value = null;
    }
  }

  /// Hides the overlay and releases resources used by the content notifier.
  void dispose() {
    hide();
    _contentNotifier.dispose();
  }

  void _updateOffset(Offset offset) => _lastOffset = offset;
}

class _ThumbnailOverlayContent extends StatelessWidget {
  const _ThumbnailOverlayContent({
    required this.contentNotifier,
    required this.stickyPadding,
    required this.onOffsetUpdate,
    this.initialOffset,
  });

  final ValueNotifier<Widget?> contentNotifier;
  final EdgeInsets stickyPadding;
  final ValueChanged<Offset> onOffsetUpdate;
  final Offset? initialOffset;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Widget?>(
      valueListenable: contentNotifier,
      builder: (BuildContext context, Widget? content, Widget? _) {
        if (content == null) {
          return const SizedBox.shrink();
        }

        return DraggableThumbnail(
          stickyPadding: stickyPadding,
          initialOffset: initialOffset,
          onOffsetUpdate: onOffsetUpdate,
          child: _AreaReporter(child: content),
        );
      },
    );
  }
}

/// Tells [floatingThumbnailArea] where its child is painted, after the frame that moved it.
class _AreaReporter extends SingleChildRenderObjectWidget {
  const _AreaReporter({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAreaReporter();
}

class _RenderAreaReporter extends RenderProxyBox {
  Rect? _told;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final area = localToGlobal(Offset.zero) & size;
    if (area == _told) return;
    _told = area;
    // Not while painting: the listeners rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached && _told == area) floatingThumbnailArea.value = area;
    });
  }

  @override
  void detach() {
    final told = _told;
    _told = null;
    super.detach();
    if (told != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (floatingThumbnailArea.value == told) floatingThumbnailArea.value = null;
      });
    }
  }
}
