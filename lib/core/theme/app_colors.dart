import 'package:flutter/material.dart';

/// Central color definitions for EchoMap
/// Brand identity: Deep Navy (#061A3A) + Navy Blue (#0B2D5C) + Primary Blue (#1677C8) + Bright Cyan (#35D5E8) + Light Cyan (#B8F4F7)
class AppColors {
  // EchoMap Core Brand Colors
  static const Color deepNavy = Color(0xFF061A3A);
  static const Color navyBlue = Color(0xFF0B2D5C);
  static const Color primaryBlue = Color(0xFF1677C8);
  static const Color brightCyan = Color(0xFF35D5E8);
  static const Color lightCyan = Color(0xFFB8F4F7);
  static const Color veryLightCyan = Color(0xFFE8FAFC);
  // The light-mode scaffold is deliberately cyan-tinted, never white.
  static const Color cyanSurface = veryLightCyan;
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkNavy = Color(0xFF031126);

  // Backgrounds
  static const Color lightBackground = cyanSurface;
  static const Color darkBackground = Color(0xFF031126);

  // Primary & Secondary Brand Aliases
  static const Color primary = primaryBlue;
  static const Color primaryCyan = brightCyan;
  static const Color primaryDeepNavy = deepNavy;
  static const Color navyBackground = deepNavy;

  // Containers & Highlights
  static const Color primaryContainer = lightCyan;
  static const Color onPrimaryContainer = deepNavy;
  static const Color secondary = brightCyan;
  static const Color secondaryContainer = Color(0xFFD4F6FA);
  static const Color tertiary = navyBlue;
  static const Color tertiaryContainer = Color(0xFFD6E8FB);

  // Light Theme Surfaces & Text (Cyan-tinted + Navy + Blue)
  static const Color lightSurface = Color(0xFFF5FCFD);
  static const Color lightSurfaceVariant = Color(0xFFE2F5F8);
  static const Color lightBorder = Color(0xFFC6E7EF);
  static const Color lightTextPrimary = Color(0xFF061A3A);
  static const Color lightTextSecondary = Color(0xFF4A6D88);

  // Dark Theme Surfaces & Text (Deep Navy Foundation + Cyan Highlights)
  static const Color darkSurface = Color(0xFF061A3A);
  static const Color darkSurfaceVariant = Color(0xFF0B2D5C);
  static const Color darkElevated = Color(0xFF0E386E);
  static const Color darkBorder = Color(0xFF13386E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB8DCE5);

  // General Text
  static const Color lightText = Colors.white;
  static const Color darkText = Color(0xFF061A3A);

  // Accent Colors
  static const Color accentLight = Color(0xFF35D5E8);
  static const Color accentDark = Color(0xFF1677C8);

  // Semantic States
  static const Color favorite = Color(0xFFE53935);
  static const Color favoriteBg = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
}
