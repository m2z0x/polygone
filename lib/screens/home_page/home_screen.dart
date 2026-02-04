import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:oreon/screens/chat_page/chat_screen.dart';
import '../nerby_page/nearby_contacts_screen.dart';
import '../settings_page/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Lazy initialization - screens created only when needed
  late final List<Widget> _screens = [
    const ChatsScreen(),
    const StableNearbyContactsScreen(),
    const SettingsScreen(),
  ];

  void _onTabChanged(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const RepaintBoundary(
            child: _StaticBackgroundGlow(),
          ),
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _CompactGlassmorphicBottomNav(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}

class _CompactGlassmorphicBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const _CompactGlassmorphicBottomNav({
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTabChanged,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            selectedItemColor: Colors.tealAccent,
            unselectedItemColor: const Color(0x99FFFFFF), // Pre-computed opacity
            iconSize: 28,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.radar_outlined),
                activeIcon: Icon(Icons.radar),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticBackgroundGlow extends StatelessWidget {
  const _StaticBackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -150,
      left: -150,
      child: IgnorePointer(
        child: SizedBox(
          width: 500,
          height: 500,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: const [
                  Color(0xFF009688), // teal color code
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
        ),
      ),
    );
  }
}