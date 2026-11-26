// The conference in full screen: the participants take the screen and the
// controls that act on the room sit under them. Whoever sends video is a big
// tile; whoever does not is a thumbnail - the avatar on a tile with the name
// under it - in a row under the big tiles, or across the screen when nobody
// sends video. The big tiles take as many columns as shows the most of their
// pictures (conference_tile_grid.dart). While someone shares a screen, it takes
// the main place with a line saying who shares, and every participant is a
// thumbnail in a row under it. The host is no tile: what goes out from him -
// the room's camera, or the tile of his share with its Stop - is the call
// screen's one floating window (CallShell), over this page as over the
// default screen, where he left it. Whoever the room shows as speaking has a
// border in the theme's accent round his tile, thumbnail or shared screen
// (speaking_frame.dart); the layout does not follow it.
//
// Two pages of the call screen's routes on a phone
// (view/conference_full_screen_pages.dart): the tiles, opened by the control
// of the conference panel's header or a tap on a participant's row, and one
// participant, opened from
// the menu of his tile - the same toolbar and control bar, with [callId]
// naming the participant. A tap on a tile, or on the three dots at its top
// right corner, opens the participant's menu: show him large, mute him for
// everyone, end his call. CallScreenHandset closes the
// pages when they stop applying; back - the arrow or the system Back - is the
// router's. The page on top says who left, over the video. What each control
// does arrives in CallScreenParams, as for the default screen; the colours are
// the call screen's style (CallScreenStyles) and the theme's scheme.
import 'package:material_ui/material_ui.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../extensions/extensions.dart';
import '../models/models.dart';
import '../view/call_screen_styles.dart';
import 'call_action_button.dart';
import 'call_controls.dart';
import 'call_row_frame.dart';
import 'conference_participant_camera.dart';
import 'conference_tile_grid.dart';
import 'popup_menu.dart';
import 'screen_share_mark.dart';
import 'speaking_frame.dart';
import 'thumbnail_overlay_manager.dart';

class ConferenceFullScreen extends StatefulWidget {
  const ConferenceFullScreen({
    super.key,
    required this.params,
    required this.onBack,
    required this.onParticipantOpened,
    required this.onKeypad,
    this.callId,
    this.covered = false,
  });

  final CallScreenParams params;

  /// Whether a participant's page lies over these tiles: they are not seen,
  /// and hold no cameras - each would keep a renderer decoding for nothing.
  final bool covered;

  /// The participant this page is about, by call id; `null` for the tiles.
  final String? callId;

  /// Back: to the tiles from a participant, to the default screen from them.
  final VoidCallback onBack;

  /// Show large, from the menu of a participant's tile.
  final ValueChanged<String> onParticipantOpened;

  /// The keypad of More: shown on the default screen.
  final VoidCallback onKeypad;

  @override
  State<ConferenceFullScreen> createState() => _ConferenceFullScreenState();
}

class _ConferenceFullScreenState extends State<ConferenceFullScreen> {
  /// The short notice of who left, shown over the video for a while.
  String? _notice;
  int _noticeSerial = 0;

  static const _noticeDuration = Duration(seconds: 3);

  /// A tile keeps its picture when a participant before it leaves and it
  /// moves to another place: its renderer goes with it rather than being made
  /// again, which would show the avatar until the next frame.
  final _tileKeys = <String, GlobalKey>{};

  GlobalKey _tileKey(String callId) => _tileKeys.putIfAbsent(callId, GlobalKey.new);

  /// The proportions of each participant's picture, by call id, as its renderer last told them:
  /// the grid lays the big tiles out by them.
  final _aspects = <String, double>{};

  void _aspectChanged(String callId, double aspect) {
    if (!mounted || _aspects[callId] == aspect) return;
    setState(() => _aspects[callId] = aspect);
  }

  /// The proportions the grid takes for [participant]'s picture: his camera's once known; `null`
  /// - an upright phone camera's - before its first frame and for whoever sends no video.
  double? _aspectOf(_OpenParticipant participant) => participant.sendsVideo ? _aspects[participant.callId] : null;

  /// The participant this page was last built for, kept for the moment the
  /// page leaves after him: it shows him to the end of its transition rather
  /// than the tiles.
  _OpenParticipant? _lastOpen;

  @override
  void didUpdateWidget(covariant ConferenceFullScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.params.conference.legs.keys.toSet();
    final now = widget.params.conference.legs.keys.toSet();
    final left = before.difference(now);
    _tileKeys.removeWhere((callId, _) => !now.contains(callId));
    _aspects.removeWhere((callId, _) => !now.contains(callId));
    if (left.isEmpty || !_onTop(left)) return;
    final names = [
      for (final callId in left)
        oldWidget.params.activeCalls.firstWhereOrNull((call) => call.callId == callId)?.nameOrNumber ?? callId,
    ];
    _showNotice(names.map((name) => context.l10n.call_ConferenceFullScreen_participantLeft(name)).join('\n'));
  }

