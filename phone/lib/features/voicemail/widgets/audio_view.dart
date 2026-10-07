import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/bloc.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import 'audio_player_interface.dart';
import 'audio_slider.dart';
import 'playback_button.dart';

class AudioView extends StatelessWidget {
  const AudioView({required this.path, super.key, this.cacheKey, this.length, this.onPlaybackStarted});

  final String path;
  final String? cacheKey;

  /// How long the message is, as the mailbox listed it; null when it did not
  /// say. Shown before the recording is loaded, which is before anybody has
  /// pressed play - the moment a person decides what to listen to.
  final Duration? length;

  final VoidCallback? onPlaybackStarted;

  String get _id => cacheKey ?? path;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VoicemailPlaybackController>();
    final isActive = controller.activeId == _id;

    final Widget view;
    Duration? known = length;
    if (isActive && controller.isLoading) {
      view = const AudioLoadingView();
    } else if (isActive && controller.error != null) {
      view = _AudioErrorView(onRetry: () => _startPlayback(context));
    } else if (isActive) {
      // Once the recording is loaded its own length is the true one.
      known = controller.player.duration ?? length;
      view = AudioPlayerInterface(
        player: controller.player,
        onToggle: () => _handleToggle(context, controller),
        onSeek: controller.seek,
        listedLength: length,
      );
    } else {
      view = _InactiveAudioView(onPlay: () => _startPlayback(context), length: length);
    }

    if (known == null) return view;
    // The length belongs to the message, so it is said with the message - on
    // its row, whatever the player is doing - and not only by a slider that
    // exists once playback has started.
    return Semantics(label: spokenDuration(context.l10n, known), child: view);
  }

  void _startPlayback(BuildContext context) {
    final controller = context.read<VoicemailPlaybackController>();
    final vmContext = context.read<VoicemailScreenContext>();
    onPlaybackStarted?.call();
    unawaited(
      controller.play(
        id: _id,
        uri: Uri.parse(path),
        headers: vmContext.mediaHeaders,
        cacheBasePath: vmContext.mediaCacheBasePath,
        cacheKey: cacheKey,
        isLocal: path.isLocalPath,
      ),
    );
  }

  void _handleToggle(BuildContext context, VoicemailPlaybackController controller) {
    if (controller.isPlaying) {
      unawaited(controller.pause());
    } else {
      onPlaybackStarted?.call();
      unawaited(controller.resume());
    }
  }
}

class _InactiveAudioView extends StatelessWidget {
  const _InactiveAudioView({required this.onPlay, required this.length});

  final VoidCallback onPlay;
  final Duration? length;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PlaybackButton(playing: false, onPressed: onPlay),
        const SizedBox(width: 16),
        Expanded(
          // A placeholder for the real slider: it neither moves nor accepts
          // input until playback starts, so assistive technology must not
          // offer it as a control at all. It does show how long the message
          // is, when the mailbox said so.
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: AudioSlider(position: Duration.zero, duration: length, onSeek: (_) {}),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown while the message is being prepared for playback.
///
/// Activating play replaces the button with this view, so the node the user
/// was focused on disappears: it is named and marked as a live region, which
/// is what makes a screen reader say that something is happening instead of
/// silently dropping focus to the top of the screen.
@visibleForTesting
class AudioLoadingView extends StatelessWidget {
  const AudioLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n.voicemail_SemanticsLabel_loading,
      liveRegion: true,
      child: SizedBox(
        height: 40,
        child: Center(child: LinearProgressIndicator(color: colorScheme.primaryContainer)),
      ),
    );
  }
}

class _AudioErrorView extends StatelessWidget {
  const _AudioErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.voicemail_Label_playbackError,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          ),
          SemanticAction(
            label: context.l10n.voicemail_Label_retry,
            identifier: voicemailRetryId,
            child: IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh)),
          ),
        ],
      ),
    );
  }
}
