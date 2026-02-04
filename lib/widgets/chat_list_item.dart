import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this. chat,
    required this.onTap,
  });

  IconData _getConnectionIcon() {
    switch (chat.connectionType) {
      case ConnectionType.wifi:
        return Icons. wifi;
      case ConnectionType. bluetooth:
        return Icons.bluetooth;
      case ConnectionType.centralized:
        return Icons.cloud;
      case ConnectionType.decentralized:
        return Icons. hub;
    }
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(chat.timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              chat.avatarText,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child:  Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color:  Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getConnectionIcon(),
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      title: Text(
        chat.contactName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTimestamp(),
            style: TextStyle(
              color: chat.unreadCount > 0 ? Colors.white : Colors.grey,
              fontSize: 12,
            ),
          ),
          if (chat.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color:  Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}