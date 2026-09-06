import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on and resets the system idle timer while a stream plays.
abstract final class PlaybackKeepAwake {
  static const MethodChannel _channel = MethodChannel('falconiptv/display');

  static Future<void> enable() => _set(true);

  static Future<void> disable() => _set(false);

  static Future<void> _set(bool enabled) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        if (enabled) {
          await WakelockPlus.enable();
        } else {
          await WakelockPlus.disable();
        }
      } catch (_) {}
      return;
    }
    try {
      await _channel.invokeMethod<void>('setKeepScreenOn', enabled);
    } catch (_) {
      // Tests and shells without a display channel ignore this.
    }
  }
}
