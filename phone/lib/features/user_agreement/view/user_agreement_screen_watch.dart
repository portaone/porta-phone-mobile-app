import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The terms on a watch face: the welcome line, the consent as a toggle,
/// the terms as their own button - the link cannot sit inside a sentence a
/// fingertip has to hit - and Continue as the edge button.
class UserAgreementScreenWatch extends StatelessWidget {
  const UserAgreementScreenWatch({
    super.key,
    required this.appName,
    required this.accepted,
    required this.onChanged,
    required this.onReadTerms,
    required this.onContinue,
    required this.buttonStyle,
  });

  final String appName;
  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onReadTerms;
  final VoidCallback? onContinue;
  final ButtonStyle? buttonStyle;

  @override
  Widget build(BuildContext context) {
    final gap = context.adaptiveMetrics.gap;
    return WatchActionLayout(
      title: context.l10n.user_agreement_description(appName),
      content: [
        // No text under the title here: the toggle keeps a little more room.
        SizedBox(height: gap),
        WatchToggleChip(
          label: context.l10n.user_agreement_toggle_text,
          value: accepted,
          onChanged: onChanged,
          identifier: userAgreementCheckboxId,
          toggleKey: userAgreementCheckboxKey,
        ),
        SizedBox(height: gap),
        WatchLink(
          label: context.l10n.user_agreement_terms_button_text,
          onPressed: onReadTerms,
          identifier: userAgreementTermsLinkId,
          linkKey: userAgreementTermsLinkKey,
        ),
      ],
      action: WatchAction(
        label: context.l10n.user_agreement_button_text,
        onPressed: onContinue,
        style: buttonStyle,
        identifier: userAgreementAcceptButtonId,
        buttonKey: userAgreementAcceptButtonKey,
      ),
    );
  }
}
