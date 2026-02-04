import 'package:flutter/material.dart';
import '../../models/chat_model.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Chat chat;

  const ChatAppBar({
    super.key,
    required this.chat,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _getConnectionTypeText(ConnectionType type) {
    return switch (type) {
      ConnectionType.bluetooth => 'Nearby • Bluetooth',
      ConnectionType.wifi => 'Local • WiFi Direct',
      ConnectionType.centralized => 'Online • Server',
      ConnectionType.decentralized => 'P2P • Decentralized',
      _ => 'Online',
    };
  }

  Color _getConnectionColor(ConnectionType type) {
    return switch (type) {
      ConnectionType.bluetooth || ConnectionType.wifi => Colors.tealAccent.withOpacity(0.9),
      _ => Colors.white.withOpacity(0.6),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.teal.withOpacity(0.2),
            child: Text(
              chat.avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  chat.contactName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _getConnectionTypeText(chat.connectionType),
                  style: TextStyle(
                    color: _getConnectionColor(chat.connectionType),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: const [
        IconButton(
          icon: Icon(Icons.videocam_outlined, color: Colors.white70),
          onPressed: null, // Replace with your video call logic
        ),
        IconButton(
          icon: Icon(Icons.call_outlined, color: Colors.white70),
          onPressed: null, // Replace with your voice call logic
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.white70),
          onPressed: null, // Replace with menu logic
        ),
        SizedBox(width: 8),
      ],
    );
  }
}