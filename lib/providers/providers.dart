import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _userName = 'User Name';
  String _userBio = 'No bio yet';
  String _userEmail = 'user@example.com';
  String _userPhone = '+1234567890';
  String _userSeed = '';
  File ? _avatarPicture;

  // Getters
  String get userName => _userName;
  String get userBio => _userBio;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get userSeed => _userSeed;
  File ? get avatarPicture => _avatarPicture;

  // Load data from SharedPreferences
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'User Name';
    _userBio = prefs.getString('user_bio') ?? 'No bio yet';
    _userEmail = prefs.getString('user_email') ?? 'user@example.com';
    _userPhone = prefs.getString('user_phone') ?? '+1234567890';
    _userSeed = prefs.getString('user_seed') ?? '';
    notifyListeners();
  }

  // Update all user data at once
  Future<void> updateUserData({
    required String name,
    required String bio,
    required String email,
    required String phone,
    String? avatarPicture,
    
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    _userName = name;
    _userBio = bio;
    _userEmail = email;
    _userPhone = phone;
    _avatarPicture = avatarPicture != null ? File(avatarPicture) : null;

    await prefs.setString('user_name', name);
    await prefs.setString('user_bio', bio);
    await prefs.setString('user_email', email);
    await prefs.setString('user_phone', phone);
    await prefs.setString('avatar_picture', _avatarPicture?.path ?? '');
    notifyListeners();
  }

  // Update individual fields
  Future<void> updateUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    _userName = name;
    await prefs.setString('user_name', name);
    notifyListeners();
  }

  Future<void> updateUserBio(String bio) async {
    final prefs = await SharedPreferences.getInstance();
    _userBio = bio;
    await prefs.setString('user_bio', bio);
    notifyListeners();
  }

  Future<void> updateAvatarPicture(String path) async {
    final prefs = await SharedPreferences.getInstance();
    _avatarPicture = File(path);
    await prefs.setString('avatar_picture', path);
    notifyListeners();
  }
}

class SettingsProvider extends ChangeNotifier {
  bool _bluetoothEnabled = true;
  bool _wifiEnabled = true;
  bool _notificationsEnabled = true;
  bool _autoConnect = false;

  // Getters
  bool get bluetoothEnabled => _bluetoothEnabled;
  bool get wifiEnabled => _wifiEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoConnect => _autoConnect;

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _bluetoothEnabled = prefs.getBool('bluetooth_enabled') ?? true;
    _wifiEnabled = prefs.getBool('wifi_enabled') ?? true;
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _autoConnect = prefs.getBool('auto_connect') ?? false;
    notifyListeners();
  }

  // Toggle methods
  Future<void> toggleBluetooth(bool value) async {
    _bluetoothEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bluetooth_enabled', value);
    notifyListeners();
  }

  Future<void> toggleWifi(bool value) async {
    _wifiEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wifi_enabled', value);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<void> toggleAutoConnect(bool value) async {
    _autoConnect = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_connect', value);
    notifyListeners();
  }
}