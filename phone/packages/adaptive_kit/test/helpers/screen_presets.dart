/// The screens a layout is checked on: the devices the configurator previews
/// the app on, so a test and the preview disagree only when the code does.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

/// One device screen, upright: its logical size, density and the system
/// insets the app has to keep clear of.
class ScreenPreset {
  const ScreenPreset(this.name, this.size, {required this.devicePixelRatio, this.padding = EdgeInsets.zero});

  final String name;
  final Size size;
  final double devicePixelRatio;
  final EdgeInsets padding;

  FormFactor get formFactor => FormFactor.fromSize(size);

  /// Puts the test window into this screen until the test ends.
  void apply(WidgetTester tester) {
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.view.physicalSize = size * devicePixelRatio;
    tester.view.padding = FakeViewPadding(
      left: padding.left * devicePixelRatio,
      top: padding.top * devicePixelRatio,
      right: padding.right * devicePixelRatio,
      bottom: padding.bottom * devicePixelRatio,
    );
    addTearDown(tester.view.reset);
  }

  @override
  String toString() => name;
}

/// The watches: Wear OS round faces and Apple Watch, sizes as the device
/// preview draws them.
const watchPresets = [
  ScreenPreset('Wear OS small round', Size(192, 192), devicePixelRatio: 2),
  ScreenPreset('Wear OS large round', Size(227, 227), devicePixelRatio: 2),
  ScreenPreset('Apple Watch SE 3 40mm', Size(162, 197), devicePixelRatio: 2),
  ScreenPreset('Apple Watch Series 12 46mm', Size(208, 248), devicePixelRatio: 2),
];

/// The phones, from the smallest still in use to a current large one.
const handsetPresets = [
  ScreenPreset('iPhone SE 3', Size(375, 667), devicePixelRatio: 2, padding: EdgeInsets.only(top: 20)),
  ScreenPreset('iPhone 16 Pro', Size(402, 874), devicePixelRatio: 3, padding: EdgeInsets.only(top: 62, bottom: 34)),
  ScreenPreset('Pixel 9', Size(411.43, 923.43), devicePixelRatio: 2.625, padding: EdgeInsets.only(top: 54, bottom: 24)),
];

/// The tablets.
const largePresets = [
  ScreenPreset('iPad 10', Size(820, 1180), devicePixelRatio: 2, padding: EdgeInsets.only(top: 24, bottom: 20)),
];

const allScreenPresets = [...watchPresets, ...handsetPresets, ...largePresets];

/// Pumps [widget] and returns what overflowed, one message per overflowing
/// box, instead of failing on the first.
///
/// A layout that does not fit reports itself through [FlutterError.onError]
/// on every frame it does not fit; collecting the reports lets a test say
/// which screens do not fit yet, and stops a known overflow from hiding a
/// second one.
Future<List<String>> pumpCollectingOverflows(WidgetTester tester, Widget widget) async {
  final overflows = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('overflowed')) {
      overflows.add(message.split('\n').first);
    } else {
      previous?.call(details);
    }
  };
  try {
    await tester.pumpWidget(widget);
    // Logos are SVG assets, read and decoded off the fake test clock: give
    // them real time, then lay the screen out again at its full height.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  } finally {
    FlutterError.onError = previous;
  }
  return overflows;
}
