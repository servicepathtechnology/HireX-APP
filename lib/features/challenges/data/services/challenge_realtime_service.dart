import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../domain/entities/challenge_entities.dart';

/// Real-time events from the challenge room WebSocket.
class RoomEvent {
  const RoomEvent({required this.type, required this.data});
  final String type;
  final Map<String, dynamic> data;
}

/// Manages the WebSocket connection for a live challenge room.
/// Events: timer_start, timer_tick, opponent_submitted, match_completed,
///         connection_status, spectator_count
class ChallengeRealtimeService {
  ChallengeRealtimeService._();
  static final ChallengeRealtimeService instance = ChallengeRealtimeService._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  String? _matchId;
  String? _token;

  final _eventController = StreamController<RoomEvent>.broadcast();
  Stream<RoomEvent> get events => _eventController.stream;

  // Derived streams
  Stream<Duration> get timerStream => events
      .where((e) => e.type == 'timer_tick' || e.type == 'timer_start')
      .map((e) {
        final seconds = e.data['remaining_seconds'] as int? ?? 0;
        return Duration(seconds: seconds);
      });

  Stream<OpponentStatus> get opponentStatusStream => events
      .where((e) => e.type == 'opponent_status')
      .map((e) => OpponentStatusX.fromString(e.data['status'] as String? ?? 'waiting'));

  Stream<bool> get matchCompletedStream =>
      events.where((e) => e.type == 'match_completed').map((_) => true);

  Stream<int> get spectatorCountStream => events
      .where((e) => e.type == 'spectator_count')
      .map((e) => e.data['count'] as int? ?? 0);

  bool _connected = false;
  bool get isConnected => _connected;

  Future<void> connect(String matchId, String authToken) async {
    _matchId = matchId;
    _token = authToken;
    await _connect();
  }

  Future<void> _connect() async {
    if (_matchId == null) return;
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final wsUrl = baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final uri = Uri.parse('$wsUrl/ws/challenges/$_matchId?token=$_token');

      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      _connected = true;
      _eventController.add(RoomEvent(type: 'connection_status', data: {'connected': true}));
      debugPrint('[WS] Connected to match $_matchId');
    } catch (e) {
      debugPrint('[WS] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = json['type'] as String? ?? 'unknown';
      final data = json['data'] as Map<String, dynamic>? ?? {};
      _eventController.add(RoomEvent(type: type, data: data));
    } catch (e) {
      debugPrint('[WS] Parse error: $e');
    }
  }

  void _onError(dynamic error) {
    debugPrint('[WS] Error: $error');
    _connected = false;
    _eventController.add(RoomEvent(type: 'connection_status', data: {'connected': false}));
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[WS] Connection closed');
    _connected = false;
    _eventController.add(RoomEvent(type: 'connection_status', data: {'connected': false}));
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () async {
      debugPrint('[WS] Reconnecting...');
      await _connect();
    });
  }

  void sendStatus(String status) {
    if (!_connected) return;
    try {
      _channel?.sink.add(jsonEncode({'type': 'status_update', 'status': status}));
    } catch (e) {
      debugPrint('[WS] Send failed: $e');
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _connected = false;
    _matchId = null;
    _token = null;
    debugPrint('[WS] Disconnected');
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
