import 'package:flutter/material.dart';
import 'package:oreon/models/chat_model.dart';
import '../models/nearby_contact_model.dart';

class NearbyContactItem extends StatelessWidget {
  final NearbyContact contact;
  final VoidCallback onConnect;

  const NearbyContactItem({
    super.key,
    required this.contact,
    required this. onConnect,
  });

  IconData _getConnectionIcon() {
    switch (contact.connectionType) {
      case ConnectionType.wifi:
        return Icons.wifi;
      case ConnectionType.bluetooth:
        return Icons.bluetooth;
      case ConnectionType.centralized:
        return Icons.cloud;
      case ConnectionType.decentralized:
        return Icons.hub;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.white,
        child: Text(
          contact.avatarText,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        contact.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            _getConnectionIcon(),
            size: 14,
            color: Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            contact.distance,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
      trailing: OutlinedButton(
        onPressed: onConnect,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors. white),
          shape: RoundedRectangleBorder(
            borderRadius:  BorderRadius.circular(20),
          ),
        ),
        child: const Text('Connect'),
      ),
    );
  }
}