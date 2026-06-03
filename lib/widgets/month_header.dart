import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/formatters.dart';

class MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthHeader({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OriaTheme.cardBorder),
      ),
      child: Row(
        children: [
          _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Fechamento',
                  style: TextStyle(
                    color: OriaTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  monthLabel(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: OriaTheme.text,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: OriaTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: OriaTheme.blueDark, size: 24),
      ),
    );
  }
}
