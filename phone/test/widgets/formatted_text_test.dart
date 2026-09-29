import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/widgets/formatted_text.dart';

/// What a message looks like and where a tap on it goes.
///
/// The link preview finds its URL on its own, so these tests are about the tap: a preview can show
/// the right site while the underlined text opens something else.
void main() {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  const style = TextStyle(fontSize: 14, color: Color(0xFF000000));

  late List<String> launched;
  late bool launchThrows;

  setUp(() {
    launched = [];
    launchThrows = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'canLaunch':
          return true;
        case 'launch':
          if (launchThrows) throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
          launched.add((call.arguments as Map)['url'] as String);
          return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> pumpMessage(WidgetTester tester, String text, {bool interactive = true, VoidCallback? onRowTap}) async {
    Widget child = FormattedText(
      text: text,
      style: style,
      quoteDecoration: const BoxDecoration(),
      interactive: interactive,
    );
    if (onRowTap != null) child = ListTile(title: child, onTap: onRowTap);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  Future<void> tapOn(WidgetTester tester, String substring) async {
    await tester.tapOnText(find.textRange.ofSubstring(substring));
    await tester.pumpAndSettle();
  }

  RichText outer(WidgetTester tester) => tester.widget<RichText>(find.byType(RichText).first);

  String rendered(WidgetTester tester) => outer(tester).text.toPlainText();

  bool hasWidgetSpan(WidgetTester tester) {
    var found = false;
    outer(tester).text.visitChildren((span) {
      if (span is WidgetSpan) found = true;
      return !found;
    });
    return found;
  }

  /// The style of the leaf span showing exactly [text].
  TextStyle? styleOf(WidgetTester tester, String text) {
    TextStyle? result;
    for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
      richText.text.visitChildren((span) {
        if (span is TextSpan && span.text == text) {
          result = span.style;
          return false;
        }
        return true;
      });
    }
    return result;
  }

  List<GestureRecognizer> recognizers(WidgetTester tester) {
    final result = <GestureRecognizer>[];
    for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
      richText.text.visitChildren((span) {
        if (span is TextSpan && span.recognizer != null) result.add(span.recognizer!);
        return true;
      });
    }
    return result;
  }

  group('a link opens itself', () {
    testWidgets('on its own', (tester) async {
      await pumpMessage(tester, 'see https://example.com/a_b now');
      await tapOn(tester, 'https://example.com/a_b');

      expect(launched, ['https://example.com/a_b']);
    });

    testWidgets('a bare host opens over https', (tester) async {
      await pumpMessage(tester, 'see example.com/page now');
      await tapOn(tester, 'example.com/page');

      expect(launched, ['https://example.com/page']);
    });

    testWidgets('a link with parentheses opens whole', (tester) async {
      await pumpMessage(tester, 'read https://en.wikipedia.org/wiki/Bird_(god) first');
      await tapOn(tester, 'Bird_(god)');

      expect(launched, ['https://en.wikipedia.org/wiki/Bird_(god)']);
    });

    testWidgets('an internationalised host opens in its ASCII form', (tester) async {
      await pumpMessage(tester, 'see \u0441\u0430\u0439\u0442.\u0443\u043a\u0440 now');
      await tapOn(tester, '\u0441\u0430\u0439\u0442');

      expect(launched, ['https://xn--80aswg.xn--j1amh']);
    });

    testWidgets('each of two links opens its own address', (tester) async {
      await pumpMessage(tester, 'first.com and second.org');
      await tapOn(tester, 'first.com');
      await tapOn(tester, 'second.org');

      expect(launched, ['https://first.com', 'https://second.org']);
    });

    testWidgets('an email address opens the mail app on that address', (tester) async {
      await pumpMessage(tester, 'write a+tag@gmail.com today');
      await tapOn(tester, 'a+tag@gmail.com');

      expect(launched, ['mailto:a+tag@gmail.com']);
    });

    testWidgets('plain text around a link opens nothing', (tester) async {
      await pumpMessage(tester, 'see https://example.com now');
      await tapOn(tester, 'see');

      expect(launched, isEmpty);
    });

    testWidgets('a failing launch is not raised at the tap', (tester) async {
      launchThrows = true;
      await pumpMessage(tester, 'see https://example.com now');
      await tapOn(tester, 'https://example.com');

      expect(tester.takeException(), isNull);
    });
  });

  group('formatting markers earlier in the message leave a link alone', () {
    const cases = {
      'an underscore in a file name': ('rename my_file then open https://example.com/a_b', 'https://example.com/a_b'),
      'an underscore on an earlier line': ('my_var\nsee https://example.com/x_y', 'https://example.com/x_y'),
      'a plus in arithmetic': ('search 1+1 at https://google.com/search?q=a+b', 'https://google.com/search?q=a+b'),
      'a tilde in a home path': ('files in ~/tmp, docs at https://example.com/~user', 'https://example.com/~user'),
    };

    cases.forEach((description, sample) {
      final (text, url) = sample;

      testWidgets('$description: the tap opens the link', (tester) async {
        await pumpMessage(tester, text);
        await tapOn(tester, url);

        expect(launched, [url]);
      });

      testWidgets('$description: the text is shown as written', (tester) async {
        await pumpMessage(tester, text);

        expect(rendered(tester), text);
      });
    });
  });

  group('a greater-than sign inside a line is not a quote', () {
    const cases = {'an arrow': 'go -> https://example.com', 'a comparison': 'a > b, see https://example.com'};

    cases.forEach((description, text) {
      testWidgets('$description: the link stays tappable', (tester) async {
        await pumpMessage(tester, text);
        await tapOn(tester, 'https://example.com');

        expect(launched, ['https://example.com']);
      });

      testWidgets('$description: the line is not turned into a quote block', (tester) async {
        await pumpMessage(tester, text);

        expect(hasWidgetSpan(tester), isFalse);
      });
    });

    testWidgets('a line that starts with it is still a quote', (tester) async {
      await pumpMessage(tester, '> quoted text');

      expect(hasWidgetSpan(tester), isTrue);
      expect(find.text('quoted text', findRichText: true), findsOneWidget);
    });
  });

  group('an at sign inside a link keeps it a link', () {
    const urls = {
      'an email address in the query': 'https://example.com/unsubscribe?email=john@mail.com',
      'a dotted address in the query': 'https://example.com/?to=a.b@c.org&x=1',
      'credentials before the host': 'https://user:pass@example.com/x',
    };

    urls.forEach((description, url) {
      testWidgets('$description: the tap opens the site, not the mail app', (tester) async {
        await pumpMessage(tester, 'open $url now');
        await tapOn(tester, url);

        expect(launched, [url]);
      });
    });
  });

  group('a link inside formatting', () {
    const cases = {
      'bold': ('*https://example.com*', 'https://example.com'),
      'code': ('`https://example.com`', 'https://example.com'),
    };

    cases.forEach((description, sample) {
      final (text, url) = sample;

      testWidgets('$description: the tap opens the link', (tester) async {
        await pumpMessage(tester, text);
        await tapOn(tester, url);

        expect(launched, [url]);
      });

      testWidgets('$description: the markers are not shown', (tester) async {
        await pumpMessage(tester, text);

        expect(rendered(tester), url);
      });
    });

    testWidgets('bold: the link is drawn bold and underlined', (tester) async {
      await pumpMessage(tester, '*https://example.com*');

      final linkStyle = styleOf(tester, 'https://example.com')!;
      expect(linkStyle.fontWeight, FontWeight.bold);
      expect(linkStyle.decoration, TextDecoration.underline);
    });

    testWidgets('italic text without a link is still italic', (tester) async {
      await pumpMessage(tester, 'this is _important_ now');

      expect(rendered(tester), 'this is important now');
      expect(styleOf(tester, 'important')?.fontStyle, FontStyle.italic);
    });
  });

  group('a link inside a quote', () {
    testWidgets('stays tappable', (tester) async {
      await pumpMessage(tester, '> quoted https://example.com');
      await tapOn(tester, 'https://example.com');

      expect(launched, ['https://example.com']);
    });

    testWidgets('the text before and after the quote is kept', (tester) async {
      await pumpMessage(tester, 'before\n> quoted\nafter');

      expect(rendered(tester), startsWith('before\n'));
      expect(rendered(tester), endsWith('\nafter'));
      expect(find.text('quoted', findRichText: true), findsOneWidget);
    });
  });

  group('how each entity is drawn', () {
    testWidgets('a link is underlined and dimmed', (tester) async {
      await pumpMessage(tester, 'see https://example.com');

      final linkStyle = styleOf(tester, 'https://example.com')!;
      expect(linkStyle.decoration, TextDecoration.underline);
      expect(linkStyle.color, style.color!.withAlpha(100));
    });

    testWidgets('bold, strikethrough, underline and code', (tester) async {
      await pumpMessage(tester, '*b* ~s~ +u+ `c`');

      expect(rendered(tester), 'b s u c');
      expect(styleOf(tester, 'b')?.fontWeight, FontWeight.bold);
      expect(styleOf(tester, 's')?.decoration, TextDecoration.lineThrough);
      expect(styleOf(tester, 'u')?.decoration, TextDecoration.underline);
      expect(styleOf(tester, 'c')?.fontFamily, 'Courier');
    });

    testWidgets('nested decorations combine', (tester) async {
      await pumpMessage(tester, '~+both+~');

      expect(
        styleOf(tester, 'both')?.decoration,
        TextDecoration.combine([TextDecoration.lineThrough, TextDecoration.underline]),
      );
    });

    testWidgets('plain text keeps the given style', (tester) async {
      await pumpMessage(tester, 'plain');

      expect(styleOf(tester, 'plain'), style);
    });
  });

  group('when the text is not interactive', () {
    testWidgets('a link is still drawn as a link', (tester) async {
      await pumpMessage(tester, 'see https://example.com', interactive: false);

      expect(styleOf(tester, 'https://example.com')?.decoration, TextDecoration.underline);
    });

    testWidgets('a tap on a link opens nothing', (tester) async {
      await pumpMessage(tester, 'see https://example.com', interactive: false);
      await tapOn(tester, 'https://example.com');

      expect(launched, isEmpty);
      expect(recognizers(tester), isEmpty);
    });

    testWidgets('a tap on a link reaches the row underneath', (tester) async {
      var rowTaps = 0;
      await pumpMessage(tester, 'see https://example.com', interactive: false, onRowTap: () => rowTaps++);
      await tapOn(tester, 'https://example.com');

      expect(rowTaps, 1);
      expect(launched, isEmpty);
    });
  });

  group('when the text changes', () {
    testWidgets('the new text is shown and its link opened', (tester) async {
      await pumpMessage(tester, 'see first.com');
      await pumpMessage(tester, 'see second.org');

      expect(rendered(tester), 'see second.org');
      await tapOn(tester, 'second.org');
      expect(launched, ['https://second.org']);
    });

    testWidgets('turning interactivity off removes the tap targets', (tester) async {
      await pumpMessage(tester, 'see https://example.com');
      expect(recognizers(tester), hasLength(1));

      await pumpMessage(tester, 'see https://example.com', interactive: false);
      expect(recognizers(tester), isEmpty);
    });
  });
}
