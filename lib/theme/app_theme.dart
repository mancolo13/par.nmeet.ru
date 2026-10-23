import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Parimatch Signature Colors
  static const Color primary = Color(0xFFF8FF13); // Electric Volt / Parimatch Neon Yellow
  static const Color primaryDark = Color(0xFFDCE200); // Darker Electric Yellow
  static const Color secondary = Color(0xFF00E676); // Electric Mint / Lime Green
  static const Color accentPurple = Color(0xFFA855F7); // Neon Purple
  static const Color accentGold = Color(0xFFF8FF13); // Yellow / Gold Accent
  static const Color accentRose = Color(0xFFFF2D55); // Intense Red
  static const Color accentOrange = Color(0xFFFF9100); // Energetic Orange

  // Background Surfaces (Deep Pitch Black & Carbon Slate)
  static const Color background = Color(0xFF0C0D0F); // Parimatch Pitch Black
  static const Color surface = Color(0xFF16181D); // Carbon Graphite Surface
  static const Color surfaceCard = Color(0xFF1F222A); // Elevated Dark Card
  static const Color surfaceBorder = Color(0xFF2C303B); // Subtle Dark Border

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure White
  static const Color textSecondary = Color(0xFF9EACB9); // Silver Gray
  static const Color textMuted = Color(0xFF656D7A); // Muted Graphite

  // Box Shadows
  static List<BoxShadow> get neonGlow => [
        BoxShadow(
          color: primary.withAlpha(70),
          blurRadius: 18,
          spreadRadius: 2,
        ),
      ];

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: accentRose,
        onPrimary: Color(0xFF0C0D0F),
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF0C0D0F),
          elevation: 0,
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: primary),
      ),
    );
  }
}
