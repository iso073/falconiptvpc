#include "desktop_channel.h"

#include <flutter/standard_method_codec.h>

#include <cstdint>
#include <string>

namespace {

constexpr const wchar_t kRunKey[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
constexpr const wchar_t kRunName[] = L"FalconIPTVPC";

int ReadInt(const flutter::EncodableMap& map, const char* key, int fallback) {
  const auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return fallback;
  }
  if (const auto* value = std::get_if<int32_t>(&it->second)) {
    return *value;
  }
  if (const auto* value = std::get_if<int64_t>(&it->second)) {
    return static_cast<int>(*value);
  }
  if (const auto* value = std::get_if<double>(&it->second)) {
    return static_cast<int>(*value);
  }
  return fallback;
}

bool ReadBool(const flutter::EncodableValue* arguments, bool fallback) {
  if (arguments == nullptr) {
    return fallback;
  }
  if (const auto* value = std::get_if<bool>(arguments)) {
    return *value;
  }
  if (const auto* map = std::get_if<flutter::EncodableMap>(arguments)) {
    const auto it = map->find(flutter::EncodableValue("value"));
    if (it != map->end()) {
      if (const auto* value = std::get_if<bool>(&it->second)) {
        return *value;
      }
    }
  }
  return fallback;
}

std::wstring ExePath() {
  wchar_t path[MAX_PATH] = {0};
  const DWORD length = GetModuleFileNameW(nullptr, path, MAX_PATH);
  if (length == 0 || length >= MAX_PATH) {
    return std::wstring();
  }
  return std::wstring(L"\"") + path + L"\"";
}

}  // namespace

DesktopChannel::DesktopChannel(flutter::BinaryMessenger* messenger,
                               Win32Window* window)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "falconiptv/desktop",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) { Handle(call, std::move(result)); });
}

HWND DesktopChannel::hwnd() const {
  return window_ == nullptr ? nullptr : window_->GetHandle();
}

bool DesktopChannel::IsAlwaysOnTop() const {
  HWND handle = hwnd();
  if (handle == nullptr) {
    return false;
  }
  return (GetWindowLongPtr(handle, GWL_EXSTYLE) & WS_EX_TOPMOST) != 0;
}

