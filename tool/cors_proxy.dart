import 'dart:async';
import 'dart:io';

/// Local zero-dependency Dart HTTP + WebSocket CORS reverse proxy for Flutter Web (Chrome).
///
/// Why this is needed for Chrome (`flutter run -d chrome`):
/// Production `server.ts` on `https://hospital.hrpocket.in` enforces:
///   1. `cors()` rejecting browser `Origin: http://localhost:<port>` headers with HTTP 500
///   2. `helmet({ crossOriginResourcePolicy: { policy: 'same-site' } })`
/// Native Android / iOS builds send NO `Origin` header and connect directly to
/// `https://hospital.hrpocket.in`. For Chrome development on desktop, this local
/// bridge strips `Origin`/`Referer` before forwarding to `https://hospital.hrpocket.in`
/// and attaches permissive CORS headers for localhost Chrome.
class LocalHospitalCorsProxy {
  final String targetOrigin;
  final int port;
  HttpServer? _server;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..autoUncompress = true;

  LocalHospitalCorsProxy({
    this.targetOrigin = 'https://hospital.hrpocket.in',
    this.port = 8787,
  });

  Future<HttpServer> start() async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
      shared: true,
    );
    _server = server;
    server.listen(_handleRequest, onError: (Object e) {
      stderr.writeln('[CORS Proxy Error] $e');
    });
    return server;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _client.close(force: true);
  }

  void _applyCorsHeaders(HttpRequest req, HttpResponse res) {
    final reqOrigin = req.headers.value('origin') ?? '*';
    res.headers.set('Access-Control-Allow-Origin', reqOrigin);
    res.headers.set('Vary', 'Origin');
    res.headers.set('Access-Control-Allow-Credentials', 'true');
    res.headers.set(
      'Access-Control-Allow-Methods',
      'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    );
    res.headers.set(
      'Access-Control-Allow-Headers',
      req.headers.value('access-control-request-headers') ??
          'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-Hospital-Target',
    );
    res.headers.set('Cross-Origin-Resource-Policy', 'cross-origin');
  }

  Future<void> _handleRequest(HttpRequest req) async {
    // Allow dynamic target override via X-Hospital-Target header if user changes Server URL
    final overrideTarget = req.headers.value('x-hospital-target');
    final cleanTarget = (overrideTarget != null && overrideTarget.trim().isNotEmpty)
        ? overrideTarget.trim().replaceAll(RegExp(r'/+$'), '')
        : targetOrigin.replaceAll(RegExp(r'/+$'), '');

    if (req.method.toUpperCase() == 'OPTIONS') {
      _applyCorsHeaders(req, req.response);
      req.response.statusCode = HttpStatus.noContent;
      await req.response.close();
      return;
    }

    // Handle Socket.IO WebSocket upgrade requests
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      await _proxyWebSocket(req, cleanTarget);
      return;
    }

    final targetBaseUri = Uri.parse(cleanTarget);
    final upstreamUri = Uri(
      scheme: targetBaseUri.scheme,
      host: targetBaseUri.host,
      port: targetBaseUri.hasPort ? targetBaseUri.port : null,
      path: req.uri.path,
      query: req.uri.hasQuery ? req.uri.query : null,
    );

    try {
      final upstreamReq = await _client.openUrl(req.method, upstreamUri);
      upstreamReq.followRedirects = true;

      // Forward safe clinical headers while stripping browser Origin/Referer/Host
      const blockedReqHeaders = <String>{
        'host',
        'origin',
        'referer',
        'connection',
        'accept-encoding',
        'content-length',
        'x-hospital-target',
      };
      req.headers.forEach((name, values) {
        if (blockedReqHeaders.contains(name.toLowerCase())) return;
        for (final v in values) {
          upstreamReq.headers.add(name, v);
        }
      });

      final bodyBytes = await req.fold<List<int>>(
        <int>[],
        (prev, chunk) => prev..addAll(chunk),
      );
      if (bodyBytes.isNotEmpty) {
        upstreamReq.contentLength = bodyBytes.length;
        upstreamReq.add(bodyBytes);
      }

      final upstreamRes = await upstreamReq.close();

      req.response.statusCode = upstreamRes.statusCode;

      const blockedResHeaders = <String>{
        'access-control-allow-origin',
        'access-control-allow-credentials',
        'access-control-allow-methods',
        'access-control-allow-headers',
        'cross-origin-resource-policy',
        'content-encoding',
        'content-length',
        'transfer-encoding',
      };
      upstreamRes.headers.forEach((name, values) {
        if (blockedResHeaders.contains(name.toLowerCase())) return;
        for (final v in values) {
          req.response.headers.add(name, v);
        }
      });

      _applyCorsHeaders(req, req.response);
      await upstreamRes.pipe(req.response);
    } catch (e) {
      _applyCorsHeaders(req, req.response);
      req.response.statusCode = HttpStatus.badGateway;
      req.response.headers.contentType = ContentType.json;
      req.response.write(
        '{"status":0,"message":"Local CORS proxy could not reach $cleanTarget: $e"}',
      );
      await req.response.close();
    }
  }

  Future<void> _proxyWebSocket(HttpRequest req, String cleanTarget) async {
    try {
      final targetBase = Uri.parse(cleanTarget);
      final wsScheme = targetBase.scheme == 'https' ? 'wss' : 'ws';
      final wsUri = Uri(
        scheme: wsScheme,
        host: targetBase.host,
        port: targetBase.hasPort ? targetBase.port : null,
        path: req.uri.path,
        query: req.uri.hasQuery ? req.uri.query : null,
      );

      final clientWs = await WebSocketTransformer.upgrade(req);
      final upstreamWs = await WebSocket.connect(wsUri.toString());

      clientWs.listen(
        (data) => upstreamWs.add(data),
        onDone: () => upstreamWs.close(),
        onError: (_) => upstreamWs.close(),
      );
      upstreamWs.listen(
        (data) => clientWs.add(data),
        onDone: () => clientWs.close(),
        onError: (_) => clientWs.close(),
      );
    } catch (_) {
      try {
        req.response.statusCode = HttpStatus.badGateway;
        await req.response.close();
      } catch (_) {}
    }
  }
}

Future<void> main(List<String> args) async {
  final target = args.isNotEmpty ? args.first : 'https://hospital.hrpocket.in';
  final port = args.length > 1 ? (int.tryParse(args[1]) ?? 8787) : 8787;

  final proxy = LocalHospitalCorsProxy(targetOrigin: target, port: port);
  await proxy.start();
  stdout.writeln(
    '[Smart Hospital CORS Proxy] Listening on http://127.0.0.1:$port -> $target',
  );
  stdout.writeln(
    '[Smart Hospital CORS Proxy] Keep this running while testing in Chrome, or run `dart run tool/run_web.dart`.',
  );
}
