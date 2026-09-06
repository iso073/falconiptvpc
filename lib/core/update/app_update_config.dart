import 'dart:io';

/// GitHub Releases kaynağı. Depo herkese açık olmalıdır.
abstract final class AppUpdateConfig {
  static const String githubOwner = 'iso073';
  static const String githubRepo = 'falconiptvpc';
  static const String apkAssetName = 'falconiptv.apk';
  static const String windowsAssetName = 'falcontvpc.exe';
  static const List<String> windowsAssetNames = <String>[
    'falcontvpc.exe',
    'falconiptv.exe',
    'falconiptv-windows.exe',
    'falconiptv-windows.zip',
    'falcontvpc.zip',
  ];
  static const List<String> windowsExtensions = <String>['.exe', '.msi', '.zip', '.7z'];
  static const List<String> androidExtensions = <String>['.apk'];

  /// pubspec.yaml `version` ile aynı tutulmalıdır. TV APK sürümü değildir.
  static const String currentName = '1.0.0';
  static const int currentCode = 1;

  static const Duration checkInterval = Duration.zero;

  static String get latestApiUrl =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  static String get releasesApiUrl =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases?per_page=10';

  static String get latestPageUrl =>
      'https://github.com/$githubOwner/$githubRepo/releases/latest';

  static String apkUrlForTag(String tag) {
    return packageUrlForTag(tag, apkAssetName);
  }

  static String packageUrlForTag(String tag, String assetName) {
    final String safeTag = tag.startsWith('v') || tag.startsWith('V') ? tag : 'v$tag';
    return 'https://github.com/$githubOwner/$githubRepo/releases/download/${Uri.encodeComponent(safeTag)}/$assetName';
  }

  static String? tagFromReleaseUrl(String location) {
    final List<String> parts = location.split('/');
    final int tagIndex = parts.lastIndexOf('tag');
    if (tagIndex == -1 || tagIndex + 1 >= parts.length) {
      return null;
    }
    return Uri.decodeComponent(parts[tagIndex + 1].split('?').first);
  }

  static String? tagFromHtml(String html) {
    final Match? match = RegExp(r'/releases/tag/([vV]?[0-9][^"\s?<]+)').firstMatch(html);
    if (match == null) {
      return null;
    }
    return Uri.decodeComponent(match.group(1)!);
  }
}

class AppVersionInfo {
  const AppVersionInfo({required this.name, required this.code, this.tag = ''});

  final String name;
  final int code;
  final String tag;

  static AppVersionInfo current = const AppVersionInfo(
    name: AppUpdateConfig.currentName,
    code: AppUpdateConfig.currentCode,
  );

  static AppVersionInfo parse(String raw) {
    final String tag = raw.trim();
    String trimmed = tag.replaceFirst(RegExp(r'^(windows|win|pc)[-_]?', caseSensitive: false), '');
    trimmed = trimmed.replaceFirst(RegExp(r'^v', caseSensitive: false), '');
    final List<String> parts = trimmed.split('+');
    final String name = parts.first.trim().isEmpty ? '0.0.0' : parts.first.trim();
    final int? explicitCode = parts.length > 1 ? int.tryParse(parts[1].trim()) : null;
    return AppVersionInfo(
      name: name,
      code: explicitCode ?? _codeFromName(name),
      tag: tag,
    );
  }

  bool isNewerThan(AppVersionInfo other) {
    final int names = _compareNames(name, other.name);
    if (names != 0) {
      return names > 0;
    }
    return code > other.code;
  }

  static int _codeFromName(String name) {
    final List<int> parts = name
        .split('.')
        .map((String part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final int major = parts.isNotEmpty ? parts[0] : 0;
    final int minor = parts.length > 1 ? parts[1] : 0;
    final int patch = parts.length > 2 ? parts[2] : 0;
    return major * 10000 + minor * 100 + patch;
  }

  static int _compareNames(String a, String b) {
    final List<int> left = a.split('.').map((String p) => int.tryParse(p) ?? 0).toList();
    final List<int> right = b.split('.').map((String p) => int.tryParse(p) ?? 0).toList();
    final int length = left.length > right.length ? left.length : right.length;
    for (int i = 0; i < length; i++) {
      final int l = i < left.length ? left[i] : 0;
      final int r = i < right.length ? right[i] : 0;
      if (l != r) {
        return l.compareTo(r);
      }
    }
    return 0;
  }
}

class GithubReleaseInfo {
  const GithubReleaseInfo({
    required this.tag,
    required this.version,
    required this.apkUrl,
    this.notes = '',
    this.apkSize = 0,
  });

  final String tag;
  final AppVersionInfo version;
  final String apkUrl;
  final String notes;
  final int apkSize;

  String get cacheFileName {
    final String safeTag = tag.replaceAll(RegExp(r'[^A-Za-z0-9._+-]'), '_');
    final String ext = _extensionFromUrl(apkUrl);
    return 'falconiptv-$safeTag$ext';
  }

  static String _extensionFromUrl(String url) {
    final String path = Uri.tryParse(url)?.path ?? url;
    final int dot = path.lastIndexOf('.');
    if (dot == -1) {
      return '.bin';
    }
    return path.substring(dot).toLowerCase();
  }

  bool isReusableCache(File file) {
    return AppUpdateCache.isReusable(file, expectedSize: apkSize);
  }

  static GithubReleaseInfo? fromJson(
    Map<String, dynamic> json, {
    String preferredAsset = '',
    List<String> allowedExtensions = AppUpdateConfig.androidExtensions,
    List<String> preferredNames = const <String>[],
  }) {
    final String tag = '${json['tag_name'] ?? json['name'] ?? ''}'.trim();
    if (tag.isEmpty) {
      return null;
    }
    final Object? assetsRaw = json['assets'];
    if (assetsRaw is! List) {
      return null;
    }
    String? url;
    int size = 0;
    final List<String> preferred = <String>[
      if (preferredAsset.isNotEmpty) preferredAsset.toLowerCase(),
      ...preferredNames.map((String name) => name.toLowerCase()),
    ];
    for (final Object? asset in assetsRaw) {
      if (asset is! Map) {
        continue;
      }
      final String name = '${asset['name'] ?? ''}'.toLowerCase();
      final String browser = '${asset['browser_download_url'] ?? ''}';
      if (browser.isEmpty || !_hasAllowedExtension(name, allowedExtensions)) {
        continue;
      }
      final int assetSize = int.tryParse('${asset['size'] ?? ''}') ?? 0;
      if (preferred.contains(name)) {
        url = browser;
        size = assetSize;
        break;
      }
      url ??= browser;
      if (url == browser) {
        size = assetSize;
      }
    }
    if (url == null) {
      return null;
    }
    return GithubReleaseInfo(
      tag: tag,
      version: AppVersionInfo.parse(tag),
      apkUrl: url,
      notes: '${json['body'] ?? ''}'.trim(),
      apkSize: size,
    );
  }

  static bool _hasAllowedExtension(String name, List<String> extensions) {
    for (final String ext in extensions) {
      if (name.endsWith(ext)) {
        return true;
      }
    }
    return false;
  }
}

abstract final class AppUpdateCache {
  static const int minApkBytes = 1024 * 1024;

  static bool isReusable(File file, {int expectedSize = 0}) {
    if (!file.existsSync()) {
      return false;
    }
    final int length = file.lengthSync();
    if (length < minApkBytes) {
      return false;
    }
    if (expectedSize > 0 && length != expectedSize) {
      return false;
    }
    return true;
  }
}
