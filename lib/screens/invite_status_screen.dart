import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/auth_service.dart';

class InviteStatusScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const InviteStatusScreen({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  Future<void> _logout() async {
    await AuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OriaTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: OriaTheme.cardBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: OriaTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.mark_email_unread_rounded, color: OriaTheme.blue, size: 34),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: OriaTheme.muted, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sair e entrar com outro e-mail'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
