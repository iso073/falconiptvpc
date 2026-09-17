#ifndef RUNNER_DESKTOP_CHANNEL_H_
#define RUNNER_DESKTOP_CHANNEL_H_

#include "win32_window.h"

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>

#include <memory>

class DesktopChannel {
 public:
  DesktopChannel(flutter::BinaryMessenger* messenger, Win32Window* window);
  void Handle(const flutter::MethodCall<flutter::EncodableValue>& call,
              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  HWND hwnd() const;
  bool IsAlwaysOnTop() const;
  void SetAlwaysOnTop(bool enabled);
  bool IsFullscreen() const;
  void SetFullscreen(bool enabled);
  flutter::EncodableMap BoundsMap() const;
  bool SetBounds(const flutter::EncodableMap& map);
  bool IsStartWithWindows() const;
  bool SetStartWithWindows(bool enabled);

  Win32Window* window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  bool fullscreen_ = false;
  LONG restore_style_ = 0;
  RECT restore_rect_{};
};

#endif  // RUNNER_DESKTOP_CHANNEL_H_
