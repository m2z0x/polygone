import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oreon/screens/chat_page/chat_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class StableNearbyContactsScreen extends StatefulWidget {
  const StableNearbyContactsScreen({super.key});

  @override
  State<StableNearbyContactsScreen> createState() => _StableNearbyContactsScreenState();
}

class _StableNearbyContactsScreenState extends State<StableNearbyContactsScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _isConnecting = false;
  List<Map<String, dynamic>> _nearbyContacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];

  late AnimationController _radarController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Use localhost for emulator, 10.0.0.2 for physical device connected to same network
  static const String _wsUrl = 'ws://10.0.0.2:8000/ws/nearby';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 6;
  static const Duration _baseReconnectDelay = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _stopScanning();
    _radarController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _filterContacts);
  }

  void _startScanning() {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _nearbyContacts.clear();
      _filteredContacts.clear();
      _reconnectAttempts = 0;
    });

    _radarController.repeat();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    if (_channel != null) return;

    setState(() => _isConnecting = true);

    try {
      final uri = Uri.parse(_wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel!.sink.add(jsonEncode({
        "action": "start_scan",
        "userId": "android_user_${DateTime.now().millisecondsSinceEpoch}",
        "durationSeconds": 45,
      }));

      _subscription = _channel!.stream.listen(
        (dynamic rawMessage) {
          if (!mounted) return;

          String text;
          if (rawMessage is String) {
            text = rawMessage;
          } else if (rawMessage is List<int>) {
            text = utf8.decode(rawMessage);
          } else {
            debugPrint("Unsupported message type: ${rawMessage.runtimeType}");
            return;
          }

          try {
            final decoded = jsonDecode(text) as Map<String, dynamic>;

            switch (decoded['type']) {
              case 'user_found':
                final user = decoded['data'] as Map<String, dynamic>?;
                if (user == null) return;

                final distance = (user['distanceMeters'] as num?)?.toDouble() ?? 9999.0;

                setState(() {
                  if (!_nearbyContacts.any((c) => c['id'] == user['id'])) {
                    _nearbyContacts.add({
                      'id': user['id'],
                      'name': user['name'] ?? 'Unknown',
                      'dist': _formatDistance(distance),
                      'rawDistance': distance,
                      'type': user['connectionType'] ?? 'WiFi',
                      'strength': _getStrengthFromDistance(distance),
                      'avatarUrl': user['avatarUrl'],
                      'timestamp': DateTime.now(),
                    });
                    _sortContacts();
                    _filteredContacts = List.from(_nearbyContacts);
                  }
                });

                if (distance < 20) {
                  HapticFeedback.lightImpact();
                }
                break;

              case 'scan_complete':
                _stopScanning(auto: true);
                break;

              case 'error':
                final msg = decoded['message'] as String? ?? 'Scan error';
                if (mounted) {
                  _showSnackBar(msg, isError: true);
                }
                _stopScanning();
                break;
            }
          } catch (e, st) {
            debugPrint("Parse error: $e\n$st");
          }
        },
        onError: (error) {
          debugPrint("WebSocket error: $error");
          _handleDisconnect();
        },
        onDone: () {
          debugPrint("WebSocket closed");
          _handleDisconnect();
        },
      );

      setState(() => _isConnecting = false);
    } catch (e) {
      debugPrint("Connect failed: $e");
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    setState(() => _isConnecting = false);

    if (_isScanning && _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final multiplier = (1 << (_reconnectAttempts - 1)).clamp(1, 8);
      final delay = _baseReconnectDelay * multiplier;

      debugPrint("Reconnect attempt #$_reconnectAttempts in ${delay.inSeconds}s");

      _reconnectTimer = Timer(delay, () {
        if (mounted && _isScanning) {
          _connectWebSocket();
        }
      });
    } else if (_isScanning) {
      _stopScanning();
      if (mounted) {
        _showSnackBar('Connection lost. Tap radar to retry.', isError: true);
      }
    }
  }

  void _stopScanning({bool auto = false}) {
    if (!_isScanning) return;

    _subscription?.cancel();
    _channel?.sink.add(jsonEncode({"action": "stop_scan"}));
    _channel?.sink.close();
    _channel = null;
    _reconnectTimer?.cancel();

    _radarController.stop();
    _radarController.reset();

    if (mounted) {
      setState(() {
        _isScanning = false;
        _isConnecting = false;
      });

      if (auto) {
        _showSnackBar('Scan finished • Found ${_nearbyContacts.length} contacts');
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: isError 
            ? Colors.red.withOpacity(0.9) 
            : Colors.teal.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleScanning() {
    HapticFeedback.mediumImpact();
    _isScanning ? _stopScanning() : _startScanning();
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _getStrengthFromDistance(double distance) {
    if (distance < 15) return 'strong';
    if (distance < 40) return 'medium';
    return 'weak';
  }

  void _sortContacts() {
    _nearbyContacts.sort((a, b) {
      final da = a['rawDistance'] as double? ?? 9999.0;
      final db = b['rawDistance'] as double? ?? 9999.0;
      return da.compareTo(db);
    });
  }

  void _filterContacts() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredContacts = query.isEmpty
          ? List.from(_nearbyContacts)
          : _nearbyContacts
              .where((c) => (c['name'] as String).toLowerCase().contains(query))
              .toList();
    });
  }

  IconData _getSignalIcon(String strength) {
    return switch (strength) {
      'strong' => Icons.wifi_rounded,
      'medium' => Icons.wifi_2_bar_rounded,
      _ => Icons.wifi_1_bar_rounded,
    };
  }

  Color _getSignalColor(String strength) {
    return switch (strength) {
      'strong' => const Color(0xFF4CAF50),
      'medium' => const Color(0xFFFFA726),
      _ => const Color(0xFFEF5350),
    };
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 10) return 'now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Nearby',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 26,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_isConnecting)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.tealAccent.withOpacity(0.8)),
                ),
              ),
            ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                _isScanning ? Icons.stop_circle_rounded : Icons.radar_rounded,
                key: ValueKey(_isScanning),
                color: _isScanning ? Colors.redAccent : Colors.tealAccent,
                size: 32,
              ),
            ),
            onPressed: _toggleScanning,
            tooltip: _isScanning ? 'Stop Scanning' : 'Start Scanning',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_isScanning) {
            _stopScanning();
            await Future.delayed(const Duration(milliseconds: 500));
          }
          _startScanning();
        },
        color: Colors.tealAccent,
        backgroundColor: const Color(0xFF1A1D24),
        strokeWidth: 3,
        child: Stack(
          children: [
            const RepaintBoundary(child: _StaticBackgroundGlow()),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildStatusCard(),
                  if (_nearbyContacts.isNotEmpty) _buildSearchBar(),
                  Expanded(
                    child: _filteredContacts.isEmpty 
                        ? _buildEmptyState() 
                        : _buildContactList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_isScanning ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(_isScanning ? 0.15 : 0.08),
          width: 1.5,
        ),
        boxShadow: _isScanning
            ? [
                BoxShadow(
                  color: Colors.tealAccent.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: RadarPainter(_radarController, _isScanning),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _isScanning ? Colors.tealAccent : Colors.grey[600],
                    shape: BoxShape.circle,
                    boxShadow: _isScanning
                        ? [
                            BoxShadow(
                              color: Colors.tealAccent.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isScanning
                        ? "Scanning..."
                        : _isConnecting
                            ? "Connecting..."
                            : "Ready",
                    key: ValueKey(_isScanning),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isScanning
                        ? "${_nearbyContacts.length} contacts found"
                        : _isConnecting
                            ? "Establishing connection..."
                            : "Tap radar to discover",
                    key: ValueKey('$_isScanning-${_nearbyContacts.length}'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search by name...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.tealAccent.withOpacity(0.7)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.white60),
                  onPressed: () {
                    _searchController.clear();
                    HapticFeedback.lightImpact();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.tealAccent.withOpacity(0.5), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildContactList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final avatarUrl = contact['avatarUrl'] as String?;
        final timeAgo = _getTimeAgo(contact['timestamp'] as DateTime);
        final strength = contact['strength'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatsScreen(
                      userId: contact['id'] as String,
                      avatarUrl: avatarUrl,
                    ),
                  ),
                );
              },
              splashColor: Colors.tealAccent.withOpacity(0.1),
              highlightColor: Colors.tealAccent.withOpacity(0.05),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.teal.withOpacity(0.3),
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Text(
                                (contact['name'] as String)[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _getSignalColor(strength),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0D0F14),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getSignalIcon(strength),
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    contact['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.tealAccent.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${contact['dist']} • ${contact['type']}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.3),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Icon(
                _isScanning
                    ? Icons.radar_rounded
                    : _isConnecting
                        ? Icons.sync_rounded
                        : _searchController.text.trim().isEmpty
                            ? Icons.people_outline_rounded
                            : Icons.search_off_rounded,
                key: ValueKey('$_isScanning-$_isConnecting-${_searchController.text}'),
                size: 100,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isScanning
                    ? "Searching nearby..."
                    : _isConnecting
                        ? "Connecting..."
                        : _searchController.text.trim().isEmpty
                            ? "No contacts yet"
                            : "No matches found",
                key: ValueKey('$_isScanning-$_isConnecting-${_searchController.text}'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isScanning
                    ? "Stay in the area for best results"
                    : _isConnecting
                        ? "Please wait while we connect..."
                        : _searchController.text.trim().isEmpty
                            ? "Pull to refresh or tap the radar\nto start discovering"
                            : "Try searching for a different name",
                key: ValueKey('desc-$_isScanning-$_isConnecting-${_searchController.text}'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isScanning;

  RadarPainter(this.animation, this.isScanning) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 8;

    // Draw static rings
    final ringPaint = Paint()
      ..color = Colors.tealAccent.withOpacity(isScanning ? 0.15 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, maxRadius * 0.35, ringPaint);
    canvas.drawCircle(center, maxRadius * 0.65, ringPaint);
    canvas.drawCircle(center, maxRadius * 0.90, ringPaint);

    if (!isScanning) return;

    // Animated sweep
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.tealAccent.withOpacity(0.5),
          Colors.tealAccent.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    final sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: maxRadius),
        -1.57 + (animation.value * 6.28),
        1.2,
        false,
      )
      ..close();

    canvas.drawPath(sweepPath, sweepPaint);

    // Pulse effect
    final pulsePaint = Paint()
      ..color = Colors.tealAccent.withOpacity(0.3 * (1 - animation.value))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, maxRadius * 0.85 * animation.value, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return isScanning != oldDelegate.isScanning || 
           animation.value != oldDelegate.animation.value;
  }
}

class _StaticBackgroundGlow extends StatelessWidget {
  const _StaticBackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -200,
      left: -200,
      child: IgnorePointer(
        child: Container(
          width: 600,
          height: 600,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.teal.withOpacity(0.08),
                Colors.transparent,
              ],
              stops: const [0.0, 0.75],
            ),
          ),
        ),
      ),
    );
  }
}