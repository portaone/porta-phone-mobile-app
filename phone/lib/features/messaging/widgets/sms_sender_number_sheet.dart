import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

/// Asks which of the user's own SMS numbers a new conversation is sent from,
/// for an account that has more than one.
class SmsSenderNumberSheet extends StatelessWidget {
  const SmsSenderNumberSheet({required this.numbers, super.key});

  /// The user's own SMS numbers, as Core gives them over the messaging socket.
  final List<String> numbers;

  /// The number picked, or null when the sheet was closed without a pick.
  static Future<String?> show(BuildContext context, {required List<String> numbers}) async {
    final result = await context.showModalBottomSheet(builder: (context) => SmsSenderNumberSheet(numbers: numbers));
    return result is String ? result : null;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
      child: Column(
        children: [
          ListTile(
            title: Text(
              context.l10n.messaging_ConversationsScreen_selectNumberSheet_title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          ...numbers.map((number) {
            return ListTile(title: Text(number), onTap: () => Navigator.of(context).pop(number));
          }),
        ],
      ),
    );
  }
}