void DesktopChannel::SetAlwaysOnTop(bool enabled) {
  HWND handle = hwnd();
  if (handle == nullptr) {
    return;
  }
  SetWindowPos(handle, enabled ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
}

bool DesktopChannel::IsFullscreen() const {
  return fullscreen_;
}

void DesktopChannel::SetFullscreen(bool enabled) {
  HWND handle = hwnd();
  if (handle == nullptr || fullscreen_ == enabled) {
    return;
  }
  if (enabled) {
    restore_style_ = GetWindowLong(handle, GWL_STYLE);
    GetWindowRect(handle, &restore_rect_);
    MONITORINFO info{sizeof(MONITORINFO)};
    GetMonitorInfo(MonitorFromWindow(handle, MONITOR_DEFAULTTONEAREST), &info);
    SetWindowLong(handle, GWL_STYLE, restore_style_ & ~WS_OVERLAPPEDWINDOW);
    SetWindowPos(handle, HWND_TOP, info.rcMonitor.left, info.rcMonitor.top,
                 info.rcMonitor.right - info.rcMonitor.left,
                 info.rcMonitor.bottom - info.rcMonitor.top,
                 SWP_FRAMECHANGED | SWP_SHOWWINDOW);
    fullscreen_ = true;
    return;
  }
  SetWindowLong(handle, GWL_STYLE, restore_style_ | WS_OVERLAPPEDWINDOW);
  SetWindowPos(handle, nullptr, restore_rect_.left, restore_rect_.top,
               restore_rect_.right - restore_rect_.left,
               restore_rect_.bottom - restore_rect_.top,
               SWP_FRAMECHANGED | SWP_NOZORDER | SWP_SHOWWINDOW);
  fullscreen_ = false;
}

flutter::EncodableMap DesktopChannel::BoundsMap() const {
  flutter::EncodableMap map;
  HWND handle = hwnd();
  RECT rect{};
  if (handle != nullptr) {
    GetWindowRect(handle, &rect);
  }
  const bool maximized =
      handle != nullptr && IsZoomed(handle) != 0;
  map[flutter::EncodableValue("x")] = flutter::EncodableValue(rect.left);
  map[flutter::EncodableValue("y")] = flutter::EncodableValue(rect.top);
  map[flutter::EncodableValue("width")] =
      flutter::EncodableValue(rect.right - rect.left);
  map[flutter::EncodableValue("height")] =
      flutter::EncodableValue(rect.bottom - rect.top);
  map[flutter::EncodableValue("maximized")] = flutter::EncodableValue(maximized);
  map[flutter::EncodableValue("fullscreen")] =
      flutter::EncodableValue(fullscreen_);
  map[flutter::EncodableValue("alwaysOnTop")] =
      flutter::EncodableValue(IsAlwaysOnTop());
  return map;
}

bool DesktopChannel::SetBounds(const flutter::EncodableMap& map) {
  HWND handle = hwnd();
  if (handle == nullptr || fullscreen_) {
    return false;
  }
  const int x = ReadInt(map, "x", 80);
  const int y = ReadInt(map, "y", 80);
  const int width = ReadInt(map, "width", 1600);
  const int height = ReadInt(map, "height", 900);
  bool maximized = false;
  const auto maximized_it = map.find(flutter::EncodableValue("maximized"));
  if (maximized_it != map.end()) {
    if (const auto* value = std::get_if<bool>(&maximized_it->second)) {
      maximized = *value;
    }
  }
  ShowWindow(handle, SW_RESTORE);
  SetWindowPos(handle, nullptr, x, y, width, height,
               SWP_NOZORDER | SWP_NOACTIVATE);
  if (maximized) {
    ShowWindow(handle, SW_MAXIMIZE);
  }
  return true;
}

bool DesktopChannel::IsStartWithWindows() const {
  wchar_t buffer[MAX_PATH + 4] = {0};
  DWORD size = sizeof(buffer);
  const LSTATUS status =
      RegGetValueW(HKEY_CURRENT_USER, kRunKey, kRunName, RRF_RT_REG_SZ, nullptr,
                   buffer, &size);
  return status == ERROR_SUCCESS && buffer[0] != 0;
}

bool DesktopChannel::SetStartWithWindows(bool enabled) {
  HKEY key = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kRunKey, 0, KEY_SET_VALUE, &key) !=
      ERROR_SUCCESS) {
    return false;
  }
  LSTATUS status = ERROR_SUCCESS;
  if (enabled) {
    const std::wstring command = ExePath();
    if (command.empty()) {
      RegCloseKey(key);
      return false;
    }
    status = RegSetValueExW(
        key, kRunName, 0, REG_SZ,
        reinterpret_cast<const BYTE*>(command.c_str()),
        static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t)));
  } else {
    status = RegDeleteValueW(key, kRunName);
    if (status == ERROR_FILE_NOT_FOUND) {
      status = ERROR_SUCCESS;
    }
  }
  RegCloseKey(key);
  return status == ERROR_SUCCESS;
}

void DesktopChannel::Handle(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  if (method == "getBounds") {
    result->Success(flutter::EncodableValue(BoundsMap()));
    return;
  }
  if (method == "setBounds") {
    const auto* map =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (map == nullptr) {
      result->Error("bad_args", "setBounds bir harita bekler.");
      return;
    }
    result->Success(flutter::EncodableValue(SetBounds(*map)));
    return;
  }
  if (method == "setAlwaysOnTop") {
    SetAlwaysOnTop(ReadBool(call.arguments(), false));
    result->Success(flutter::EncodableValue(IsAlwaysOnTop()));
    return;
  }
  if (method == "isAlwaysOnTop") {
    result->Success(flutter::EncodableValue(IsAlwaysOnTop()));
    return;
  }
  if (method == "setFullscreen") {
    SetFullscreen(ReadBool(call.arguments(), false));
    result->Success(flutter::EncodableValue(IsFullscreen()));
    return;
  }
  if (method == "isFullscreen") {
    result->Success(flutter::EncodableValue(IsFullscreen()));
    return;
  }
  if (method == "toggleFullscreen") {
    SetFullscreen(!IsFullscreen());
    result->Success(flutter::EncodableValue(IsFullscreen()));
    return;
  }
  if (method == "setStartWithWindows") {
    result->Success(
        flutter::EncodableValue(SetStartWithWindows(ReadBool(call.arguments(), false))));
    return;
  }
  if (method == "isStartWithWindows") {
    result->Success(flutter::EncodableValue(IsStartWithWindows()));
    return;
  }
  result->NotImplemented();
}
