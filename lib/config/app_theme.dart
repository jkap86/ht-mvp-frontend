import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colors
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color errorColor = Color(0xFFE53935);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);

  // Draft-specific semantic colors
  static const Color draftActionPrimary = Color(0xFF238636);  // Draft button, your turn
  static const Color draftUrgent = Color(0xFFDA3633);         // Timer urgent (<10s)
  static const Color draftWarning = Color(0xFFD29922);        // Timer warning (10-30s)
  static const Color draftNormal = Color(0xFF1F6FEB);         // Timer normal, in-progress
  static const Color draftSuccess = Color(0xFF238636);        // Timer plenty of time (>60s)

  // Auction-specific colors
  static const Color auctionPrimary = Color(0xFFFF9800);      // Orange - auction accent
  static const Color auctionBgLight = Color(0xFFFFF3E0);      // Light orange background
  static const Color auctionBgDark = Color(0xFF3D2E1E);       // Dark orange-tinted background
  static const Color auctionBorderLight = Color(0xFFFFCC80);  // Light orange border
  static const Color auctionBorderDark = Color(0xFF5D4E3E);   // Dark orange border
  static const Color auctionTextMuted = Color(0xFF6E7681);    // Muted text color

  // Position colors (industry standard)
  static const Color positionQB = Color(0xFFE91E63);        // Pink/Magenta
  static const Color positionRB = Color(0xFF00BFA5);        // Teal
  static const Color positionWR = Color(0xFF2196F3);        // Blue
  static const Color positionTE = Color(0xFFFF9800);        // Orange
  static const Color positionK = Color(0xFF9C27B0);         // Purple
  static const Color positionDEF = Color(0xFF795548);       // Brown
  static const Color positionFLEX = Color(0xFF607D8B);      // Blue-grey
  static const Color positionSuperFlex = Color(0xFF7C4DFF); // Deep Purple
  static const Color positionRecFlex = Color(0xFF00ACC1);   // Cyan
  static const Color positionDL = Color(0xFF5D4037);        // Brown (dark)
  static const Color positionLB = Color(0xFF6D4C41);        // Brown (medium)
  static const Color positionDB = Color(0xFF8D6E63);        // Brown (light)
  static const Color positionIdpFlex = Color(0xFF795548);   // Brown
  static const Color positionIR = Color(0xFF9E9E9E);        // Grey
  static const Color positionTaxi = Color(0xFFFFB300);      // Amber/Gold
  static const Color positionPick = Color(0xFF3F51B5);      // Indigo (draft pick asset)

  // Injury status colors
  static const Color injuryOut = Color(0xFFDA3633);
  static const Color injuryDoubtful = Color(0xFFDA3633);
  static const Color injuryQuestionable = Color(0xFFD29922);
  static const Color injuryProbable = Color(0xFFD29922);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
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
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: darkSurfaceColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextPrimary,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceColor,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkCardColor,
        selectedColor: primaryColor.withAlpha(50),
        labelStyle: const TextStyle(color: darkTextPrimary),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: darkTextPrimary,
        iconColor: darkTextSecondary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCardColor,
        contentTextStyle: const TextStyle(color: darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
