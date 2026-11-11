import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../extensions/extensions.dart';
import '../widgets/widgets.dart';

/// A contact's page on a watch, its actions handed in by the screen, which
/// the phone's card shares.
class ContactScreenWatch extends StatelessWidget {
  const ContactScreenWatch({
    super.key,
    required this.contact,
    required this.onCall,
    this.pickLabel,
    this.pickIcon,
    this.onPick,
    this.onVideoCall,
    this.onMessage,
    this.onCallLog,
    this.onFavoriteChanged,
    this.onEmail,
  });

  final Contact contact;
  final ValueChanged<String>? onCall;
  final String Function(ContactPhone phone)? pickLabel;
  final IconData? pickIcon;
  final VoidCallback? Function(ContactPhone phone)? onPick;
  final ValueChanged<String>? onVideoCall;
  final VoidCallback? onMessage;
  final ValueChanged<String>? onCallLog;
  final void Function(ContactPhone phone, bool favorite)? onFavoriteChanged;
  final ValueChanged<ContactEmail>? onEmail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SemanticId(
        identifier: contactScreenId,
        child: ContactWatchView(
          contact: contact,
          phones: contact.displayPhoneEntries,
          onCall: onCall,
          pickLabel: pickLabel,
          pickIcon: pickIcon,
          onPick: onPick,
          onVideoCall: onVideoCall,
          onMessage: onMessage,
          onCallLog: onCallLog,
          onFavoriteChanged: onFavoriteChanged,
          onEmail: onEmail,
        ),
      ),
    );
  }
}
