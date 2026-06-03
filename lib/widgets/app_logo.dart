import 'package:flutter/material.dart';

import '../app/theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 92,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x331D4ED8),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/oria_logo.png',
            fit: BoxFit.cover,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          const Text(
            'Oria',
            style: TextStyle(
              color: OriaTheme.blueDark,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sua casa, seu mes, seu controle.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: OriaTheme.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
