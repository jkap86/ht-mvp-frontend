import 'package:flutter/material.dart';

import '../core/theme/hype_train_colors.dart';

class AppTheme {
  // ══════════════════════════════════════════════════════════════════════
  // Brand palette (theme-invariant)
  // ══════════════════════════════════════════════════════════════════════

  static const Color brandBlue = Color(0xFF32B8FB);
  static const Color brandBlueDark = Color(0xFF1A8FCC); // WCAG-safe on light bg
  static const Color brandPink = Color(0xFFFE1155);
  static const Color brandMint = Color(0xFF11FDA9);
  static const Color brandOrange = Color(0xFFFF8C11);
  static const Color darkBase = Color(0xFF0E1A25);

  // ══════════════════════════════════════════════════════════════════════
  // Legacy aliases (kept for backward compat during migration)
  // ══════════════════════════════════════════════════════════════════════

  static const Color primaryColor = brandBlue;
  static const Color secondaryColor = brandMint;
  static const Color errorColor = Color(0xFFE53935);

  // ══════════════════════════════════════════════════════════════════════
  // Draft-specific semantic colors (theme-invariant)
  // ══════════════════════════════════════════════════════════════════════

  static const Color draftActionPrimary = brandMint;
  static const Color draftUrgent = Color(0xFFDA3633);
  static const Color draftWarning = Color(0xFFD29922);
  static const Color draftNormal = brandBlue;
  static const Color draftSuccess = Color(0xFF43A047);

  // ══════════════════════════════════════════════════════════════════════
  // Auction-specific colors (theme-invariant accents)
  // ══════════════════════════════════════════════════════════════════════

  static const Color auctionPrimary = brandOrange;

  // ══════════════════════════════════════════════════════════════════════
  // Position colors (industry standard, theme-invariant)
  // ══════════════════════════════════════════════════════════════════════

  static const Color positionQB = Color(0xFFE91E63);
  static const Color positionRB = Color(0xFF00BFA5);
  static const Color positionWR = Color(0xFF2196F3);
  static const Color positionTE = Color(0xFFFF9800);
  static const Color positionK = Color(0xFF9C27B0);
  static const Color positionDEF = Color(0xFF795548);
  static const Color positionFLEX = Color(0xFF607D8B);
  static const Color positionSuperFlex = Color(0xFF7C4DFF);
  static const Color positionRecFlex = Color(0xFF00ACC1);
  static const Color positionDL = Color(0xFF5D4037);
  static const Color positionLB = Color(0xFF6D4C41);
  static const Color positionDB = Color(0xFF8D6E63);
  static const Color positionIdpFlex = Color(0xFF795548);
  static const Color positionIR = Color(0xFF9E9E9E);
  static const Color positionTaxi = Color(0xFFFFB300);
  static const Color positionPick = Color(0xFF3F51B5);

  // ══════════════════════════════════════════════════════════════════════
  // Injury status colors (theme-invariant)
  // ══════════════════════════════════════════════════════════════════════

  static const Color injuryOut = Color(0xFFDA3633);
  static const Color injuryDoubtful = Color(0xFFDA3633);
  static const Color injuryQuestionable = Color(0xFFD29922);
  static const Color injuryProbable = Color(0xFFD29922);
  static const Color injuryMuted = Color(0xFF6E7681);

  // ══════════════════════════════════════════════════════════════════════
  // Medal colors (theme-invariant)
  // ══════════════════════════════════════════════════════════════════════

  static const Color medalGold = Color(0xFFFFB300);
  static const Color medalSilver = Color(0xFF9E9E9E);
  static const Color medalBronze = Color(0xFF8D6E63);

  // ══════════════════════════════════════════════════════════════════════
  // Light Theme
  // ══════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandBlue,
        primary: brandBlue,
        secondary: brandMint,
        error: errorColor,
        surface: const Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: const Color(0xFFEEF2F6),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandBlueDark,
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFD0D7DE),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF5F8FB),
        selectedColor: brandBlue.withAlpha(30),
        labelStyle: const TextStyle(color: Color(0xFF0E1A25)),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFF0E1A25),
        iconColor: Color(0xFF4A5F73),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF0E1A25),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: const [HypeTrainColors.light],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // Dark Theme
  // ══════════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandBlue,
        brightness: Brightness.dark,
        primary: brandBlue,
        secondary: brandMint,
        error: errorColor,
        surface: const Color(0xFF142230),
      ),
      scaffoldBackgroundColor: darkBase,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF142230),
        foregroundColor: Color(0xFFE8EDF2),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: const Color(0xFF1F3345),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F3345),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2D4255)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2D4255)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: Color(0xFF8DA0B5)),
        hintStyle: const TextStyle(color: Color(0xFF8DA0B5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandBlue,
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF142230),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF142230),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2D4255),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1F3345),
        selectedColor: brandBlue.withAlpha(50),
        labelStyle: const TextStyle(color: Color(0xFFE8EDF2)),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFE8EDF2),
        iconColor: Color(0xFF8DA0B5),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF1F3345),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F3345),
        contentTextStyle: const TextStyle(color: Color(0xFFE8EDF2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: const [HypeTrainColors.dark],
    );
  }
}
