import 'chat_model.dart';

class NearbyContact {
  final String id;
  final String name;
  final String distance;
  final ConnectionType connectionType;
  final String avatarText;

  NearbyContact({
    required this. id,
    required this.name,
    required this.distance,
    required this.connectionType,
    required this.avatarText,
  });
}

class User {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? status;

  User({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isOnline,
    this.lastSeen,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'status': status,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
      status: json['status'],
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
    );
  }
}