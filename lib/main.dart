import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';
import 'home_page.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint('Stack:\n${details.stack}');
  };

  runZonedGuarded(
    () {
      runApp(const NrlApp());
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class NrlApp extends StatelessWidget {
  const NrlApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Take your existing themes as base
    final lightBase = AppTheme.light;
    final darkBase = AppTheme.dark;

    return MaterialApp(
      title: 'National Robotics League',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,

      theme: lightBase.copyWith(
        textTheme: GoogleFonts.interTextTheme(lightBase.textTheme),
      ),

      darkTheme: darkBase.copyWith(
        textTheme: GoogleFonts.interTextTheme(darkBase.textTheme),
      ),

      home: const HomePage(),
    );
  }
}
