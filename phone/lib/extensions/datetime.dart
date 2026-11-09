extension DateTimeComprassion on DateTime {
  bool isSameDay(DateTime anotherDate) {
    final anotherLocal = anotherDate.toLocal();
    final thisLocal = toLocal();

    return thisLocal.year == anotherLocal.year &&
        thisLocal.month == anotherLocal.month &&
        thisLocal.day == anotherLocal.day;
  }
}
