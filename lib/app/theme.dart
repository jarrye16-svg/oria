import 'package:flutter/material.dart';

class OriaTheme {
  static const blue = Color(0xFF2453D4);
  static const blueDark = Color(0xFF102B6B);
  static const blueLight = Color(0xFF4CC6F0);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F7FC);
  static const surfaceAlt = Color(0xFFEFF4FF);
  static const cardBorder = Color(0xFFE3EAF5);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const danger = Color(0xFFDC2626);
  static const success = Color(0xFF15803D);
  static const soft = Color(0xFFF8FBFF);
  static const shadow = Color(0x140F172A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.light,
      primary: blue,
      secondary: blueDark,
      surface: surface,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.1,
        ),
        headlineMedium: const TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        titleLarge: const TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: const TextStyle(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: const TextStyle(
          color: text,
          height: 1.35,
        ),
        bodySmall: const TextStyle(
          color: muted,
          height: 1.35,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: text,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceAlt,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: text),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        height: 74,
        indicatorColor: blue.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? blue : muted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? blue : muted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            fontSize: 12,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
        surfaceTintColor: Colors.white,
      ),
    );
  }
}
