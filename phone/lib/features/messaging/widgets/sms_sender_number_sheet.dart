import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

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
    return NumberChoiceSheet(
      title: context.l10n.messaging_ConversationsScreen_selectNumberSheet_title,
      choices: [for (final number in numbers) NumberChoice(number: number)],
    );
  }
}
