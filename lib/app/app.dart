import 'package:flutter/material.dart';

import '../features/auth/screens/splash_screen.dart';
import 'theme.dart';

class CareLinkApp extends StatelessWidget {
  const CareLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareLink',
      debugShowCheckedModeBanner: false,
      theme: CareLinkTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}