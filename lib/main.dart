import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite FFI for Windows/Linux/macOS desktop support
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Check login session
  final bool isLoggedIn = await DatabaseHelper.instance.isLoggedIn();
  final String? loggedInUsername = await DatabaseHelper.instance.getSessionUsername();

  runApp(SpaceNewsApp(
    initialIsLoggedIn: isLoggedIn && loggedInUsername != null,
    initialUsername: loggedInUsername,
  ));
}

class SpaceNewsApp extends StatelessWidget {
  final bool initialIsLoggedIn;
  final String? initialUsername;

  const SpaceNewsApp({
    super.key,
    required this.initialIsLoggedIn,
    this.initialUsername,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpaceNews Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF0284C7),
          surface: Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: initialIsLoggedIn && initialUsername != null
          ? HomeScreen(username: initialUsername!)
          : const LoginScreen(),
    );
  }
}