  /// Whether this page is the one seen once [left] have gone: a participant's
  /// page unless it is his own, leaving with him; the tiles unless a page is
  /// over them.
  bool _onTop(Set<String> left) {
    final callId = widget.callId;
    return callId == null ? !widget.covered : !left.contains(callId);
  }

  void _showNotice(String text) {
    final serial = ++_noticeSerial;
    _notice = text;
    Future<void>.delayed(_noticeDuration, () {
      if (mounted && serial == _noticeSerial) setState(() => _notice = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = widget.params;
    final style = Theme.of(context).extension<CallScreenStyles>()?.primary;
    final infoStyle = style?.callInfo;
    final themeData = Theme.of(context);
    final colors = themeData.colorScheme;
    final foreground = infoStyle?.callStatus?.color ?? colors.onSurface;
    final textStyle = infoStyle?.callStatus ?? themeData.textTheme.bodyMedium;
    final look = _Look(foreground: foreground, scrim: colors.scrim, textStyle: textStyle);
    final conference = params.conference;
    final legs = conference.legs.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final covered = widget.covered;

    _OpenParticipant participantOf(int index, MapEntry<String, int> leg) => _OpenParticipant(
      index: index,
      callId: leg.key,
      call: params.activeCalls.firstWhereOrNull((call) => call.callId == leg.key),
      video: covered ? null : conference.videoOfLine(leg.value),
      sendsVideo: conference.videoOfLine(leg.value) != null,
      muted: conference.participantMuted(leg.key),
      ready: conference.isReady(leg.key),
      speaking: conference.speaks(leg.value),
    );

    Widget tileOf(_OpenParticipant participant, {required _TileShape shape}) => _ParticipantMenu(
      key: _tileKey(participant.callId),
      participant: participant,
      params: params,
      onOpened: shape == _TileShape.page ? null : () => widget.onParticipantOpened(participant.callId),
      look: look,
      radius: shape == _TileShape.thumbnail ? _Thumbnail.radius : _tileRadius,
      child: shape == _TileShape.thumbnail
          ? _Thumbnail(participant: participant, params: params, look: look)
          : _BigTile(
              participant: participant,
              params: params,
              look: look,
              page: shape == _TileShape.page,
              onAspectChanged: (aspect) => _aspectChanged(participant.callId, aspect),
            ),
    );

    final callId = widget.callId;
    final openIndex = callId == null ? -1 : legs.indexWhere((leg) => leg.key == callId);
    if (openIndex >= 0) _lastOpen = participantOf(openIndex, legs[openIndex]);
    // The participant left: the page leaves after him, showing him to the end.
    final open = callId == null ? null : (openIndex >= 0 ? _lastOpen : _lastOpen?.gone());
    final Widget body;
    final String title;
    if (open != null) {
      title = open.call?.nameOrNumber ?? open.callId;
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: _gap),
        child: SemanticId(
          identifier: conferenceParticipantPageId,
          child: tileOf(open, shape: _TileShape.page),
        ),
      );
    } else {
      // Everyone in the room, the host included.
      title = context.l10n.call_ConferenceFullScreen_title(legs.length + 1);
      final participants = [for (final (index, leg) in legs.indexed) participantOf(index, leg)];
      final screenFeed = covered ? null : conference.mainScreenFeed;
      final screen = conference.screens[screenFeed];
      if (screenFeed != null && screen != null) {
        // The far end of the host's line N is feed N + 2; a guest of the room has no call here.
        final presenter = legs.firstWhereOrNull((leg) => leg.value + 2 == screenFeed);
        final call = presenter == null
            ? null
            : params.activeCalls.firstWhereOrNull((call) => call.callId == presenter.key);
        // The share takes the presenter's one video line: as a thumbnail he would only be an avatar
        // repeating the screen and its label. His menu is on the screen instead.
        final presenting = presenter == null
            ? null
            : participants.firstWhereOrNull((participant) => participant.callId == presenter.key);
        final others = [
          for (final participant in participants)
            if (!identical(participant, presenting)) participant,
        ];
        body = _PresenterLayout(
          screen: screen,
          name: call?.nameOrNumber,
          look: look,
          presenterMenu: presenting == null
              ? null
              : (child) => _ParticipantMenu(
                  key: _tileKey(presenting.callId),
                  participant: presenting,
                  params: params,
                  look: look,
                  // The screen is the large picture already.
                  onOpened: null,
                  radius: _tileRadius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      // His name on the screen, as a big tile has it: no thumbnail says it any more.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _NameStrip(name: presenting.name, look: look),
                      ),
                      if (presenting.muted)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: _MutedBadge(index: presenting.index, look: look),
                        ),
                    ],
                  ),
                ),
          thumbnails: [for (final participant in others) tileOf(participant, shape: _TileShape.thumbnail)],
        );
      } else {
        // By who sends video, not by the picture held: covered tiles hold none and keep their places.
        final withVideo = participants.where((participant) => participant.sendsVideo).toList();
        final withoutVideo = participants.where((participant) => !participant.sendsVideo).toList();
        if (withVideo.isEmpty) {
          body = ConferenceTileGrid(
            gap: _gap,
            minRowHeight: _minRowHeight,
            tiles: [for (final participant in withoutVideo) tileOf(participant, shape: _TileShape.thumbnail)],
            aspects: List.filled(withoutVideo.length, null),
          );
        } else {
          body = Column(
            children: [
              Expanded(
                child: ConferenceTileGrid(
                  gap: _gap,
                  minRowHeight: _minRowHeight,
                  tiles: [for (final participant in withVideo) tileOf(participant, shape: _TileShape.big)],
                  aspects: [for (final participant in withVideo) _aspectOf(participant)],
                ),
              ),
              if (withoutVideo.isNotEmpty) ...[
                const SizedBox(height: _gap),
                SizedBox(
                  height: _Thumbnail.rowHeight,
                  child: _ThumbnailRow(
                    stretch: true,
                    thumbnails: [
                      for (final participant in withoutVideo) tileOf(participant, shape: _TileShape.thumbnail),
                    ],
                  ),
                ),
              ],
            ],
          );
        }
      }
    }

    final notice = _notice;
    // No safe area of its own: the call screen's layer already keeps the
    // controls clear of the system bars, as for the default screen.
    final page = Column(
      children: [
        // The call screen's own toolbar: back where it always is, the room
        // in the title, and everything under it for the video.
        AppBar(
          primary: false,
          automaticallyImplyLeading: false,
          backgroundColor: style?.appBar?.backgroundColor,
          foregroundColor: style?.appBar?.foregroundColor ?? foreground,
          leading: CallActionButton(
            label: MaterialLocalizations.of(context).backButtonTooltip,
            identifier: conferenceFullScreenBackId,
            onPressed: widget.onBack,
            style: TextButton.styleFrom(foregroundColor: foreground, shape: const CircleBorder()),
            child: const Icon(Icons.arrow_back),
          ),
          titleSpacing: 0,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: body),
              // Over the video, as a snackbar is: it takes no place of its own.
              if (notice != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: SemanticId(
                    identifier: conferenceFullScreenNoticeId,
                    child: Semantics(
                      liveRegion: true,
                      child: Material(
                        color: colors.inverseSurface,
                        elevation: 6,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text(
                            notice,
                            style: themeData.textTheme.bodyMedium?.copyWith(color: colors.onInverseSurface),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        _ControlBar(params: params, foreground: foreground, onKeypad: widget.onKeypad),
        const SizedBox(height: 12),
      ],
    );
    return page;
  }
}

const _gap = 8.0;

/// The lowest a row of tiles may get before the grid scrolls instead of
/// squeezing the pictures further.
const _minRowHeight = 160.0;
const _tileRadius = 16.0;

/// The full screen's colours and text: the screen's foreground, the theme's
/// scrim under what sits on a picture, the call screen's status text.
@immutable
class _Look {
  const _Look({required this.foreground, required this.scrim, required this.textStyle});

  final Color foreground;
  final Color scrim;
  final TextStyle? textStyle;

  /// The ground of a tile without a picture.
  Color get tileGround => foreground.withValues(alpha: 0.08);
}

enum _TileShape {
  /// A participant who sends video, in the big tiles.
  big,

  /// A participant without video, or anyone in the row under a shared screen.
  thumbnail,

  /// The participant's own page.
  page,
}

/// Thumbnails in one row: sharing the width when [stretch] and they fit, else
/// of [_Thumbnail.width] each, scrolling sideways past what fits.
class _ThumbnailRow extends StatelessWidget {
  const _ThumbnailRow({required this.thumbnails, this.stretch = false});

  final List<Widget> thumbnails;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - _gap * 2;
        final fits = thumbnails.length * _Thumbnail.width + _gap * (thumbnails.length - 1) <= width;
        if (stretch && fits) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gap),
            child: Row(
              spacing: _gap,
              children: [for (final thumbnail in thumbnails) Expanded(child: thumbnail)],
            ),
          );
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: _gap),
          itemCount: thumbnails.length,
          separatorBuilder: (_, _) => const SizedBox(width: _gap),
          itemBuilder: (context, index) => SizedBox(width: _Thumbnail.width, child: thumbnails[index]),
        );
      },
    );
  }
}

