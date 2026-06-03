import 'package:flutter/material.dart';

import '../app/theme.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final bool highlight;
  final bool danger;
  final bool success;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.highlight = false,
    this.danger = false,
    this.success = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = danger ? OriaTheme.danger : (success ? OriaTheme.success : (highlight ? Colors.white : OriaTheme.text));
    final iconColor = danger ? OriaTheme.danger : (success ? OriaTheme.success : OriaTheme.blue);

    final card = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 185 || constraints.maxHeight < 198;
        final padding = compact ? 15.0 : 17.0;
        final iconBox = compact ? 48.0 : 52.0;
        final iconRadius = compact ? 16.0 : 18.0;
        final iconToTitleGap = compact ? 12.0 : 14.0;
        final titleToValueGap = compact ? 7.0 : 8.0;
        final valueToSubtitleGap = compact ? 7.0 : 8.0;
        final titleSize = compact ? 13.0 : 14.0;
        final valueSize = compact ? 33.0 : 36.0;
        final subtitleSize = compact ? 11.0 : 12.0;
        final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            gradient: highlight
                ? const LinearGradient(
                    colors: [OriaTheme.blue, OriaTheme.blueDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: highlight ? null : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: highlight ? null : Border.all(color: OriaTheme.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: OriaTheme.shadow,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: iconBox,
                      height: iconBox,
                      decoration: BoxDecoration(
                        color: highlight ? Colors.white.withValues(alpha: 0.16) : OriaTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(iconRadius),
                      ),
                      child: Icon(icon, color: highlight ? Colors.white : iconColor),
                    ),
                    const Spacer(),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: highlight ? Colors.white70 : OriaTheme.muted,
                      ),
                  ],
                ),
                SizedBox(height: iconToTitleGap),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: highlight ? Colors.white70 : OriaTheme.muted,
                    fontWeight: FontWeight.w900,
                    fontSize: titleSize,
                  ),
                ),
                SizedBox(height: titleToValueGap),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w900,
                      color: valueColor,
                      letterSpacing: -0.9,
                    ),
                  ),
                ),
                if (hasSubtitle) ...[
                  SizedBox(height: valueToSubtitleGap),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: highlight ? Colors.white70 : OriaTheme.muted,
                      fontSize: subtitleSize,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
