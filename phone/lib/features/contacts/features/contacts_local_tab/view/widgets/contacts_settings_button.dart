import 'package:material_ui/material_ui.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

/// Leads to the app's page in the system settings, where access to the
/// address book is granted and a shared selection is edited. The tab rereads
/// the contacts when the app is resumed.
class ContactsSettingsButton extends StatelessWidget {
  const ContactsSettingsButton({super.key, required this.identifier, required this.label});

  final String identifier;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SemanticAction(
      identifier: identifier,
      child: TextButton(
        onPressed: () => openAppSettings(),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
