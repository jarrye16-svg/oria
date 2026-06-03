import 'package:flutter/material.dart';

import '../screens/auth_gate.dart';
import 'theme.dart';

class OriaApp extends StatelessWidget {
  const OriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oria',
      debugShowCheckedModeBanner: false,
      theme: OriaTheme.light(),
      home: const AuthGate(),
    );
  }
}
