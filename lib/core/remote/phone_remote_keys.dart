import 'dart:ffi';
import 'dart:io';

abstract final class PhoneRemoteKeys {
  static const int _keyeventfKeyup = 2;
  static const int _vkLeft = 0x25;
  static const int _vkUp = 0x26;
  static const int _vkRight = 0x27;
  static const int _vkDown = 0x28;
  static const int _vkReturn = 0x0D;
  static const int _vkEscape = 0x1B;
  static const int _vkSpace = 0x20;
  static const int _vkApps = 0x5D;
  static const int _vkVolumeDown = 0xAE;
  static const int _vkVolumeUp = 0xAF;
  static const int _vkMediaNext = 0xB0;
  static const int _vkMediaPrev = 0xB1;
  static const int _vkMediaPlayPause = 0xB3;

  static final DynamicLibrary? _user32 = Platform.isWindows ? DynamicLibrary.open('user32.dll') : null;

  static final void Function(int, int, int, int)? _keybdEvent = _user32
      ?.lookupFunction<Void Function(Uint8, Uint8, Uint32, IntPtr), void Function(int, int, int, int)>(
        'keybd_event',
      );

  static bool tap(String action) {
    final int? vk = _vkFor(action);
    if (vk == null || _keybdEvent == null) {
      return false;
    }
    _keybdEvent!(vk, 0, 0, 0);
    _keybdEvent!(vk, 0, _keyeventfKeyup, 0);
    return true;
  }

  static int? _vkFor(String action) {
    return switch (action) {
      'up' || 'ch_up' => _vkUp,
      'down' || 'ch_down' => _vkDown,
      'left' || 'seek_back' => _vkLeft,
      'right' || 'seek_fwd' => _vkRight,
      'ok' => _vkReturn,
      'back' => _vkEscape,
      'play' => _vkMediaPlayPause,
      'space' => _vkSpace,
      'menu' => _vkApps,
      'vol_up' => _vkVolumeUp,
      'vol_down' => _vkVolumeDown,
      'next' => _vkMediaNext,
      'prev' => _vkMediaPrev,
      _ => null,
    };
  }
}
