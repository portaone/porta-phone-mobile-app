import 'package:flutter/widgets.dart';

import 'package:clock/clock.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('AppTime');

/// The single source of the date and time formats the app shows.
///
/// Every format shown on screen is built on the call, never kept: a screen
/// or list asks for the formats it needs while it builds and hands the
/// [DateFormat] down to its rows, so a row only formats and a bloc never
/// holds a format. Only [fileNameDateFormat], which no reader sees, is kept.
///
/// Each format takes the locale the screen is shown in, read with
/// `Localizations.localeOf(context)`: the screen then rebuilds when the app
/// language changes and builds its formats again in the new language.
class AppTime {
  static Future<AppTime> init() async {
    final is24HourFormat = await _determine24HourFormat();

    _logger.info('Initialized with format: $is24HourFormat');

    return AppTime(is24HourFormat: is24HourFormat);
  }

  static Future<bool> _determine24HourFormat() async {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    try {
      final firstView = dispatcher.views.first;
      return MediaQueryData.fromView(firstView).alwaysUse24HourFormat;
    } catch (e, stackTrace) {
      _logger.warning('Determine hour format failure: $e', e, stackTrace);
      return true;
    }
  }

  AppTime({required bool is24HourFormat}) : _is24HourFormat = is24HourFormat;

  final bool _is24HourFormat;

  /// A format specifically designed for generating safe filenames.
  /// Pattern: `yyyy-MM-dd_HH-mm-ss`
  final DateFormat fileNameDateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

  bool get is24HourFormat => _is24HourFormat;

  /// Time of an entry in a list, following the device's 12/24-hour setting
  /// (e.g. 14:30, 2:30:00 PM).
  DateFormat timeFormat(Locale locale) =>
      _is24HourFormat ? DateFormat.Hm(_name(locale)) : DateFormat.jms(_name(locale));

  /// Date with time, following the device's 12/24-hour setting
  /// (e.g. Nov 6, 2026 14:30).
  DateFormat dateTimeFormat(Locale locale) =>
      _is24HourFormat ? DateFormat.yMMMd(_name(locale)).add_Hm() : DateFormat.yMMMd(_name(locale)).add_jms();

  /// Hours and minutes on a 24-hour clock (e.g. 14:30).
  DateFormat hourMinuteFormat(Locale locale) => DateFormat('HH:mm', _name(locale));

  /// Day and short month (e.g. 20 Aug).
  DateFormat dayMonthFormat(Locale locale) => DateFormat('d MMM', _name(locale));

  /// Full day of the week (e.g. Tuesday).
  DateFormat weekdayFormat(Locale locale) => DateFormat.EEEE(_name(locale));

  /// Short day of the week, day and short month (e.g. Tue, 6 Jan).
  DateFormat weekdayDayMonthFormat(Locale locale) => DateFormat('E, d MMM', _name(locale));

  /// [hourMinuteFormat] for a moment today, [dayMonthFormat] for any other.
  TimeOrDateFormat timeOrDateFormat(Locale locale) =>
      TimeOrDateFormat(time: hourMinuteFormat(locale), date: dayMonthFormat(locale));

  /// The intl name of [locale] (e.g. fr, en_US), the form Flutter's own
  /// localizations format their dates with.
  static String _name(Locale locale) => Intl.canonicalizedLocale(locale.toString());
}

/// Formats a moment as a clock time when it falls today and as a date
/// otherwise, the way list rows show when something last happened.
class TimeOrDateFormat {
  TimeOrDateFormat({required this.time, required this.date});

  final DateFormat time;
  final DateFormat date;

  /// Formats [value] on the phone's clock (it is converted to local time).
  String format(DateTime value) {
    final local = value.toLocal();
    final now = clock.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return midnight.isBefore(local) ? time.format(local) : date.format(local);
  }
}