/// A shared screen in the main place, whole (contained, never cut), with who
/// shares it above, and every participant as a thumbnail in one row under it.
///
/// A phone sends its screen only when the screen changes: one that shows something still sends
/// nothing to a picture opened after its last change, and the place says who shares and that the
/// picture is on its way, rather than standing empty.
class _PresenterLayout extends StatelessWidget {
  const _PresenterLayout({
    required this.screen,
    required this.name,
    required this.look,
    required this.presenterMenu,
    required this.thumbnails,
  });

  final ParticipantCamera screen;

  /// Puts the presenter's menu on the screen - a tap there opens it - when the presenter is a
  /// participant here; `null` for one the room knows no call of.
  final Widget Function(Widget child)? presenterMenu;

  /// Who shares, when the room knows them as a call here.
  final String? name;
  final _Look look;
  final List<Widget> thumbnails;

  @override
  Widget build(BuildContext context) {
    final name = this.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (name != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, _gap),
            child: SemanticId(
              identifier: callScreenShareConferenceLabelId,
              child: Row(
                spacing: 8,
                children: [
                  ExcludeSemantics(child: Icon(Icons.screen_share_outlined, size: 18, color: look.foreground)),
                  Expanded(
                    child: Text(
                      context.l10n.call_ConferenceFullScreen_sharing(name),
                      maxLines: 2,
                      style: look.textStyle?.copyWith(color: look.foreground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gap),
            // The screen's own node around the presenter's control (conferenceTile<N>), which
            // carries his menu: a node of its own inside the control would take its id.
            child: SemanticId(
              identifier: callScreenShareConferenceScreenId,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_tileRadius),
                child: ColoredBox(
                  color: look.tileGround,
                  child: (presenterMenu ?? (child) => child)(
                    ParticipantVideo(
                      camera: screen,
                      placeholder: _ScreenWaiting(name: name, look: look),
                      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (thumbnails.isNotEmpty) ...[
          const SizedBox(height: _gap),
          SizedBox(
            height: _Thumbnail.rowHeight,
            child: _ThumbnailRow(thumbnails: thumbnails),
          ),
        ],
      ],
    );
  }
}

/// What the main place shows until the shared screen's first picture: who shares, and that the
/// screen is on its way.
class _ScreenWaiting extends StatelessWidget {
  const _ScreenWaiting({required this.name, required this.look});

  final String? name;
  final _Look look;

  @override
  Widget build(BuildContext context) {
    final name = this.name;
    final foreground = look.foreground;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Icon(Icons.screen_share_outlined, size: 40, color: foreground.withValues(alpha: 0.7)),
          if (name != null)
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: look.textStyle?.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          Text(
            context.l10n.call_ConferenceFullScreen_screenWaiting,
            textAlign: TextAlign.center,
            style: look.textStyle?.copyWith(color: foreground.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

/// One participant as a page of the room shows him: his leg, his call and his
/// camera, what the room says of his microphone.
@immutable
class _OpenParticipant {
  const _OpenParticipant({
    required this.index,
    required this.callId,
    required this.call,
    required this.video,
    required this.sendsVideo,
    required this.muted,
    required this.ready,
    required this.speaking,
  });

  final int index;
  final String callId;
  final ActiveCall? call;
  final ParticipantCamera? video;

  /// Whether the room sends his video, held here or not.
  final bool sendsVideo;
  final bool muted;
  final bool ready;

  /// Whether the room shows him as speaking.
  final bool speaking;

  String get name => call?.nameOrNumber ?? callId;

  /// The same participant once he has left: nothing of him can be acted on,
  /// and his camera is gone with him.
  _OpenParticipant gone() => _OpenParticipant(
    index: index,
    callId: callId,
    call: call,
    video: null,
    sendsVideo: false,
    muted: muted,
    ready: false,
    speaking: false,
  );
}

/// A participant's tile with the menu its tap opens: show him large (not on
/// his own page), mute or unmute him for everyone (once the room has him), end
/// his call. The tile is a tap target named for the menu, and so are the three
/// dots at its top right corner, which say the menu is there; the entries carry
/// the ids the corner controls of the tile had. While the room shows him as speaking, a border in the
/// theme's accent lies round the tile (SpeakingFrame), and nothing else moves.
class _ParticipantMenu extends StatefulWidget {
  const _ParticipantMenu({
    super.key,
    required this.participant,
    required this.params,
    required this.look,
    required this.onOpened,
    required this.radius,
    required this.child,
  });

  final _OpenParticipant participant;
  final CallScreenParams params;
  final _Look look;

  /// The corners of the tile, for the speaking border round it.
  final double radius;

  /// Shows the participant large; `null` on his own page.
  final VoidCallback? onOpened;
  final Widget child;

  @override
  State<_ParticipantMenu> createState() => _ParticipantMenuState();
}

class _ParticipantMenuState extends State<_ParticipantMenu> {
  final _menuKey = GlobalKey<PopupMenuButtonState<void>>();

  /// Whether the call screen's floating window lies over the dots' place at the top right: they
  /// go to the top left then, under the muted sign when it is there.
  bool _dotsCovered = false;

  @override
  void initState() {
    super.initState();
    floatingThumbnailArea.addListener(_checkDots);
  }

  @override
  void dispose() {
    floatingThumbnailArea.removeListener(_checkDots);
    super.dispose();
  }

  /// After layout, where both the tile and the window are known.
  void _checkDots() {
    if (!mounted) return;
    final box = context.findRenderObject();
    final window = floatingThumbnailArea.value;
    var covered = false;
    if (box is RenderBox && box.attached && box.hasSize && window != null) {
      final place = box.localToGlobal(Offset(box.size.width - _MoreMark.extent, 0));
      covered = (place & const Size.square(_MoreMark.extent)).overlaps(window);
    }
    if (covered != _dotsCovered) setState(() => _dotsCovered = covered);
  }

  @override
  Widget build(BuildContext context) {
    final participant = widget.participant;
    final params = widget.params;
    final index = participant.index;
    final name = participant.name;
    final muted = participant.muted;
    final colors = Theme.of(context).colorScheme;
    final iconColor = Theme.of(context).textTheme.bodyMedium?.color;
    final endColor =
        Theme.of(context).extension<CallScreenStyles>()?.primary?.actions?.hangup?.backgroundColor?.resolve(const {}) ??
        colors.error;
    final onOpened = widget.onOpened;
    final label = context.l10n.call_SemanticsLabel_conferenceParticipantMenu(name);
    final tile = SemanticAction.button(
      label: label,
      identifier: numberedId(conferenceTileId, index),
      child: CallPopupMenuButton<void>(
        menuKey: _menuKey,
        position: PopupMenuPosition.over,
        items: [
          if (onOpened != null)
            CallPopupMenuItem<void>(
              identifier: numberedId(conferenceTileOpenId, index),
              // After the menu has gone: the page opens over the tiles, not over a closing menu.
              onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => onOpened()),
              text: context.l10n.call_ConferenceFullScreen_showLarge,
              icon: Icon(Icons.open_in_full, size: 20, color: iconColor),
            ),
          CallPopupMenuItem<void>(
            identifier: numberedId(conferenceTileMuteId, index),
            enabled: participant.ready && params.onConferenceParticipantMuted != null,
            onTap: () => params.onConferenceParticipantMuted?.call(participant.callId, !muted),
            text: muted
                ? context.l10n.call_SemanticsLabel_conferenceParticipantUnmute(name)
                : context.l10n.call_SemanticsLabel_conferenceParticipantMute(name),
            icon: Icon(muted ? Icons.mic : Icons.mic_off, size: 20, color: iconColor),
          ),
          CallPopupMenuItem<void>(
            identifier: numberedId(conferenceParticipantHangupId, index),
            enabled: participant.ready || participant.call != null,
            onTap: () => params.onConferenceParticipantHangup?.call(participant.callId),
            text: context.l10n.call_SemanticsLabel_conferenceParticipantHangup(name),
            icon: Icon(Icons.call_end, size: 20, color: endColor),
          ),
        ],
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _openMenu, child: widget.child),
      ),
    );
    // The tiles move and the window is dragged: the dots' place is checked once laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDots());
    final dots = _MoreMark(index: index, label: label, look: widget.look, onTap: _openMenu);
    // The dots beside the tile's node, not inside it: the tile merges all under it into one node,
    // and a second tap target there would vanish into it.
    return Stack(
      fit: StackFit.expand,
      children: [
        tile,
        // Beside the tile's node too, so that it keeps an id of its own; over the picture, under the dots.
        if (participant.speaking)
          Positioned.fill(
            child: SpeakingFrame(identifier: numberedId(conferenceTileSpeakingId, index), radius: widget.radius),
          ),
        if (_dotsCovered)
          // Clear of the muted sign at the top left (8 + 28 dp), under it.
          Positioned(top: muted ? 36 : 0, left: 0, child: dots)
        else
          Positioned(top: 0, right: 0, child: dots),
      ],
    );
  }

  void _openMenu() => _menuKey.currentState?.showButtonMenu();
}

/// The three dots at a tile's top right corner: the sign that a tap opens the participant's menu,
/// and a tap target for it of its own. A dark translucent circle of [_size], drawn in a larger
/// square for the finger; clear of the muted sign, which is at the top left.
class _MoreMark extends StatelessWidget {
  const _MoreMark({required this.index, required this.label, required this.look, required this.onTap});

  final int index;
  final String label;
  final _Look look;
  final VoidCallback onTap;

  static const _size = 30.0;

  /// The square the dots take, their tap target.
  static const extent = 44.0;

  @override
  Widget build(BuildContext context) {
    return SemanticAction.button(
      label: label,
      identifier: numberedId(conferenceTileMoreId, index),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: extent,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(color: look.scrim.withValues(alpha: 0.45), shape: BoxShape.circle),
              child: SizedBox.square(
                dimension: _size,
                child: Icon(Icons.more_vert, size: 20, color: look.foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A participant's name at the bottom of a large picture, over a dark gradient: a big tile's and a
/// shared screen's.
class _NameStrip extends StatelessWidget {
  const _NameStrip({required this.name, required this.look, this.compact = false});

  final String name;
  final _Look look;

  /// A thumbnail's: smaller type and margins.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [look.scrim.withValues(alpha: 0), look.scrim.withValues(alpha: 0.55)],
        ),
      ),
      child: Padding(
        padding: compact ? const EdgeInsets.fromLTRB(8, 16, 8, 6) : const EdgeInsets.fromLTRB(12, 24, 12, 10),
        child: ExcludeSemantics(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: look.textStyle?.copyWith(
              color: look.foreground,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 12 : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// The small sign that a participant's microphone is off for the room: only
/// while it is, and not a control.
class _MutedBadge extends StatelessWidget {
  const _MutedBadge({required this.index, required this.look});

  final int index;
  final _Look look;

  @override
  Widget build(BuildContext context) {
    return SemanticId(
      identifier: numberedId(conferenceTileMutedId, index),
      child: DecoratedBox(
        decoration: BoxDecoration(color: look.scrim.withValues(alpha: 0.38), shape: BoxShape.circle),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(Icons.mic_off, size: 16, color: look.foreground),
        ),
      ),
    );
  }
}

/// A participant who sends video: the picture across the tile, the name on a
/// dark gradient at its foot, the muted sign at the top left while muted. On
/// [page] the picture is whole (contained) and the avatar large when it goes.
class _BigTile extends StatelessWidget {
  const _BigTile({
    required this.participant,
    required this.params,
    required this.look,
    required this.onAspectChanged,
    this.page = false,
  });

  final _OpenParticipant participant;
  final CallScreenParams params;
  final _Look look;
  final bool page;

  /// Hears the picture's proportions, for the grid.
  final ValueChanged<double> onAspectChanged;

  @override
  Widget build(BuildContext context) {
    final call = participant.call;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_tileRadius),
      child: ColoredBox(
        color: look.tileGround,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: ParticipantVideo(
                camera: participant.video,
                onAspectChanged: onAspectChanged,
                fit: page
                    ? RTCVideoViewObjectFit.RTCVideoViewObjectFitContain
                    : RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                placeholder: call == null
                    ? const SizedBox.shrink()
                    : Transform.scale(
                        scale: page ? 4 : 2.5,
                        child: CallRowAvatar(call: call, contactResolver: params.contactResolver),
                      ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _NameStrip(name: participant.name, look: look),
            ),
            if (participant.muted)
              Positioned(
                left: 8,
                top: 8,
                child: _MutedBadge(index: participant.index, look: look),
              ),
          ],
        ),
      ),
    );
  }
}

/// A participant as a thumbnail: the picture, or a 44 dp avatar a little above
/// the middle of the tile's ground, the name on the card at its bottom over the
/// big tiles' dark strip (one line, an ellipsis for a long one), and the muted
/// sign at the top left while muted. The same element under a shared screen and for whoever
/// sends no video.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.participant, required this.params, required this.look});

  final _OpenParticipant participant;
  final CallScreenParams params;
  final _Look look;

  /// The width of one in a row that scrolls, and the height of a row.
  static const width = 112.0;
  static const rowHeight = 132.0;

  /// The corners of the card.
  static const radius = 12.0;

  /// The avatar's size on a card without video.
  static const avatarSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final call = participant.call;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: look.tileGround,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: ParticipantVideo(
                camera: participant.video,
                // A little above the middle and 44 dp: the name strip at the bottom does not cover it.
                placeholder: call == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: const Alignment(0, -0.35),
                        child: Transform.scale(
                          scale: avatarSize / (CallRowAvatar.radius * 2),
                          child: CallRowAvatar(call: call, contactResolver: params.contactResolver),
                        ),
                      ),
              ),
            ),
            // The name on the card, as a big tile has it: one line, an ellipsis for a long one.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _NameStrip(name: participant.name, look: look, compact: true),
            ),
            if (participant.muted)
              Positioned(
                left: 6,
                top: 6,
                child: _MutedBadge(index: participant.index, look: look),
              ),
          ],
        ),
      ),
    );
  }
}

/// The room's controls: mic, camera, speaker, add participant, More, end of
/// the conference. No hold, transfer or calls outside the room on the bar;
/// More holds the keypad, the camera switch, hold - unavailable in a room, a
/// long press says so - and the screen share where the phone and the room
/// allow it.
///
/// One rule for the states of the toggles: on - a light button with a dark
/// icon; off - translucent, with the icon crossed out in the foreground;
/// unavailable - dimmed. While the host shares his screen the camera is
/// unavailable (the screen holds the room's line), and More carries a ring
/// and a screen badge in the theme's accent, its entry reading "Stop sharing"
/// in the same accent.
class _ControlBar extends StatefulWidget {
  const _ControlBar({required this.params, required this.foreground, required this.onKeypad});

  final CallScreenParams params;
  final Color foreground;
  final VoidCallback onKeypad;

  @override
  State<_ControlBar> createState() => _ControlBarState();
}

class _ControlBarState extends State<_ControlBar> {
  static const _size = 56.0;

  final _mic = WidgetStatesController();
  final _camera = WidgetStatesController();
  final _speaker = WidgetStatesController();

  @override
  void dispose() {
    _speaker.dispose();
    _camera.dispose();
    _mic.dispose();
    super.dispose();
  }

  CallScreenParams get _params => widget.params;

  void _toggleSpeaker() {
    final speakerOn = _params.audioDevice?.type == CallAudioDeviceType.speaker;
    final target = speakerOn ? _params.availableAudioDevices.getEarpiece : _params.availableAudioDevices.getSpeaker;
    if (target != null) _params.onAudioDeviceChanged(target);
  }

  void _toggleSelfMute() => _params.onConferenceSelfMuted?.call(!_params.conference.selfMuted);

  void _toggleCamera() => _params.onConferenceCameraChanged?.call(_params.conference.selfVideo == null);

  /// A round button of the bar: selected is on, the rest off, disabled dimmed.
  ButtonStyle _round({bool toggle = true}) {
    final foreground = widget.foreground;
    final on = Theme.of(context).colorScheme.scrim;
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(_size, _size)),
      fixedSize: const WidgetStatePropertyAll(Size(_size, _size)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      shape: const WidgetStatePropertyAll(CircleBorder()),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? foreground.withValues(alpha: 0.3)
            : toggle && states.contains(WidgetState.selected)
            ? on
            : foreground,
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? foreground.withValues(alpha: 0.06)
            : toggle && states.contains(WidgetState.selected)
            ? foreground
            : foreground.withValues(alpha: 0.16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = _params;
    final themeData = Theme.of(context);
    final accent = themeData.colorScheme.primary;
    final conference = params.conference;
    final micOn = !conference.selfMuted;
    final cameraOn = conference.selfVideo != null;
    final roomShare = params.roomScreenShare;
    final enabled = params.interactionsEnabled;
    final speakerOn = params.audioDevice?.type == CallAudioDeviceType.speaker;
    final textStyle = themeData.textTheme.bodyMedium;
    final iconColor = textStyle?.color;
    final plain = _round(toggle: false);
    final endStyle = themeData.extension<CallScreenStyles>()?.primary?.actions?.hangup;

    final more = CallActionMenuButton<void>(
      identifier: conferenceFullScreenMoreId,
      label: context.l10n.call_Watch_more,
      style: plain,
      items: [
        // First of More: the bar keeps the mic, the camera, the speaker, More and the end.
        CallPopupMenuItem<void>(
          identifier: conferenceFullScreenAddId,
          enabled: params.addParticipantAvailability.enabled && enabled && params.onAddParticipant != null,
          // After the menu has gone: what it opens comes over the room, not over a closing menu.
          onTap: () => WidgetsBinding.instance.addPostFrameCallback((_) => params.onAddParticipant?.call()),
          text: context.l10n.call_CallActionsTooltip_addParticipant,
          icon: Icon(Icons.person_add_alt_1, size: 20, color: iconColor),
          textStyle: textStyle,
        ),
        CallPopupMenuItem<void>(
          identifier: conferenceFullScreenKeypadId,
          onTap: widget.onKeypad,
          text: context.l10n.call_Watch_keypad,
          icon: Icon(Icons.dialpad, size: 20, color: iconColor),
          textStyle: textStyle,
        ),
        CallPopupMenuItem<void>(
          identifier: conferenceFullScreenSwitchCameraId,
          enabled: cameraOn && params.onConferenceCameraSwitched != null,
          onTap: params.onConferenceCameraSwitched,
          text: context.l10n.call_ConferenceFullScreen_switchCamera,
          icon: Icon(Icons.cameraswitch_outlined, size: 20, color: iconColor),
          textStyle: textStyle,
        ),
        // A room's legs are never held (docs/call-hold-policy): shown, so the
        // menu reads the same everywhere, disabled, and a long press says why.
        CallPopupMenuItem<void>(
          identifier: conferenceFullScreenHoldId,
          enabled: false,
          hint: context.l10n.call_ConferenceFullScreen_holdUnavailable,
          text: context.l10n.call_Watch_hold,
          icon: Icon(Icons.pause, size: 20, color: iconColor),
          textStyle: textStyle,
        ),
        if (params.onConferenceScreenShare case final onScreenShare?)
          CallPopupMenuItem<void>(
            identifier: callScreenShareConferenceId,
            onTap: () => onScreenShare(roomShare == null),
            text: roomShare == null
                ? context.l10n.call_screenShare_actionLabel_share
                : context.l10n.call_screenShare_actionLabel_stop,
            icon: Icon(
              roomShare == null ? Icons.screen_share_outlined : Icons.stop_screen_share_outlined,
              size: 20,
              color: roomShare == null ? iconColor : accent,
            ),
            textStyle: textStyle,
            accent: roomShare == null ? null : accent,
          ),
      ],
      child: const Icon(Icons.more_horiz),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CallActionButton(
            label: micOn ? context.l10n.call_CallActionsTooltip_mute : context.l10n.call_CallActionsTooltip_unmute,
            identifier: conferenceFullScreenMicId,
            onPressed: params.onConferenceSelfMuted == null || !enabled ? null : _toggleSelfMute,
            statesController: _mic..update(WidgetState.selected, micOn),
            style: _round(),
            child: Icon(micOn ? Icons.mic : Icons.mic_off),
          ),
          CallActionButton(
            label: cameraOn
                ? context.l10n.call_CallActionsTooltip_disableCamera
                : context.l10n.call_CallActionsTooltip_enableCamera,
            identifier: conferenceFullScreenCameraId,
            onPressed: params.onConferenceCameraChanged == null || !enabled || roomShare != null ? null : _toggleCamera,
            statesController: _camera..update(WidgetState.selected, cameraOn),
            style: _round(),
            child: Icon(cameraOn ? Icons.videocam : Icons.videocam_off),
          ),
          if (params.availableAudioDevices.onlyBuiltIn)
            CallActionButton(
              label: speakerOn
                  ? context.l10n.call_CallActionsTooltip_disableSpeaker
                  : context.l10n.call_CallActionsTooltip_enableSpeaker,
              identifier: conferenceFullScreenSpeakerId,
              onPressed: _toggleSpeaker,
              statesController: _speaker..update(WidgetState.selected, speakerOn),
              style: _round(),
              child: Icon(speakerOn ? Icons.volume_up : Icons.volume_off),
            )
          else
            CallActionMenuButton<CallAudioDevice>(
              identifier: conferenceFullScreenSpeakerId,
              label: context.l10n.call_CallActionsTooltip_changeAudioDevice,
              statesController: _speaker
                ..update(WidgetState.selected, params.audioDevice?.type != CallAudioDeviceType.earpiece),
              style: _round(),
              onSelected: params.onAudioDeviceChanged,
              items: [
                for (final device in params.availableAudioDevices)
                  CallPopupMenuItem<CallAudioDevice>(
                    value: device,
                    text: device.l10n(context),
                    icon: Icon(device.type.icon, size: 20, color: iconColor),
                    textStyle: textStyle,
                  ),
              ],
              child: Icon(params.audioDevice?.type.icon ?? Icons.volume_off),
            ),
          if (roomShare == null) more else ScreenShareMark(identifier: callScreenShareConferenceBadgeId, child: more),
          // It ends the room, as the default screen's hangup does while the
          // focused call is a leg, and says so.
          CallActionButton(
            label: context.l10n.call_SemanticsLabel_conferenceEnd,
            identifier: conferenceFullScreenEndId,
            onPressed: params.onHangup,
            style: (endStyle ?? plain).copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(_size, _size)),
              fixedSize: const WidgetStatePropertyAll(Size(_size, _size)),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              shape: const WidgetStatePropertyAll(CircleBorder()),
            ),
            child: const Icon(Icons.call_end),
          ),
        ],
      ),
    );
  }
}
