import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Palette - Rox Player (Sleek Monochrome Black & White)
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color primaryBlack = Color(0xFF09090B);
  static const Color accentEmerald = Color(0xFF10B981);

  // Dark Theme Colors (Pure Neutral Black & Charcoal - Zero Blue Tint)
  static const Color backgroundDark = Color(0xFF09090B);
  static const Color surfaceDark = Color(0xFF121215);
  static const Color cardDark = Color(0xFF1A1A1E);
  static const Color borderDark = Color(0xFF2E2E34);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFE4E4E7);
  static const Color textMutedDark = Color(0xFFA1A1AA);

  // Light Theme Colors (Pure Crisp White & High-Contrast Black Text)
  static const Color backgroundLight = Color(0xFFF4F4F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFD4D4D8);
  static const Color textPrimaryLight = Color(0xFF09090B);
  static const Color textSecondaryLight = Color(0xFF18181B);
  static const Color textMutedLight = Color(0xFF52525B);

  // Adaptive Theme Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? backgroundDark : backgroundLight;

  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLight;

  static Color card(BuildContext context) =>
      isDark(context) ? cardDark : cardLight;

  static Color border(BuildContext context) =>
      isDark(context) ? borderDark : borderLight;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textSecondaryDark : textSecondaryLight;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? textMutedDark : textMutedLight;

  /// Primary monochrome accent: Crisp White in Dark Mode, Crisp Black in Light Mode
  static Color accent(BuildContext context) =>
      isDark(context) ? primaryWhite : primaryBlack;

  /// Foreground color guaranteed to contrast cleanly on top of `accent(context)`
  static Color onAccent(BuildContext context) =>
      isDark(context) ? primaryBlack : primaryWhite;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryWhite,
      colorScheme: const ColorScheme.dark(
        primary: primaryWhite,
        onPrimary: primaryBlack,
        secondary: Color(0xFFE4E4E7),
        onSecondary: primaryBlack,
        surface: surfaceDark,
        surfaceContainerHigh: cardDark,
        onSurface: textPrimaryDark,
        outline: borderDark,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimaryDark,
        displayColor: textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimaryDark,
        ),
        iconTheme: const IconThemeData(color: textPrimaryDark),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primaryWhite,
        unselectedLabelColor: textMutedDark,
        indicatorColor: primaryWhite,
        dividerColor: borderDark,
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        modalBackgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceDark,
        textStyle: GoogleFonts.plusJakartaSans(color: textPrimaryDark, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderDark),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryWhite,
        unselectedItemColor: textSecondaryDark,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceDark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimaryDark,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textSecondaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark, width: 1),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryBlack,
      colorScheme: const ColorScheme.light(
        primary: primaryBlack,
        onPrimary: primaryWhite,
        secondary: Color(0xFF27272A),
        onSecondary: primaryWhite,
        surface: surfaceLight,
        surfaceContainerHigh: cardLight,
        onSurface: textPrimaryLight,
        outline: borderLight,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: textPrimaryLight,
        displayColor: textPrimaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimaryLight,
        ),
        iconTheme: const IconThemeData(color: textPrimaryLight),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primaryBlack,
        unselectedLabelColor: textSecondaryLight,
        indicatorColor: primaryBlack,
        dividerColor: borderLight,
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceLight,
        modalBackgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceLight,
        textStyle: GoogleFonts.plusJakartaSans(color: textPrimaryLight, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderLight),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryBlack,
        unselectedItemColor: textSecondaryLight,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardTheme(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceLight,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimaryLight,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textSecondaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
    );
  }
}
