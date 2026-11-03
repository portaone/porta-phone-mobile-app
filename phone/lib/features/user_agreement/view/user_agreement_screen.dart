import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/user_agreement/widgets/widgets.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class UserAgreementScreen extends StatefulWidget {
  const UserAgreementScreen({super.key, required this.appTermsAndConditionsUrl, required this.appName});

  final String appTermsAndConditionsUrl;
  final String appName;

  @override
  State<UserAgreementScreen> createState() => _UserAgreementScreenState();
}

class _UserAgreementScreenState extends State<UserAgreementScreen> {
  late AgreementStatus agreementStatus = context.read<AppBloc>().state.userAgreementStatus;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final ElevatedButtonStyles? elevatedButtonStyles = themeData.extension<ElevatedButtonStyles>();

    return Scaffold(
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, appState) {
          return AdaptiveLayout(
            watch: (context) => _UserAgreementWatch(
              appName: widget.appName,
              accepted: agreementStatus.isAccepted,
              onChanged: _handleAgreementStatusChange,
              onReadTerms: _openTerms,
              onContinue: agreementStatus.isAccepted ? _submitAgreement : null,
              buttonStyle: elevatedButtonStyles?.primary,
            ),
            handset: (context) => LayoutBuilder(
              builder: (context, viewportConstraints) {
                final body = Padding(
                  padding: const EdgeInsets.all(kInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: kInset * 2),
                      const AppIcon(Icons.menu_book_rounded, size: kInset * 6),
                      const SizedBox(height: kInset * 2),
                      Text(
                        context.l10n.user_agreement_description(widget.appName),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      const SizedBox(height: kInset),
                      LinkifyAgreementCheckbox(
                        agreementLink: widget.appTermsAndConditionsUrl,
                        userAgreementAccepted: agreementStatus.isAccepted,
                        onChanged: _handleAgreementStatusChange,
                        onAgreementLinkTap: _openTerms,
                      ),
                      const SizedBox(height: kInset / 2),
                      SemanticAction(
                        identifier: userAgreementAcceptButtonId,
                        child: OutlinedButton(
                          key: userAgreementAcceptButtonKey,
                          onPressed: agreementStatus.isAccepted ? _submitAgreement : null,
                          style: elevatedButtonStyles?.primary,
                          child: Text(context.l10n.user_agreement_button_text),
                        ),
                      ),
                    ],
                  ),
                );

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
                    child: IntrinsicHeight(child: InertSafeArea(bottom: true, child: body)),
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

  void _openTerms() {
    context.router.navigate(TermsConditionsScreenPageRoute(initialUriQueryParam: widget.appTermsAndConditionsUrl));
  }

  void _submitAgreement() {
    context.read<AppBloc>().add(AppAgreementAccepted.updateUserAgreement(agreementStatus));
  }
}

/// The terms on a watch face: the welcome line, the consent as a toggle,
/// the terms as their own button - the link cannot sit inside a sentence a
/// fingertip has to hit - and Continue as the edge button.
class _UserAgreementWatch extends StatelessWidget {
  const _UserAgreementWatch({
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
