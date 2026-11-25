/// The instant an ISO 8601 [value] stands for, or null when it cannot be read.
///
/// A [value] that names its zone (`Z`, `+02:00`, `+0200`) is that instant, and [wallClockOffsetMin] is not applied
/// to it. One that names no zone is a wall clock, and [wallClockOffsetMin] - minutes east of UTC - says whose: its
/// fields are taken as UTC and the offset is subtracted. They are not read in the zone of this phone on the way,
/// because a wall clock inside this phone's spring-forward gap does not exist there and would come out an hour off.
/// Without [wallClockOffsetMin] a value with no zone is read in the zone of this phone, the only reading left.
DateTime? parseIsoInstant(String? value, {int? wallClockOffsetMin}) {
  if (value == null) return null;

  // Whether the value names a zone is left to the parser itself, which reads
  // a value as UTC exactly when it carries one; a pattern of our own could
  // disagree with it, and a bare date such as 2026-07-31 ends like an offset.
  final parsed = DateTime.tryParse(value);
  if (parsed == null || parsed.isUtc || wallClockOffsetMin == null) return parsed;

  // A bare date takes no zone designator, so it is the one value the parser
  // refuses this way; its fields are taken from the reading above instead.
  final wallClock = DateTime.tryParse('${value}Z') ?? _fieldsAsUtc(parsed);
  return wallClock.subtract(Duration(minutes: wallClockOffsetMin));
}

DateTime _fieldsAsUtc(DateTime time) {
  return DateTime.utc(
    time.year,
    time.month,
    time.day,
    time.hour,
    time.minute,
    time.second,
    time.millisecond,
    time.microsecond,
  );
}
