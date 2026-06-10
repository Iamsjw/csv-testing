import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Core Colors ───────────────────────────────────────────────
  static const Color background = Color(0xFF1C1F3A); // Deep indigo/navy
  static const Color backgroundVariant = Color(0xFF252A4A); // Slightly lighter
  static const Color surface = Color(0xFF1E2240); // Surface - very low contrast
  static const Color surfaceVariant = Color(0xFF22264A); // Elevated surface
  static const Color surfaceRaised = Color(0xFF262B52); // Raised elements

  // ─── Primary & Accent Colors ────────────────────────────────────
  static const Color primary = primaryBlue; // Alias for electric blue
  static const Color primaryBlue = Color(0xFF6C63FF); // Electric blue
  static const Color primaryCyan = Color(0xFF22D3EE); // Cyan
  static const Color primaryGreen = Color(0xFF22C55E); // Green
  static const Color softGlow = Color(0x3322D3EE); // Soft blue glow

  // ─── Text Colors ─────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFF94A3B8); // Muted gray-blue
  static const Color textMuted = Color(0xFF64748B); // More muted
  static const Color textDisabled = Color(0xFF475569); // Disabled

  // ─── Status Colors ────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color(0x3322C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0x33F59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSoft = Color(0x33EF4444);

  // ─── Neumorphic Shadows ─────────────────────────────────────
  static const Color shadowDark = Color(
    0x66101220,
  ); // Dark shadow (bottom-right)
  static const Color shadowLight = Color(0x1AFFFFFF); // Light shadow (top-left)

  // ─── Gradients ──────────────────────────────────────────────
  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryCyan, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient surfaceGradient = RadialGradient(
    center: Alignment(-0.8, -0.6),
    radius: 1.2,
    colors: [Color(0x0D22D3EE), Colors.transparent],
  );

  // ─── Neumorphic Decorations ─────────────────────────────────────
  static BoxDecoration neumorphic({
    BorderRadiusGeometry? borderRadius,
    bool isRaised = false,
  }) {
    return BoxDecoration(
      color: isRaised ? surfaceRaised : surface,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      boxShadow: [
        // Dark shadow (bottom-right)
        BoxShadow(
          color: shadowDark,
          offset: const Offset(4, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
        // Light shadow (top-left)
        BoxShadow(
          color: shadowLight,
          offset: const Offset(-4, -4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ],
    );
  }

  static BoxDecoration neumorphicGlow({
    BorderRadiusGeometry? borderRadius,
    Color glowColor = primaryCyan,
  }) {
    return BoxDecoration(
      color: surface,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: shadowDark,
          offset: const Offset(4, 4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: shadowLight,
          offset: const Offset(-4, -4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: glowColor.withAlpha(40),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // ─── Theme Data ──────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryCyan,
      secondary: primaryBlue,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      outline: shadowLight,
    ),
    scaffoldBackgroundColor: background,
    canvasColor: background,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        displayLarge: _buildTextStyle(32, FontWeight.w700, textPrimary, -0.5),
        displayMedium: _buildTextStyle(28, FontWeight.w700, textPrimary, -0.3),
        headlineLarge: _buildTextStyle(24, FontWeight.w700, textPrimary, -0.2),
        headlineMedium: _buildTextStyle(20, FontWeight.w600, textPrimary),
        headlineSmall: _buildTextStyle(18, FontWeight.w600, textPrimary),
        titleLarge: _buildTextStyle(16, FontWeight.w600, textPrimary),
        titleMedium: _buildTextStyle(14, FontWeight.w600, textPrimary),
        titleSmall: _buildTextStyle(13, FontWeight.w600, textSecondary),
        bodyLarge: _buildTextStyle(15, FontWeight.w400, textPrimary),
        bodyMedium: _buildTextStyle(14, FontWeight.w400, textSecondary),
        bodySmall: _buildTextStyle(12, FontWeight.w400, textMuted),
        labelLarge: _buildTextStyle(14, FontWeight.w600, textPrimary, 0.2),
        labelMedium: _buildTextStyle(12, FontWeight.w600, textSecondary, 0.3),
        labelSmall: _buildTextStyle(11, FontWeight.w600, textMuted, 0.4),
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryCyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textMuted, fontSize: 14),
      hintStyle: const TextStyle(color: textDisabled, fontSize: 14),
      errorStyle: const TextStyle(color: error, fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: primaryBlue.withAlpha(80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: shadowDark,
    ),
    dividerTheme: const DividerThemeData(
      color: shadowLight,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariant,
      selectedColor: primaryBlue.withAlpha(60),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    ),
    iconTheme: const IconThemeData(color: textPrimary, size: 24),
  );

  // lightTheme required by contract - redirect to dark
  static ThemeData get lightTheme => darkTheme;

  // ─── Helper Methods ────────────────────────────────────────────
  static TextStyle _buildTextStyle(
    double fontSize,
    FontWeight fontWeight,
    Color color, [
    double letterSpacing = 0,
  ]) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // ─── Glass Morphism Effect ────────────────────────────────────
  static BoxDecoration glassMorphism({
    BorderRadiusGeometry? borderRadius,
    double opacity = 0.08,
    Color borderColor = const Color(0x1AFFFFFF),
  }) {
    return BoxDecoration(
      color: Color(0xFF1E2240).withAlpha((opacity * 255).round()),
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: shadowDark,
          offset: const Offset(4, 4),
          blurRadius: 16,
        ),
        BoxShadow(
          color: shadowLight,
          offset: const Offset(-4, -4),
          blurRadius: 16,
        ),
      ],
    );
  }

  // ─── Glow Effect ──────────────────────────────────────────────
  static BoxDecoration glowEffect({
    required Color glowColor,
    BorderRadiusGeometry? borderRadius,
    double intensity = 0.3,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: glowColor.withAlpha((intensity * 255).round()),
          blurRadius: 24,
          spreadRadius: 4,
        ),
      ],
    );
  }
}
