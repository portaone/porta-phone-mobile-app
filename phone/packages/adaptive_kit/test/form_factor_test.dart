import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  group('FormFactor.fromSize', () {
    for (final preset in watchPresets) {
      test('$preset is a watch', () => expect(preset.formFactor, FormFactor.watch));
    }
    for (final preset in handsetPresets) {
      test('$preset is a handset', () => expect(preset.formFactor, FormFactor.handset));
    }
    for (final preset in largePresets) {
      test('$preset is large', () => expect(preset.formFactor, FormFactor.large));
    }

    test('a phone lying down stays a handset', () {
      expect(FormFactor.fromSize(const Size(874, 402)), FormFactor.handset);
    });

    test('a tablet lying down stays large', () {
      expect(FormFactor.fromSize(const Size(1180, 820)), FormFactor.large);
    });

    test('a window short on one side only is not a watch', () {
      // A phone in split screen lying down: low, but as wide as the phone.
      expect(FormFactor.fromSize(const Size(874, 200)), FormFactor.handset);
    });

    test('the watch boundary belongs to the handset', () {
      const edge = FormFactorBreakpoints.watchMaxSide;
      expect(FormFactor.fromSize(const Size(edge - 1, edge - 1)), FormFactor.watch);
      expect(FormFactor.fromSize(const Size(edge - 1, edge)), FormFactor.handset);
    });

    test('the large boundary belongs to large', () {
      const edge = FormFactorBreakpoints.largeMinShortestSide;
      expect(FormFactor.fromSize(const Size(edge - 1, 1000)), FormFactor.handset);
      expect(FormFactor.fromSize(const Size(edge, 1000)), FormFactor.large);
    });
  });

  group('FormFactor.resolve', () {
    test('a class with its own value gets it', () {
      expect(FormFactor.watch.resolve(handset: 'h', watch: 'w', large: 'l'), 'w');
      expect(FormFactor.handset.resolve(handset: 'h', watch: 'w', large: 'l'), 'h');
      expect(FormFactor.large.resolve(handset: 'h', watch: 'w', large: 'l'), 'l');
    });

    test('a class without its own value falls back to the handset one', () {
      expect(FormFactor.watch.resolve(handset: 'h'), 'h');
      expect(FormFactor.large.resolve(handset: 'h'), 'h');
    });
  });

  group('AdaptiveMetrics', () {
    test('a phone keeps the spacing the app has always used', () {
      expect(AdaptiveMetrics.of(FormFactor.handset).inset, 24);
      expect(AdaptiveMetrics.of(FormFactor.handset).minTapTarget, kMinInteractiveDimension);
    });

    test('a watch is tighter but keeps the tap floor', () {
      final watch = AdaptiveMetrics.of(FormFactor.watch);
      expect(watch.inset, lessThan(AdaptiveMetrics.handset.inset));
      expect(watch.minTapTarget, kMinInteractiveDimension);
    });

    test('a large screen uses the phone spacing until it gets its own', () {
      expect(AdaptiveMetrics.of(FormFactor.large), AdaptiveMetrics.handset);
    });
  });
}
