import 'package:hive/hive.dart';

import '../../../core/constants/hive_boxes.dart';
import '../../../core/desktop/desktop_window_service.dart';

class DesktopSettingsRepository {
  DesktopSettingsRepository(this._settingsBox);

  final Box<dynamic> _settingsBox;

  bool get alwaysOnTop => _settingsBox.get(HiveBoxes.alwaysOnTopKey, defaultValue: false) == true;

  bool get startWithWindows =>
      _settingsBox.get(HiveBoxes.startWithWindowsKey, defaultValue: false) == true;

  bool get rememberWindow =>
      _settingsBox.get(HiveBoxes.rememberWindowKey, defaultValue: true) == true;

  DesktopWindowBounds? get savedBounds {
    final Object? raw = _settingsBox.get(HiveBoxes.windowBoundsKey);
    if (raw is! Map) {
      return null;
    }
    return DesktopWindowBounds.fromMap(Map<Object?, Object?>.from(raw));
  }

  Future<void> setAlwaysOnTop(bool value) {
    return _settingsBox.put(HiveBoxes.alwaysOnTopKey, value);
  }

  Future<void> setStartWithWindows(bool value) {
    return _settingsBox.put(HiveBoxes.startWithWindowsKey, value);
  }

  Future<void> setRememberWindow(bool value) {
    return _settingsBox.put(HiveBoxes.rememberWindowKey, value);
  }

  Future<void> saveBounds(DesktopWindowBounds bounds) {
    return _settingsBox.put(HiveBoxes.windowBoundsKey, bounds.toMap());
  }
}
