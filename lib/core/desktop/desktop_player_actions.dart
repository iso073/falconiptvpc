abstract final class DesktopPlayerActions {
  static const List<int> sleepMinutes = <int>[0, 15, 30, 45, 60, 90];

  static int nextSleepMinutes(int current) {
    final int index = sleepMinutes.indexOf(current);
    if (index == -1 || index + 1 >= sleepMinutes.length) {
      return sleepMinutes.first;
    }
    return sleepMinutes[index + 1];
  }

  static String sleepLabel(int minutes) {
    if (minutes <= 0) {
      return 'Kapalı';
    }
    return '$minutes dk';
  }
}
