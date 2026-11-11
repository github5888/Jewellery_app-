import 'dart:io';

import 'cors_proxy.dart';

/// Single-command Flutter Chrome launcher with automatic local CORS bridge:
///   dart run tool/run_web.dart
Future<void> main(List<String> args) async {
  const proxyPort = 8787;
  const targetUrl = 'https://hospital.hrpocket.in';

  final proxy = LocalHospitalCorsProxy(
    targetOrigin: targetUrl,
    port: proxyPort,
  );
  await proxy.start();
  stdout.writeln(
    '✓ Local Hospital CORS Bridge active: http://127.0.0.1:$proxyPort -> $targetUrl',
  );
  stdout.writeln('✓ Launching Flutter Nurse Portal in Chrome...');

  final flutterExecutable = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final process = await Process.start(
    flutterExecutable,
    <String>[
      'run',
      '-d',
      'chrome',
      ...args,
    ],
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );

  final exitCode = await process.exitCode;
  await proxy.stop();
  exit(exitCode);
}
