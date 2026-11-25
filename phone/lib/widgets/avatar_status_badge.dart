import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/styles/styles.dart';

import '../utils/utils.dart';
import 'sip_presence_indicator.dart';

/// Contact status badge for the `LeadingAvatar` badge slot.
///
/// Owns the choice between the two status generations - the legacy
/// SIP-registration dot and the hybrid presence indicator - based on
/// [PresenceViewParams], so neither the avatar nor its callers need to know
/// which one a deployment uses. Sizes itself relative to the slot it is
/// given, matching the avatar's bottom-right badge geometry.
class AvatarStatusBadge extends StatelessWidget {
  const AvatarStatusBadge({super.key, this.registered, this.presenceInfo, this.dialogInfo});

  /// The badge for the given data, or `null` when there is no status data at
  /// all - so the avatar mounts nothing instead of an empty badge.
  static AvatarStatusBadge? maybe({bool? registered, List<PresenceInfo>? presenceInfo, List<DialogInfo>? dialogInfo}) {
    if (registered == null && presenceInfo == null && dialogInfo == null) return null;
    return AvatarStatusBadge(registered: registered, presenceInfo: presenceInfo, dialogInfo: dialogInfo);
  }

  /// The badge of [contact], from everything the contact carries: registration,
  /// presence and calls.
  ///
  /// The sites that used to pass the registration alone - the contact pickers,
  /// the call log, the number CDRs, the watch rows, the chat header and the
  /// members of a group chat - build their badge here, as a site that did so
  /// showed a registered phone as reachable while its owner had published do
  /// not disturb.
  ///
  /// Null when nothing is known that the badge would draw - no registration, no
  /// presence, no established call - so that the avatar mounts no badge.
  static AvatarStatusBadge? ofContact(Contact? contact) {
    if (contact == null) return null;

    // The same test the badge draws by: a phone that is only ringing is not a
    // call it shows, and a badge mounted for it alone would be empty.
    final nothingKnown =
        contact.registered == null && contact.presenceInfo.isEmpty && contact.dialogInfo.established == null;
    if (nothingKnown) return null;

    return AvatarStatusBadge(
      registered: contact.registered,
      presenceInfo: contact.presenceInfo,
      dialogInfo: contact.dialogInfo,
    );
  }

  /// SIP registration state, as the contact list reports it; `null` means it
  /// is unknown. Without hybrid presence support it feeds the legacy dot.
  /// With it, it is the last source asked: it decides the mark only for a
  /// contact nobody published a status for.
  final bool? registered;

  /// Presence states feeding the hybrid indicator. Empty or `null` means
  /// nothing was published about the contact - then [registered] answers, and
  /// if that is unknown too, no mark is shown.
  final List<PresenceInfo>? presenceInfo;

  /// BLF dialog states of the contact; an established call among them marks
  /// the contact as on a call via the activity icon of the hybrid indicator.
  /// A phone that is merely ringing is not one, so reported calls are not
  /// counted, they are read - see `DialogInfo.isEstablished`.
  final List<DialogInfo>? dialogInfo;

  @override
  Widget build(BuildContext context) {
    final presenceParams = PresenceViewParams.of(context);
    final style = LeadingAvatarStyles.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;

        if (presenceParams.hybridPresenceSupport) {
          // The sources answer in order, and the first that knows something
          // wins: what the contact's own app published, then what the PBX
          // holds for the number, then whether their phone is registered. The
          // last one is drawn exactly like the others, so a row does not
          // change shape depending on which of them answered.
          final presenceInfo = (this.presenceInfo ?? const <PresenceInfo>[]).leadingSource;
          final dialogInfo = this.dialogInfo ?? const <DialogInfo>[];
          final registered = this.registered;

          // Nothing published, no call reported, registration unknown. A mark
          // here could only say "unavailable", which nobody has said.
          final nothingKnown = presenceInfo.isEmpty && dialogInfo.established == null && registered == null;
          if (nothingKnown) return const SizedBox.shrink();

          final rect = BadgeLayout.onCircleEdgeSquare(size: size, sizeFactor: style.presenceBadge!.sizeFactor!);
          return Semantics(
            // A colour and a glyph say nothing out loud, so the state is
            // named here: it merges into the row's label and is read right
            // after the contact's name.
            label: _presenceLabel(context, presenceInfo, dialogInfo, registered),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fromRect(
                  rect: rect,
                  child: SipPresenceIndicator(
                    presenceInfo: presenceInfo,
                    dialogInfo: dialogInfo,
                    presenceRect: rect,
                    registered: registered,
                  ),
                ),
              ],
            ),
          );
        }

        final registered = this.registered;
        if (registered == null) return const SizedBox.shrink();

        // Drawn exactly like the presence mark - same size, same ring, same
        // place on the avatar edge. It used to sit small and fully inside the
        // avatar because it had no ring, which left deployments without
        // presence support with a mark a quarter of the coloured area of the
        // one WT-1779 enlarged; the ring is what lets it straddle the edge.
        final rect = BadgeLayout.onCircleEdgeSquare(size: size, sizeFactor: style.registeredBadge!.sizeFactor!);
        return Semantics(
          // Same reason as the presence mark above: a bare coloured dot is
          // silent, so the registration state is named here and read right
          // after the contact's name.
          label: registered
              ? context.l10n.presence_badge_state_registered
              : context.l10n.presence_badge_state_unregistered,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: rect,
                child: _RegisteredDot(registered: registered, style: style, side: rect.width),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The state in words, for anyone who does not see the mark.
  ///
  /// A published activity wins over the plain state - "on vacation" is what
  /// the contact chose to say, and it is more use than "available" - except
  /// while they are in a call, which outranks whatever they published earlier.
  ///
  /// This follows the GLYPH, not the colour: an established call is spoken
  /// even though it deliberately leaves the colour alone.
  String _presenceLabel(
    BuildContext context,
    List<PresenceInfo> presenceInfo,
    List<DialogInfo> dialogInfo,
    bool? registered,
  ) {
    final l10n = context.l10n;
    if (dialogInfo.established != null) return l10n.presence_badge_state_onCall;

    final activity = presenceInfo.primaryActivity;
    if (activity != null) return activity.l10n(l10n);

    return presenceInfo.reachable(registered: registered)
        ? l10n.presence_badge_state_available
        : l10n.presence_badge_state_unavailable;
  }
}

class _RegisteredDot extends StatelessWidget {
  const _RegisteredDot({required this.registered, required this.style, required this.side});

  final bool registered;
  final LeadingAvatarStyle style;

  /// Side of the square the dot is drawn into; the ring is a share of it, so
  /// the fill keeps its weight at every avatar size.
  final double side;

  @override
  Widget build(BuildContext context) {
    final rs = Theme.of(context).extension<RegisteredStatusStyles>()?.primary;

    final badge = style.registeredBadge!;
    final color = registered
        ? (badge.registeredColor ?? rs?.registered)
        : (badge.unregisteredColor ?? rs?.unregistered);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: side * 0.1),
      ),
    );
  }
}
