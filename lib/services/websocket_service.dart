import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket service for handling nearby device scanning
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 6;
  static const Duration _baseReconnectDelay = Duration(seconds: 4);
  static const Duration _pingInterval = Duration(seconds: 15);
  
  bool _isConnected = false;
  bool _shouldReconnect = false;
  
  // Callbacks
  Function(Map<String, dynamic>)? onUserFound;
  Function()? onScanComplete;
  Function(String)? onError;
  Function(bool)? onConnectionStateChanged;
  
  String? _currentUserId;
  final String wsUrl;
  
  WebSocketService({required this.wsUrl});
  
  bool get isConnected => _isConnected;
  
  /// Connect to WebSocket server and start scanning
  Future<void> connect({required String userId, int durationSeconds = 45}) async {
    if (_isConnected) {
      debugPrint('[WebSocket] Already connected');
      return;
    }
    
    _currentUserId = userId;
    _shouldReconnect = true;
    _reconnectAttempts = 0;
    
    await _establishConnection();
    
    if (_isConnected) {
      sendMessage({
        "action": "start_scan",
        "userId": userId,
        "durationSeconds": durationSeconds,
      });
      _startPingTimer();
    }
  }
  
  Future<void> _establishConnection() async {
    try {
      debugPrint('[WebSocket] Connecting to $wsUrl');
      
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);
      
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );
      
      _isConnected = true;
      _reconnectAttempts = 0;
      onConnectionStateChanged?.call(true);
      
      debugPrint('[WebSocket] Connected successfully');
    } catch (e) {
      debugPrint('[WebSocket] Connection failed: $e');
      _isConnected = false;
      onConnectionStateChanged?.call(false);
      _handleDisconnect();
    }
  }
  
  void _handleMessage(dynamic rawMessage) {
    try {
      String text;
      if (rawMessage is String) {
        text = rawMessage;
      } else if (rawMessage is List<int>) {
        text = utf8.decode(rawMessage);
      } else {
        debugPrint('[WebSocket] Unsupported message type: ${rawMessage.runtimeType}');
        return;
      }
      
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      debugPrint('[WebSocket] Received: ${decoded['type']}');
      
      switch (decoded['type']) {
        case 'user_found':
          final userData = decoded['data'] as Map<String, dynamic>?;
          if (userData != null) {
            onUserFound?.call(userData);
          }
          break;
          
        case 'scan_complete':
          debugPrint('[WebSocket] Scan completed');
          onScanComplete?.call();
          break;
          
        case 'error':
          final errorMsg = decoded['message'] as String? ?? 'Unknown error';
          debugPrint('[WebSocket] Server error: $errorMsg');
          onError?.call(errorMsg);
          break;
          
        case 'pong':
          debugPrint('[WebSocket] Received pong');
          break;
          
        default:
          debugPrint('[WebSocket] Unknown message type: ${decoded['type']}');
      }
    } catch (e, stackTrace) {
      debugPrint('[WebSocket] Parse error: $e\n$stackTrace');
    }
  }
  
  void _handleError(dynamic error) {
    debugPrint('[WebSocket] Stream error: $error');
    _isConnected = false;
    onConnectionStateChanged?.call(false);
    _handleDisconnect();
  }
  
  void _handleDisconnect() {
    debugPrint('[WebSocket] Connection closed');
    
    _isConnected = false;
    _pingTimer?.cancel();
    onConnectionStateChanged?.call(false);
    
    _subscription?.cancel();
    _subscription = null;
    
    if (_shouldReconnect && _reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else if (_shouldReconnect) {
      debugPrint('[WebSocket] Max reconnection attempts reached');
      onError?.call('Connection lost. Please try again.');
    }
  }
  
  void _scheduleReconnect() {
    _reconnectAttempts++;
    final multiplier = (1 << (_reconnectAttempts - 1)).clamp(1, 8);
    final delay = _baseReconnectDelay * multiplier;
    
    debugPrint('[WebSocket] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (_shouldReconnect) {
        await _establishConnection();
        if (_isConnected && _currentUserId != null) {
          sendMessage({
            "action": "start_scan",
            "userId": _currentUserId!,
            "durationSeconds": 45,
          });
        }
      }
    });
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_isConnected) {
        sendMessage({"action": "ping"});
      } else {
        timer.cancel();
      }
    });
  }
  
  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      debugPrint('[WebSocket] Cannot send message - not connected');
      return;
    }
    
    try {
      final json = jsonEncode(message);
      _channel!.sink.add(json);
      debugPrint('[WebSocket] Sent: ${message['action']}');
    } catch (e) {
      debugPrint('[WebSocket] Send error: $e');
    }
  }
  
  Future<void> disconnect() async {
    debugPrint('[WebSocket] Disconnecting...');
    
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    
    if (_isConnected) {
      sendMessage({"action": "stop_scan"});
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    await _channel?.sink.close();
    _subscription?.cancel();
    
    _channel = null;
    _subscription = null;
    _isConnected = false;
    _currentUserId = null;
    
    onConnectionStateChanged?.call(false);
  }
  
  void dispose() {
    disconnect();
  }
}