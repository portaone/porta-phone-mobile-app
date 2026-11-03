import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../cubit/keypad_cubit.dart';
import '../widgets/widgets.dart';
import 'keypad_view_params.dart';
import 'keypad_view_parts.dart';

/// The keypad on a watch face.
///
/// The twelve keys fill the face, without the letters under the digits -
/// they only help with vanity numbers and take the room the digits need. The
/// number sits above them on one line with backspace beside it and the
/// matched contact under it; the call is the edge button along the bottom.
///
/// On the smallest face a key is about 44 x 24 points, under the usual tap
/// floor: twelve keys and a call button do not fit otherwise. The keys have
/// no gaps, so every whole cell is the target. Video, transfer and the
/// caller-id menu stay on the phone for now.
class KeypadViewWatch extends StatelessWidget {
  const KeypadViewWatch({super.key, required this.params});

  final KeypadViewParams params;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final inputField = params.style?.inputField;
    final contactField = params.style?.contactNameField;
    final small = themeData.textTheme.bodySmall;

    return WatchEdgeLayout(
      compact: true,
      padding: context.watchContentPadding().copyWith(bottom: 2),
      edge: (context, overlay) => _EdgeAction(params: params, overlay: overlay),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: KeypadNumberField(
                  fieldKey: params.fieldKey,
                  controller: params.controller,
                  focusNode: params.focusNode,
                  onPaste: params.onPaste,
                  fieldStyle: inputField,
                  style: (inputField?.textStyle ?? themeData.textTheme.titleLarge)?.copyWith(
                    fontSize: context.isSmallWatch ? 16 : 19,
                  ),
                  // The brand's field without its padding, sized for a phone
                  // screen; on a face every point goes to the keys.
                  decoration:
                      inputField?.decoration?.copyWith(isDense: true, contentPadding: EdgeInsets.zero) ??
                      const InputDecoration.collapsed(hintText: null),
                ),
              ),
              _Backspace(hasNumber: params.hasNumber, onPressed: params.onBackspace, onLongPress: params.onClear),
            ],
          ),
          // The brand's style in the small size. The line is kept while
          // nothing matches, so the keys do not move under a finger when a
          // contact is found.
          KeypadContactName(
            style: (contactField?.textStyle ?? small)?.copyWith(fontSize: small?.fontSize),
            textAlign: contactField?.textAlign,
            maxLines: 1,
          ),
          // The same id the phone's key carries, so automation dials the same
          // way on both.
          Expanded(
            child: WatchKeyGrid(keys: watchDialKeys, onPressed: params.onKey, identifier: keypadKeyId),
          ),
        ],
      ),
    );
  }
}

/// Backspace beside the number: off with nothing to erase, as on the phone,
/// and a key's width by the number's height - as wide a target as a key, the
/// row has no more height to give. Held, it clears the number.
class _Backspace extends StatelessWidget {
  const _Backspace({required this.hasNumber, required this.onPressed, required this.onLongPress});

  final ValueListenable<bool> hasNumber;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;

  static const _width = 44.0;
  static const _height = 28.0;

  @override
  Widget build(BuildContext context) {
    final disabledColor = Theme.of(context).disabledColor;
    return ValueListenableBuilder<bool>(
      valueListenable: hasNumber,
      builder: (context, enabled, _) {
        return SemanticAction(
          label: context.l10n.actionpad_SemanticsLabel_backspace,
          identifier: actionPadBackspaceId,
          child: InkResponse(
            key: actionPadBackspaceKey,
            onTap: enabled ? onPressed : null,
            onLongPress: enabled ? onLongPress : null,
            radius: 22,
            child: SizedBox(
              width: _width,
              height: _height,
              child: Icon(Icons.backspace_outlined, size: 16, color: enabled ? null : disabledColor),
            ),
          ),
        );
      },
    );
  }
}

/// The edge button: the choice being made, when the pad is asked for one;
/// the call otherwise. Only it follows the number, not the keys around it.
class _EdgeAction extends StatelessWidget {
  const _EdgeAction({required this.params, required this.overlay});

  final KeypadViewParams params;
  final ButtonStyle overlay;

  @override
  Widget build(BuildContext context) {
    final actionpadStyle = params.style?.actionpadStyle ?? Theme.of(context).extension<ActionpadStyles>()?.primary;
    final style = overlay.merge(actionpadStyle?.primary?.style);

    // Whether there is a number to call comes from the field; what a typed
    // number answers needs the number itself, which the cubit has.
    return ValueListenableBuilder<bool>(
      valueListenable: params.hasNumber,
      builder: (context, canCall, _) => BlocBuilder<KeypadCubit, KeypadState>(
        buildWhen: (p, c) => p.value != c.value,
        builder: (context, keypadState) {
          final pick = TypedPick.of(context, keypadState.value);
          final purpose = pick.purpose;

          if (purpose != null) {
            return SemanticAction(
              label: pick.label,
              identifier: actionPadTransferId,
              child: TextButton(
                onPressed: pick.isAnswer ? () => params.onPick(purpose) : null,
                style: style,
                child: Icon(purpose.pickIcon),
              ),
            );
          }
          return SemanticAction(
            label: context.l10n.numberActions_audioCall,
            identifier: actionPadVoiceCallId,
            child: TextButton(onPressed: canCall ? params.onCall : null, style: style, child: const Icon(Icons.call)),
          );
        },
      ),
    );
  }
}
