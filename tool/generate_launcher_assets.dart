// Regenerates launcher icons, TV banner, splash mark and the Windows .ico
// from assets/branding/falcon_logo.png.
//
// Run with: dart run tool/generate_launcher_assets.dart

import 'dart:io';

import 'package:image/image.dart';

const String _source = 'assets/branding/falcon_logo.png';
const String _windowsIco = 'windows/runner/resources/app_icon.ico';
final ColorRgb8 _background = ColorRgb8(0x0A, 0x0B, 0x10);

const Map<String, int> _launcherSizes = <String, int>{
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

void main() {
  final File sourceFile = File(_source);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Kaynak logo bulunamadı: $_source');
    exitCode = 1;
    return;
  }

  final Image? logo = decodeImage(sourceFile.readAsBytesSync());
  if (logo == null) {
    stderr.writeln('Logo çözümlenemedi: $_source');
    exitCode = 1;
    return;
  }

  if (Directory('android').existsSync()) {
    _writeLauncherIcons(logo);
    _writeTvBanner(logo);
    _writeSplash(logo);
  }
  _writeWindowsIco(logo);
  stdout.writeln('Launcher ikonları, TV banner, splash ve Windows .ico üretildi.');
}

void _writeLauncherIcons(Image logo) {
  _launcherSizes.forEach((String density, int size) {
    _write(
      'android/app/src/main/res/mipmap-$density/ic_launcher.png',
      _fitOnBackground(logo, width: size, height: size, inset: 0.12),
    );
  });
}

void _writeWindowsIco(Image logo) {
  final Image mark = _iconMark(logo);
  final List<Image> frames = <Image>[
    for (final int size in <int>[16, 24, 32, 48, 64, 128, 256])
      _fitOnBackground(
        size <= 48 ? mark : logo,
        width: size,
        height: size,
        inset: size <= 32 ? 0.08 : 0.1,
      ),
  ];
  final File file = File(_windowsIco);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(IcoEncoder().encodeImages(frames));
  stdout.writeln('  ${file.path}');
}

Image _iconMark(Image logo) {
  final int height = (logo.height * 0.62).round().clamp(1, logo.height);
  return copyCrop(logo, x: 0, y: 0, width: logo.width, height: height);
}

void _writeTvBanner(Image logo) {
  _write(
    'android/app/src/main/res/drawable-xhdpi/tv_banner.png',
    _fitOnBackground(logo, width: 320, height: 180, inset: 0.08),
  );
}

void _writeSplash(Image logo) {
  _write(
    'android/app/src/main/res/drawable-xxhdpi/splash_logo.png',
    _fitOnBackground(logo, width: 720, height: 720, inset: 0.08),
  );
}

Image _fitOnBackground(
  Image logo, {
  required int width,
  required int height,
  double inset = 0,
}) {
  final Image canvas = Image(width: width, height: height)..clear(_background);
  final int innerWidth = (width * (1 - inset * 2)).round().clamp(1, width);
  final int innerHeight = (height * (1 - inset * 2)).round().clamp(1, height);
  final double scale = (innerWidth / logo.width) < (innerHeight / logo.height)
      ? innerWidth / logo.width
      : innerHeight / logo.height;
  final Image scaled = copyResize(
    logo,
    width: (logo.width * scale).round().clamp(1, innerWidth),
    height: (logo.height * scale).round().clamp(1, innerHeight),
    interpolation: Interpolation.cubic,
  );

  return compositeImage(
    canvas,
    scaled,
    dstX: ((width - scaled.width) / 2).round(),
    dstY: ((height - scaled.height) / 2).round(),
  );
}

void _write(String path, Image image) {
  final File file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(image));
  stdout.writeln('  ${file.path}');
}
