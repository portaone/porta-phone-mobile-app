/// The parts both arrangements of the pad are made of.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../cubit/keypad_cubit.dart';
import '../utils/utils.dart';

/// What the typed number offers while the pad is asked for a choice, read
/// the same way for both arrangements.
///
/// Two questions, as everywhere else: whether this section can answer the
/// purpose at all - somewhere to forward a message to cannot be typed - and
/// whether what is typed right now is an answer it would take. What the
/// typed number offers is asked the way every list asks it. With nothing
/// typed there is no number to name, so the control is called after the
/// choice itself rather than read as a sentence missing its end.
class TypedPick {
  const TypedPick._(this.purpose, this.offer);

  factory TypedPick.of(BuildContext context, String? value) {
    final purpose = context.pickPurpose;
    if (purpose == null || !purpose.offeredBy(MainFlavor.keypad)) return const TypedPick._(null, null);
    final typed = DestinationCandidate(number: sanitize(value));
    return TypedPick._(purpose, typed.number != null ? context.pickOfferFor(typed) : null);
  }

  /// What is typed, in the form anything downstream would use it in.
  static String? sanitize(String? value) {
    if (value == null || value.isEmpty) return null;

    final number = PhoneNormalizingFormatter.sanitize(value);
    return number.isEmpty ? null : number;
  }

  /// The choice being made, when the pad can answer it; null otherwise.
  final DestinationPickPurpose? purpose;
  final DestinationPickOffer? offer;

  bool get isAnswer => offer?.isAnswer ?? false;

  String? get label {
    final purpose = this.purpose;
    return purpose == null ? null : offer?.label ?? purpose.announcement;
  }
}

/// The number being typed: one field for every arrangement, so the number
/// and its state live in the view's state whichever face shows them.
///
/// Name, id and the paste action sit on the field's own node: an identifier
/// makes a boundary of its own, and anything beside the field would be
/// announced apart from it. The number needs no naming - the field publishes
/// what it holds as its value.
class KeypadNumberField extends StatelessWidget {
  const KeypadNumberField({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.onPaste,
    required this.fieldStyle,
    required this.style,
    this.decoration,
  });

  /// The view reaches the field's text selection through it, for paste.
  final GlobalKey fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onPaste;

  /// The theme's field: alignment, cursor, keyboard, decoration.
  final TextFieldStyle? fieldStyle;

  /// The digits' type, which each arrangement sizes for itself.
  final TextStyle? style;

  /// In place of the theme's decoration, where its padding does not fit.
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = this.fieldStyle;
    return MergeSemantics(
      child: Semantics(
        label: context.l10n.keypad_SemanticsLabel_number,
        identifier: keypadNumberInputId,
        customSemanticsActions: {CustomSemanticsAction(label: context.l10n.keypad_SemanticsAction_paste): onPaste},
        child: TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          decoration: decoration ?? fieldStyle?.decoration ?? Theme.of(context).extension<InputDecorations>()?.keypad,
          style: style,
          textAlign: fieldStyle?.textAlign ?? TextAlign.center,
          showCursor: fieldStyle?.showCursor ?? true,
          keyboardType: fieldStyle?.keyboardType ?? TextInputType.none,
          cursorColor: fieldStyle?.cursorColor,
          inputFormatters: [PhoneNormalizingFormatter()],
        ),
      ),
    );
  }
}

/// The name of the contact the typed number matches, under the number.
class KeypadContactName extends StatelessWidget {
  const KeypadContactName({super.key, required this.style, this.textAlign, this.maxLines});

  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocBuilder<KeypadCubit, KeypadState>(
        buildWhen: (p, c) => (p.contact?.maybeName ?? '') != (c.contact?.maybeName ?? ''),
        builder: (context, state) {
          final name = state.contact?.maybeName ?? '';
          return Text(
            name,
            style: style,
            textAlign: textAlign ?? TextAlign.center,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
          );
        },
      ),
    );
  }
}
