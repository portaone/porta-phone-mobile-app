import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/agreement_status.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class ContactsAgreementScreen extends StatefulWidget {
  const ContactsAgreementScreen({super.key});

  @override
  State<ContactsAgreementScreen> createState() => _ContactsAgreementScreenState();
}

class _ContactsAgreementScreenState extends State<ContactsAgreementScreen> {
  late AgreementStatus agreementStatus = context.read<AppBloc>().state.contactsAgreementStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final elevatedButtonStyles = theme.extension<ElevatedButtonStyles>();

    return Scaffold(
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, appState) {
          return AdaptiveLayout(
            watch: (context) => _ContactsAgreementWatch(
              accepted: agreementStatus.isAccepted,
              onChanged: _handleAgreementStatusChange,
              onContinue: _submitAgreement,
              buttonStyle: elevatedButtonStyles?.primary,
            ),
            handset: (context) => LayoutBuilder(
              builder: (context, viewportConstraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(kInset),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: kInset * 2),
                            const AppIcon(Icons.contacts, size: kInset * 6),
                            const SizedBox(height: kInset * 2),
                            Text(
                              context.l10n.contacts_agreement_title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: kInset),
                            Text(context.l10n.contacts_agreement_description, textAlign: TextAlign.center),
                            const Spacer(),
                            const SizedBox(height: kInset),
                            AgreementCheckbox(
                              checkboxKey: contactsAgreementCheckboxKey,
                              identifier: contactsAgreementCheckboxId,
                              agreementAccepted: agreementStatus.isAccepted,
                              onChanged: _handleAgreementStatusChange,
                              text: context.l10n.contacts_agreement_checkbox_text,
                            ),
                            const SizedBox(height: kInset / 2),
                            InertSafeArea(
                              bottom: true,
                              child: SemanticAction(
                                identifier: contactsAgreementAcceptButtonId,
                                child: OutlinedButton(
                                  key: contactsAgreementAcceptButtonKey,
                                  onPressed: _submitAgreement,
                                  style: elevatedButtonStyles?.primary,
                                  child: Text(context.l10n.contacts_agreement_button_text),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleAgreementStatusChange(bool value) {
    agreementStatus = value ? AgreementStatus.accepted : AgreementStatus.declined;
    setState(() {});
  }

  void _submitAgreement() {
    final resultStatus = agreementStatus.isPending ? AgreementStatus.declined : agreementStatus;
    context.read<AppBloc>().add(AppAgreementAccepted.updateContactsAgreement(resultStatus));
  }
}

/// The contacts consent on a watch face: the title, the consent as a toggle
/// right under it, the explanation in small text that scrolls, and Continue
/// as the edge button. As on a phone, Continue without the consent declines
/// it - so the toggle sits in view beside Continue, never at the end of a
/// text nobody scrolls through.
class _ContactsAgreementWatch extends StatelessWidget {
  const _ContactsAgreementWatch({
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
