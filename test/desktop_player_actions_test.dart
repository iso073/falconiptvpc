import 'package:falconiptv/core/desktop/desktop_player_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uyku zamanlayıcısı adımları döner', () {
    expect(DesktopPlayerActions.nextSleepMinutes(0), 15);
    expect(DesktopPlayerActions.nextSleepMinutes(15), 30);
    expect(DesktopPlayerActions.nextSleepMinutes(90), 0);
    expect(DesktopPlayerActions.sleepLabel(0), 'Kapalı');
    expect(DesktopPlayerActions.sleepLabel(30), '30 dk');
  });
}
