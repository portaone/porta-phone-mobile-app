import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';
import 'semantic_id.dart';

/// One number offered in a [NumberChoiceSheet], and what it is where that is
/// known.
class NumberChoice {
  const NumberChoice({required this.number, this.label});

  final String number;

  /// What the number is to its owner - "ext", "mobile" - shown under it.
  final String? label;
}

/// Asks which of several numbers to use, and closes with the one tapped.
///
/// The list scrolls inside the sheet: a contact can have more numbers than fit
/// on a small screen, and a column that overflows would hide the last of them.
class NumberChoiceSheet extends StatelessWidget {
  const NumberChoiceSheet({
    required this.title,
    required this.choices,
    this.identifier,
    this.choiceIdentifier,
    super.key,
  });

  final String title;
  final List<NumberChoice> choices;

  /// The sheet's automation id, where automation reaches it.
  final String? identifier;

  /// The automation id of the choice at an index, where automation reaches it.
  final String Function(int index)? choiceIdentifier;

  @override
  Widget build(BuildContext context) {
    final sheet = LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: constraints.maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: choices.length,
                itemBuilder: (context, index) => SemanticAction(
                  identifier: choiceIdentifier?.call(index),
                  child: ListTile(
                    title: Text(choices[index].number),
                    subtitle: choices[index].label == null ? null : Text(choices[index].label!),
                    onTap: () => Navigator.of(context).pop(choices[index].number),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final id = identifier;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
      child: id == null ? sheet : SemanticId(identifier: id, child: sheet),
    );
  }
}
