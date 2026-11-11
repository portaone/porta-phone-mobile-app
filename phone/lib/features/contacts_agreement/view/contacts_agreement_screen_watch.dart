import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The contacts consent on a watch face: the title, the consent as a toggle
/// right under it, the explanation in small text that scrolls, and Continue
/// as the edge button. As on a phone, Continue without the consent declines
/// it - so the toggle sits in view beside Continue, never at the end of a
/// text nobody scrolls through.
class ContactsAgreementScreenWatch extends StatelessWidget {
  const ContactsAgreementScreenWatch({
    super.key,
    required this.accepted,
    required this.onChanged,
    required this.onContinue,
    required this.buttonStyle,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onContinue;
  final ButtonStyle? buttonStyle;

  @override
  Widget build(BuildContext context) {
    final gap = context.adaptiveMetrics.gap;
    return WatchActionLayout(
      title: context.l10n.contacts_agreement_title,
      content: [
        WatchToggleChip(
          label: context.l10n.contacts_agreement_toggle_text,
          value: accepted,
          onChanged: onChanged,
          identifier: contactsAgreementCheckboxId,
          toggleKey: contactsAgreementCheckboxKey,
        ),
        SizedBox(height: gap * 2),
        Text(context.l10n.contacts_agreement_description),
      ],
      action: WatchAction(
        label: context.l10n.contacts_agreement_button_text,
        onPressed: onContinue,
        style: buttonStyle,
        identifier: contactsAgreementAcceptButtonId,
        buttonKey: contactsAgreementAcceptButtonKey,
      ),
    );
  }
}
