import '../../features/settings/data/desktop_settings_repository.dart';
import 'desktop_window_service.dart';

abstract final class DesktopSession {
  static Future<void> apply(DesktopSettingsRepository settings) async {
    if (!DesktopWindowService.isSupported) {
      return;
    }
    if (settings.rememberWindow) {
      final DesktopWindowBounds? bounds = settings.savedBounds;
      if (bounds != null) {
        await DesktopWindowService.setBounds(bounds);
      }
    }
    await DesktopWindowService.setAlwaysOnTop(settings.alwaysOnTop);
    await DesktopWindowService.setStartWithWindows(settings.startWithWindows);
  }

  static Future<void> persistBounds(DesktopSettingsRepository settings) async {
    if (!DesktopWindowService.isSupported || !settings.rememberWindow) {
      return;
    }
    final DesktopWindowBounds? bounds = await DesktopWindowService.getBounds();
    if (bounds == null || bounds.fullscreen || !bounds.isUsable) {
      return;
    }
    await settings.saveBounds(bounds);
  }
}
