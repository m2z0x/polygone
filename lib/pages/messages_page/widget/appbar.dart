import 'dart:ffi';

import 'package:flutter/material.dart';
import  'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:polygone_app/pages/const/const.dart';


class MessagesAppBar extends StatefulWidget {
  const MessagesAppBar({super.key});

  @override
  State<MessagesAppBar> createState() => _MessagesAppBarState();
}

class _MessagesAppBarState extends State<MessagesAppBar> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AppBar(
        
        title: Text('Messages',style: TextStyle(fontFamily: 'RobotoMono')),
        actions: [
            IconButton(
            icon: Icon(LucideIcons.wifi400,color: isWifiOn ? Colors.lightGreen : Colors.grey),
            tooltip: "Wi-Fi",
            onPressed: () {
              setState(() {
                isWifiOn = !isWifiOn;
              });
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.bluetooth400,color: isBluetoothOn ? Colors.lightBlue : Colors.grey),
            tooltip: "Bluetooth",
            onPressed: () {
              setState(() {
                isBluetoothOn = !isBluetoothOn;
              });
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.settings400,color: Colors.grey),
            tooltip: "Settings",
            onPressed: () {
              // Add your settings logic here
            },
          ),
        ],
      ),
    );
  }
}