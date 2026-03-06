import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ──────────────────────────────────────────
  // Brand Colors
  // ──────────────────────────────────────────
  static const Color primary = Color(0xFF4F46E5); // Indigo
  static const Color secondary = Color(0xFF6366F1);
  static const Color primaryColor = primary; // alias for legacy refs

  // Priority Colors
  static const Color lowPriority = Color(0xFF10B981); // Green
  static const Color mediumPriority = Color(0xFFF59E0B); // Orange
  static const Color highPriority = Color(0xFFEF4444); // Red
  static const Color urgentPriority = Color(0xFF8B5CF6); // Purple

  // Light Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightSubText = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark Palette
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkSubText = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // ──────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────
  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return lowPriority;
      case 'high':
        return highPriority;
      case 'urgent':
        return urgentPriority;
      case 'medium':
      default:
        return mediumPriority;
    }
  }

  static String priorityEmoji(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return '🟢';
      case 'high':
        return '🔴';
      case 'urgent':
        return '🟣';
      default:
        return '🟠';
    }
  }

  static IconData priorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Icons.keyboard_double_arrow_down_rounded;
      case 'high':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'urgent':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.drag_handle_rounded;
    }
  }

  // ──────────────────────────────────────────
  // Light Theme
  // ──────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = _baseTextTheme(lightText, lightSubText);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(primary: primary, secondary: secondary, surface: lightCard),
      textTheme: base,
      cardColor: lightCard,
      dividerColor: lightBorder,
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: lightText),
        titleTextStyle: GoogleFonts.inter(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: _elevatedBtnTheme(primary),
      inputDecorationTheme: _inputTheme(lightCard, lightBorder, lightSubText),
      chipTheme: _chipTheme(primary),
    );
  }

  // ──────────────────────────────────────────
  // Dark Theme
  // ──────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = _baseTextTheme(darkText, darkSubText);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: secondary,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: secondary,
        brightness: Brightness.dark,
      ).copyWith(primary: secondary, secondary: primary, surface: darkCard),
      textTheme: base,
      cardColor: darkCard,
      dividerColor: darkBorder,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkText),
        titleTextStyle: GoogleFonts.inter(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: _elevatedBtnTheme(secondary),
      inputDecorationTheme: _inputTheme(darkCard, darkBorder, darkSubText),
      chipTheme: _chipTheme(secondary),
    );
  }

  // ──────────────────────────────────────────
  // Shared builders
  // ──────────────────────────────────────────
  static TextTheme _baseTextTheme(Color text, Color sub) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        color: text,
        fontWeight: FontWeight.w800,
        fontSize: 32,
      ),
      displayMedium: GoogleFonts.inter(
        color: text,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      displaySmall: GoogleFonts.inter(
        color: text,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      headlineMedium: GoogleFonts.inter(
        color: text,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      headlineSmall: GoogleFonts.inter(
        color: text,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleLarge: GoogleFonts.inter(
        color: text,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      titleMedium: GoogleFonts.inter(
        color: text,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodyLarge: GoogleFonts.inter(
        color: text,
        fontWeight: FontWeight.w400,
        fontSize: 15,
      ),
      bodyMedium: GoogleFonts.inter(
        color: sub,
        fontWeight: FontWeight.w400,
        fontSize: 13,
      ),
      bodySmall: GoogleFonts.inter(
        color: sub,
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
      labelLarge: GoogleFonts.inter(
        color: text,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedBtnTheme(
    Color color,
  ) => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );

  static InputDecorationTheme _inputTheme(
    Color fill,
    Color border,
    Color hint,
  ) => InputDecorationTheme(
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    hintStyle: GoogleFonts.inter(color: hint, fontWeight: FontWeight.w400),
  );

  static ChipThemeData _chipTheme(Color color) => ChipThemeData(
    selectedColor: color,
    backgroundColor: Colors.transparent,
    labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );
}
