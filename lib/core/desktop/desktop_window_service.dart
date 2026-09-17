import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DesktopWindowBounds {
  const DesktopWindowBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.maximized = false,
    this.fullscreen = false,
    this.alwaysOnTop = false,
  });

  final int x;
  final int y;
  final int width;
  final int height;
  final bool maximized;
  final bool fullscreen;
  final bool alwaysOnTop;

  bool get isUsable => width >= 800 && height >= 500;

  Map<String, Object> toMap() {
    return <String, Object>{
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'maximized': maximized,
    };
  }

  static DesktopWindowBounds? fromMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    int read(Object? value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      return int.tryParse('$value') ?? 0;
    }

    return DesktopWindowBounds(
      x: read(raw['x']),
      y: read(raw['y']),
      width: read(raw['width']),
      height: read(raw['height']),
      maximized: raw['maximized'] == true,
      fullscreen: raw['fullscreen'] == true,
      alwaysOnTop: raw['alwaysOnTop'] == true,
    );
  }
}

abstract final class DesktopWindowService {
  static const MethodChannel _channel = MethodChannel('falconiptv/desktop');

  static bool get isSupported {
    if (kIsWeb) {
      return false;
    }
    return Platform.isWindows;
  }

  static Future<DesktopWindowBounds?> getBounds() async {
    if (!isSupported) {
      return null;
    }
    try {
      return DesktopWindowBounds.fromMap(await _channel.invokeMethod<dynamic>('getBounds'));
    } catch (_) {
      return null;
    }
  }

  static Future<void> setBounds(DesktopWindowBounds bounds) async {
    if (!isSupported || !bounds.isUsable) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setBounds', bounds.toMap());
    } catch (_) {}
  }

  static Future<void> setAlwaysOnTop(bool enabled) async {
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setAlwaysOnTop', enabled);
    } catch (_) {}
  }

  static Future<bool> toggleFullscreen() async {
    if (!isSupported) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('toggleFullscreen') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setFullscreen(bool enabled) async {
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setFullscreen', enabled);
    } catch (_) {}
  }

  static Future<void> setStartWithWindows(bool enabled) async {
    if (!isSupported) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setStartWithWindows', enabled);
    } catch (_) {}
  }
}
