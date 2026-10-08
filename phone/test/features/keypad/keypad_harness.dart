/// Everything needed to put [KeypadView] on a test screen: the blocs it reads,
/// the call controller it dials through, and a stand-in clipboard.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call_routing/call_routing.dart';
import 'package:webtrit_phone/features/keypad/keypad.dart';
import 'package:webtrit_phone/features/keypad/view/keypad_view.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class MockContactResolver extends Mock implements ContactResolver {}

class MockCallController extends Mock implements CallController {}

class MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

class MockCallRoutingCubit extends MockCubit<CallRoutingState?> implements CallRoutingCubit {}

class KeypadHarness {
  KeypadHarness() {
    final contactResolver = MockContactResolver();
    when(() => contactResolver.resolve(any())).thenAnswer((_) async => null);
    keypadCubit = KeypadCubit(contactResolver);
    when(() => callBloc.state).thenReturn(const CallState());
    when(() => routingCubit.state).thenReturn(null);
  }

  late final KeypadCubit keypadCubit;
  final MockCallBloc callBloc = MockCallBloc();
  final MockCallRoutingCubit routingCubit = MockCallRoutingCubit();

  /// What the view asked the clipboard, in order, by platform method name.
  final List<String> clipboardCalls = [];

  /// Answers the clipboard the way the platform would, with [text] on it.
  void withClipboard(String? text) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method.startsWith('Clipboard.')) clipboardCalls.add(call.method);
        if (call.method == 'Clipboard.getData') return text == null ? null : <String, dynamic>{'text': text};
        if (call.method == 'Clipboard.hasStrings') return <String, dynamic>{'value': text != null};
        return null;
      },
    );
  }

  void release() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  }

  /// [purpose] puts the pad inside a choice being made; [transferEnabled] is
  /// the call-transfer configuration, which must not decide whether a choice
  /// can be answered.
  ///
  /// [appBar] and [bottomNavigationBar] put the pad where the app puts it:
  /// behind an app bar the body is drawn under, above the tabs.
  Widget build({
    DestinationPickPurpose? purpose,
    bool transferEnabled = false,
    PreferredSizeWidget? appBar,
    Widget? bottomNavigationBar,
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        extendBodyBehindAppBar: appBar != null,
        appBar: appBar,
        bottomNavigationBar: bottomNavigationBar,
        body: CallControllerScope(
          controller: MockCallController(),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<KeypadCubit>.value(value: keypadCubit),
              BlocProvider<CallBloc>.value(value: callBloc),
              BlocProvider<CallRoutingCubit>.value(value: routingCubit),
            ],
            child: DestinationPicking(
              purpose: purpose,
              child: KeypadView(videoEnabled: true, transferEnabled: transferEnabled, style: null),
            ),
          ),
        ),
      ),
    );
  }
}

/// The number field as assistive technology sees it: one node carrying the text
/// field, its name and the actions offered on it.
SemanticsNode numberField(WidgetTester tester) => tester.getSemantics(find.byType(TextField));

/// Lets the debounce behind the field settle so a test ends with no timers
/// still running.
Future<void> teardownKeypad(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 500));
}
