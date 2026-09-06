import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'falcon_navigator.dart';
import 'phone_remote_html.dart';
import 'phone_remote_keys.dart';

class PhoneRemoteSession {
  const PhoneRemoteSession({
    required this.uri,
    required this.token,
    required this.port,
  });

  final Uri uri;
  final String token;
  final int port;
}

abstract final class PhoneRemoteService {
  static HttpServer? _server;
  static String? _token;
  static Uri? _uri;
  static DateTime? lastCommandAt;

  static PhoneRemoteSession? get session {
    final Uri? uri = _uri;
    final String? token = _token;
    if (uri == null || token == null || _server == null) {
      return null;
    }
    return PhoneRemoteSession(uri: uri, token: token, port: uri.port);
  }

  static bool get isRunning => _server != null;

  static Future<PhoneRemoteSession> ensureStarted() async {
    final PhoneRemoteSession? existing = session;
    if (existing != null) {
      return existing;
    }

    final String token = _newToken();
    HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv4, 18788);
    } on SocketException {
      server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    }
    server.listen((HttpRequest request) {
      unawaited(_handle(request, token: token));
    });

    final String? ip = await localIPv4();
    if (ip == null) {
      await server.close(force: true);
      throw const SocketException(
        'Yerel ağ adresi alınamadı. Telefon ile bilgisayarın aynı Wi‑Fi ağında olduğundan emin olunuz.',
      );
    }

    _server = server;
    _token = token;
    _uri = Uri(
      scheme: 'http',
      host: ip,
      port: server.port,
      queryParameters: <String, String>{'t': token},
    );
    return session!;
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _token = null;
    _uri = null;
  }

  static Future<String?> localIPv4() async {
    String? fallback;
    for (final NetworkInterface interface in await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    )) {
      for (final InternetAddress address in interface.addresses) {
        if (address.isLoopback) {
          continue;
        }
        final String ip = address.address;
        fallback ??= ip;
        if (ip.startsWith('192.168.') || ip.startsWith('10.')) {
          return ip;
        }
        final List<String> parts = ip.split('.');
        if (parts.length == 4 && parts[0] == '172') {
          final int? second = int.tryParse(parts[1]);
          if (second != null && second >= 16 && second <= 31) {
            return ip;
          }
        }
      }
    }
    return fallback;
  }

  static String _newToken() {
    const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final Random random = Random.secure();
    return List<String>.generate(6, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }

  static Future<void> _handle(HttpRequest request, {required String token}) async {
    try {
      if (request.method == 'GET' && (request.uri.path == '/' || request.uri.path.isEmpty)) {
        _writeHtml(request.response, PhoneRemoteHtml.page(token: token));
        return;
      }
      if (request.method == 'GET' && request.uri.path == '/api/ping') {
        if (request.uri.queryParameters['t'] != token) {
          _writeJson(request.response, <String, Object?>{'ok': false}, status: HttpStatus.forbidden);
          return;
        }
        _writeJson(request.response, <String, Object?>{'ok': true});
        return;
      }
      if (request.method == 'POST' && request.uri.path == '/api/key') {
        final String body = await utf8.decoder.bind(request).join();
        final Object? decoded = jsonDecode(body);
        if (decoded is! Map) {
          _writeJson(request.response, <String, Object?>{'ok': false, 'error': 'Geçersiz istek.'}, status: HttpStatus.badRequest);
          return;
        }
        if ('${decoded['t']}' != token) {
          _writeJson(request.response, <String, Object?>{'ok': false, 'error': 'Kod hatalı.'}, status: HttpStatus.forbidden);
          return;
        }
        final String action = '${decoded['action']}'.trim();
        final bool ok = _dispatch(action);
        lastCommandAt = DateTime.now();
        if (ok) {
          _writeJson(request.response, <String, Object?>{'ok': true, 'action': action});
        } else {
          _writeJson(
            request.response,
            <String, Object?>{'ok': false, 'error': 'Bilinmeyen komut.'},
            status: HttpStatus.badRequest,
          );
        }
        return;
      }
      _writeJson(request.response, <String, Object?>{'ok': false, 'error': 'Bulunamadı.'}, status: HttpStatus.notFound);
    } catch (_) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  static bool _dispatch(String action) {
    if (action == 'home') {
      FalconNavigator.goHome();
      return true;
    }
    if (action == 'play') {
      return PhoneRemoteKeys.tap('play') || PhoneRemoteKeys.tap('space');
    }
    return PhoneRemoteKeys.tap(action);
  }

  static void _writeHtml(HttpResponse response, String body) {
    response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType('text', 'html', charset: 'utf-8')
      ..write(body);
    unawaited(response.close());
  }

  static void _writeJson(HttpResponse response, Map<String, Object?> body, {int status = HttpStatus.ok}) {
    response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    unawaited(response.close());
  }
}
