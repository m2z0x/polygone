import 'package:flutter/material.dart';
import 'package:polygone_app/pages/messages_page/messages.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polygone App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF2c666e, {
          50: Color(0xFFE1F0F2),
          100: Color(0xFFB3D8DD),
          200: Color(0xFF80BDC5),
          300: Color(0xFF4D9FAA),
          400: Color(0xFF267E93),
          500: Color(0xFF006680),
          600: Color(0xFF005C73),
          700: Color(0xFF004F63),
          800: Color(0xFF004255),
          900: Color(0xFF002F3E),
        }),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF006680),
          secondary: Color(0xFF267E93),
        ),
      ),
      home: const Messages()
    );
  }
}