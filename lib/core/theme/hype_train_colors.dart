import 'package:flutter/material.dart';

/// ThemeExtension providing brand-consistent colors that vary by light/dark mode.
///
/// Access via `context.htColors.card` instead of manual `isDark ? X : Y` checks.
/// Theme-invariant colors (brand accents, position, injury) live as statics on AppTheme.
class HypeTrainColors extends ThemeExtension<HypeTrainColors> {
  const HypeTrainColors({
    // Surfaces
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.card,
    // Text
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    // Semantic
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    // Feature areas
    required this.draftAction,
    required this.draftActionBg,
    required this.draftNormal,
    required this.auctionAccent,
    required this.auctionBg,
    required this.auctionBorder,
    required this.tradeAccent,
    // UI
    required this.border,
    required this.divider,
    required this.shadow,
    required this.selectionPrimary,
    required this.selectionSuccess,
    required this.selectionWarning,
  });

  // -- Surfaces --
  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color card;

  // -- Text --
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // -- Semantic --
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // -- Feature areas --
  final Color draftAction;
  final Color draftActionBg;
  final Color draftNormal;
  final Color auctionAccent;
  final Color auctionBg;
  final Color auctionBorder;
  final Color tradeAccent;

  // -- UI --
  final Color border;
  final Color divider;
  final Color shadow;
  final Color selectionPrimary;
  final Color selectionSuccess;
  final Color selectionWarning;

  // ──────────────────────────────── Light ────────────────────────────────

  static const light = HypeTrainColors(
    // Surfaces - pale desaturated navy tints
    background: Color(0xFFEEF2F6),
    surface: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF5F8FB),
    card: Color(0xFFFFFFFF),
    // Text
    textPrimary: Color(0xFF0E1A25),
    textSecondary: Color(0xFF4A5F73),
    textMuted: Color(0xFF7A8E9F),
    // Semantic
    success: Color(0xFF43A047),
    warning: Color(0xFFEF6C00),
    error: Color(0xFFE53935),
    info: Color(0xFF1A8FCC), // darker shade of brand blue for text-on-light
    // Feature areas
    draftAction: Color(0xFF0DA87A), // darker mint for light backgrounds
    draftActionBg: Color(0xFFE0FFF4),
    draftNormal: Color(0xFF1A8FCC), // darker blue for light backgrounds
    auctionAccent: Color(0xFFFF8C11),
    auctionBg: Color(0xFFFFF3E0),
    auctionBorder: Color(0xFFFFCC80),
    tradeAccent: Color(0xFFFE1155),
    // UI
    border: Color(0xFFD0D7DE),
    divider: Color(0xFFD0D7DE),
    shadow: Color(0x0D000000), // black 5%
    selectionPrimary: Color(0x1E32B8FB), // brand blue 12%
    selectionSuccess: Color(0x1E43A047), // green 12%
    selectionWarning: Color(0x1EFF8C11), // orange 12%
  );

  // ──────────────────────────────── Dark ─────────────────────────────────

  static const dark = HypeTrainColors(
    // Surfaces - lightened tints of #0E1A25
    background: Color(0xFF0E1A25),
    surface: Color(0xFF142230),
    surfaceContainer: Color(0xFF1A2B3A),
    card: Color(0xFF1F3345),
    // Text
    textPrimary: Color(0xFFE8EDF2),
    textSecondary: Color(0xFF8DA0B5),
    textMuted: Color(0xFF5A7085),
    // Semantic
    success: Color(0xFF43A047),
    warning: Color(0xFFEF6C00),
    error: Color(0xFFE53935),
    info: Color(0xFF32B8FB),
    // Feature areas
    draftAction: Color(0xFF11FDA9), // brand mint - vibrant on dark
    draftActionBg: Color(0xFF0D2A1F),
    draftNormal: Color(0xFF32B8FB), // brand blue
    auctionAccent: Color(0xFFFF8C11),
    auctionBg: Color(0xFF2A1F14),
    auctionBorder: Color(0xFF5D4E3E),
    tradeAccent: Color(0xFFFE1155),
    // UI
    border: Color(0xFF2D4255),
    divider: Color(0xFF2D4255),
    shadow: Color(0x33000000), // black 20%
    selectionPrimary: Color(0x3332B8FB), // brand blue 20%
    selectionSuccess: Color(0x3343A047), // green 20%
    selectionWarning: Color(0x33FF8C11), // orange 20%
  );

  // ──────────────────────────────── copyWith ─────────────────────────────

  @override
  HypeTrainColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceContainer,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? draftAction,
    Color? draftActionBg,
    Color? draftNormal,
    Color? auctionAccent,
    Color? auctionBg,
    Color? auctionBorder,
    Color? tradeAccent,
    Color? border,
    Color? divider,
    Color? shadow,
    Color? selectionPrimary,
    Color? selectionSuccess,
    Color? selectionWarning,
  }) {
    return HypeTrainColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      draftAction: draftAction ?? this.draftAction,
      draftActionBg: draftActionBg ?? this.draftActionBg,
      draftNormal: draftNormal ?? this.draftNormal,
      auctionAccent: auctionAccent ?? this.auctionAccent,
      auctionBg: auctionBg ?? this.auctionBg,
      auctionBorder: auctionBorder ?? this.auctionBorder,
      tradeAccent: tradeAccent ?? this.tradeAccent,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      selectionPrimary: selectionPrimary ?? this.selectionPrimary,
      selectionSuccess: selectionSuccess ?? this.selectionSuccess,
      selectionWarning: selectionWarning ?? this.selectionWarning,
    );
  }

  // ──────────────────────────────── lerp ─────────────────────────────────

  @override
  HypeTrainColors lerp(HypeTrainColors? other, double t) {
    if (other is! HypeTrainColors) return this;
    return HypeTrainColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      draftAction: Color.lerp(draftAction, other.draftAction, t)!,
      draftActionBg: Color.lerp(draftActionBg, other.draftActionBg, t)!,
      draftNormal: Color.lerp(draftNormal, other.draftNormal, t)!,
      auctionAccent: Color.lerp(auctionAccent, other.auctionAccent, t)!,
      auctionBg: Color.lerp(auctionBg, other.auctionBg, t)!,
      auctionBorder: Color.lerp(auctionBorder, other.auctionBorder, t)!,
      tradeAccent: Color.lerp(tradeAccent, other.tradeAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      selectionPrimary: Color.lerp(selectionPrimary, other.selectionPrimary, t)!,
      selectionSuccess: Color.lerp(selectionSuccess, other.selectionSuccess, t)!,
      selectionWarning: Color.lerp(selectionWarning, other.selectionWarning, t)!,
    );
  }
}

/// Convenience extension for accessing HypeTrainColors from BuildContext.
extension HypeTrainColorsX on BuildContext {
  HypeTrainColors get htColors => Theme.of(this).extension<HypeTrainColors>()!;
}
