import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call_routing/call_routing.dart';

import '../cubit/keypad_cubit.dart';
import '../widgets/widgets.dart';
import 'keypad_view_params.dart';
import 'keypad_view_parts.dart';

/// The keypad on a phone: the number centred in the space above the keys,
/// the full pad with letters, and the action pad - call, video, transfer,
/// the caller-id menu and backspace - under it.
class KeypadViewHandset extends StatelessWidget {
  const KeypadViewHandset({super.key, required this.params});

  final KeypadViewParams params;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final inputField = params.style?.inputField;
    final contactField = params.style?.contactNameField;
    final actionpadStyle = params.style?.actionpadStyle;

    final scaledInset = MediaQuery.of(context).size.height > 800 ? 16.0 : 8.0;
    return Column(
      children: [
        Expanded(
          // The input is intentionally invisible (blends with the background), so its own hit
          // target is a tiny box in the center. Catch long-presses across the whole upper region
          // and surface the input's context menu (paste/copy) from anywhere on the background.
          // Translucent (not opaque) so pointers still reach the field's own gesture handlers
          // instead of being fully absorbed by this background detector.
          //
          // It says nothing to assistive technology: an unnamed long press on an
          // invisible half of the screen is not something anyone can find, and
          // its annotation merged into the field below, stretching that field
          // over the whole region. The same thing is offered on the field
          // itself, as an action with a name.
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            onLongPress: params.onShowInputMenu,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: scaledInset),
              // The screen draws its body behind the app bar, so the top of this
              // region lies under it. The number is centred in what is left below
              // the bar: on a short screen the middle of the whole region is
              // still behind the bar.
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeypadNumberField(
                    fieldKey: params.fieldKey,
                    controller: params.controller,
                    focusNode: params.focusNode,
                    onPaste: params.onPaste,
                    fieldStyle: inputField,
                    style: inputField?.textStyle ?? themeData.textTheme.headlineLarge,
                  ),
                  KeypadContactName(
                    style: contactField?.textStyle ?? themeData.textTheme.bodyMedium,
                    textAlign: contactField?.textAlign,
                  ),
                ],
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: Keypad(
            onKeypadPressed: params.onKey,
            onKeypadHeld: params.onKeyHeld,
            style: params.style?.keypadStyle,
          ),
        ),
        SizedBox(height: scaledInset),
        RepaintBoundary(
          child: BlocBuilder<KeypadCubit, KeypadState>(
            // The whole value, not just whether there is one: what is typed
            // decides whether it can be chosen, so two different nonempty
            // numbers are not the same state.
            buildWhen: (p, c) => p.value != c.value,
            builder: (context, keypadState) {
              final pick = TypedPick.of(context, keypadState.value);
              final purpose = pick.purpose;

              return BlocBuilder<CallBloc, CallState>(
                buildWhen: (p, c) => p.activeCalls != c.activeCalls,
                builder: (context, callState) {
                  final activeCalls = callState.activeCalls;

                  return BlocBuilder<CallRoutingCubit, CallRoutingState?>(
                    builder: (context, callRoutingState) {
                      bool canCall = keypadState.noValue == false;

                      return Actionpad(
                        actionsEnabled: canCall,
                        onBackspacePressed: params.onBackspace,
                        onBackspaceLongPress: params.onClear,
                        onAudioCallPressed: params.onCall,
                        onVideoCallPressed: params.videoEnabled ? params.onVideoCall : null,
                        onTransferPressed: params.transferEnabled && activeCalls.isNotEmpty ? params.onTransfer : null,
                        // Not gated on the transfer configuration: that is
                        // permission to hand a call over, not permission to
                        // answer whatever is being asked.
                        // Shown for as long as the choice is being made, from
                        // the first key: an empty pad that looked like the
                        // ordinary dialer gave no sign it was choosing.
                        onInitiatedTransferPressed: purpose != null ? () => params.onPick(purpose) : null,
                        pickEnabled: pick.isAnswer,
                        pickIcon: purpose?.pickIcon,
                        pickLabel: pick.label,
                        callNumbers: callRoutingState?.allNumbers ?? [],
                        onCallFrom: params.onCallFrom,
                        style: actionpadStyle,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: scaledInset),
      ],
    );
  }
}
