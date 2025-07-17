import 'package:apk/screens/config_api_screen.dart';
import 'package:flutter/material.dart';
import 'package:apk/screens/menu_screen.dart';
import 'package:apk/screens/admin_screen.dart';
import 'package:apk/screens/select_court_screen.dart';
import 'package:apk/screens/scoreboard_screen.dart';

void main() {
  runApp(const PadelApp());
}

class PadelApp extends StatelessWidget {
  const PadelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pádel Pro Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/',
      // En tu PadelApp, agrega esta ruta:
      routes: {
        '/': (context) => const MenuScreen(),
        '/select-court': (context) => const SelectCourtScreen(),
        '/scoreboard': (context) {
          final courtId = ModalRoute.of(context)!.settings.arguments as int;
          return ScoreboardScreen(courtId: courtId);
        },
        '/admin': (context) => const AdminScreen(),
        '/config-api': (context) => const ConfigApiScreen(), // Nueva ruta
      },
    );
  }
}
