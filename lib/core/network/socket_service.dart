import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import '../utils/json_parsers.dart';

class RealtimeClinicalEvent {
  final String eventName;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  const RealtimeClinicalEvent({
    required this.eventName,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.payload,
  });
}

/// Real-Time Socket.IO client connecting to backend `initRealtimeService`
/// and listening for live ward nursing events:
/// - `ipd:new_admission`
/// - `ipd:vitals_recorded`
/// - `ipd:medication_administered`
class SocketService {
  io.Socket? _socket;
  bool _connected = false;

  bool get isConnected => _connected;

  void Function(bool connected)? onConnectionChanged;
  void Function(RealtimeClinicalEvent event)? onClinicalEvent;

  void connect({
    required String baseUrl,
    required String token,
    String? hospitalId,
  }) {
    disconnect();
    final normalizedUrl = AppConfig.effectiveTransportBaseUrl(baseUrl);
    if (token.trim().isEmpty) return;

    final options = <String, dynamic>{
      'transports': <String>['websocket', 'polling'],
      'autoConnect': false,
      'forceNew': true,
      'reconnection': true,
      'reconnectionAttempts': 12,
      'reconnectionDelay': 2500,
      'auth': <String, dynamic>{
        'token': token,
        if (hospitalId != null && hospitalId.isNotEmpty) 'hospital': hospitalId,
      },
      'query': <String, dynamic>{
        'token': token,
        if (hospitalId != null && hospitalId.isNotEmpty) 'hospital': hospitalId,
      },
      if (!kIsWeb)
        'extraHeaders': <String, dynamic>{
          'Authorization': 'Bearer $token',
        },
    };

    final socket = io.io(normalizedUrl, options);
    _socket = socket;

    socket.onConnect((_) {
      _connected = true;
      onConnectionChanged?.call(true);
    });

    socket.onDisconnect((_) {
      _connected = false;
      onConnectionChanged?.call(false);
    });

    socket.onConnectError((_) {
      _connected = false;
      onConnectionChanged?.call(false);
    });

    // 1. Ward New Admission Live Alert
    socket.on('ipd:new_admission', (raw) {
      final map = JsonParsers.asMap(raw);
      final patientName = JsonParsers.asString(
        map['patient_name'] ?? map['patient'],
        fallback: 'New IPD Patient',
      );
      final bed = JsonParsers.asString(
        map['bed'] ?? map['bed_name'],
        fallback: 'Ward',
      );
      onClinicalEvent?.call(
        RealtimeClinicalEvent(
          eventName: 'ipd:new_admission',
          title: 'New Ward Admission',
          subtitle: '$patientName admitted to $bed',
          timestamp: DateTime.now(),
          payload: map,
        ),
      );
    });

    // 2. Bedside Vitals Recorded Live Alert
    socket.on('ipd:vitals_recorded', (raw) {
      final map = JsonParsers.asMap(raw);
      final patientName = JsonParsers.asString(
        map['patient_name'] ?? map['patient'],
        fallback: 'Ward Patient',
      );
      final bp = JsonParsers.asString(map['bp']);
      final spo2 = JsonParsers.asString(map['spo2']);
      final summaryParts = <String>[
        if (bp.isNotEmpty) 'BP $bp',
        if (spo2.isNotEmpty) 'SpO2 $spo2%',
      ];
      onClinicalEvent?.call(
        RealtimeClinicalEvent(
          eventName: 'ipd:vitals_recorded',
          title: 'Vitals Updated • $patientName',
          subtitle: summaryParts.isEmpty
              ? 'Bedside vitals logged in chart'
              : summaryParts.join(' • '),
          timestamp: DateTime.now(),
          payload: map,
        ),
      );
    });

    // 3. Medication Administration Record (MAR) Live Alert
    socket.on('ipd:medication_administered', (raw) {
      final map = JsonParsers.asMap(raw);
      final med = JsonParsers.asString(
        map['medicine_name'] ?? map['medicine'],
        fallback: 'Medication',
      );
      final status = JsonParsers.asString(map['status'], fallback: 'Given');
      final patientName = JsonParsers.asString(map['patient_name']);
      onClinicalEvent?.call(
        RealtimeClinicalEvent(
          eventName: 'ipd:medication_administered',
          title: 'MAR Dose $status',
          subtitle: patientName.isNotEmpty ? '$med • $patientName' : med,
          timestamp: DateTime.now(),
          payload: map,
        ),
      );
    });

    socket.connect();
  }

  void disconnect() {
    final existing = _socket;
    _socket = null;
    _connected = false;
    if (existing != null) {
      try {
        existing.clearListeners();
        existing.disconnect();
        existing.dispose();
      } catch (_) {}
    }
    onConnectionChanged?.call(false);
  }
}
