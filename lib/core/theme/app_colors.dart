import 'package:flutter/material.dart';

/// Central color definitions for EchoMap
/// Brand identity: Deep Navy (#071A3D) + Primary Blue (#1479D1) + Bright Cyan (#4DD8F2)
class AppColors {
  // Brand Foundation Colors
  static const Color primaryDeepNavy = Color(0xFF071A3D);
  static const Color primaryBlue = Color(0xFF1479D1);
  static const Color brightCyan = Color(0xFF4DD8F2);
  static const Color lightCyan = Color(0xFFB9F3FA);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Backgrounds
  static const Color lightBackground = Color(0xFFF4F8FC);
  static const Color darkBackground = Color(0xFF050B18);

  // Primary & Cyan Aliases
  static const Color primary = primaryBlue;
  static const Color primaryCyan = brightCyan;
  static const Color navyBackground = primaryDeepNavy;

  // Containers & Highlights
  static const Color primaryContainer = lightCyan;
  static const Color onPrimaryContainer = primaryDeepNavy;
  static const Color secondary = brightCyan;
  static const Color secondaryContainer = Color(0xFFD6F6FC);
  static const Color tertiary = Color(0xFF0E6EB8);
  static const Color tertiaryContainer = Color(0xFFD1ECFB);

  // Light Theme Surfaces & Text
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F5FA);
  static const Color lightBorder = Color(0xFFDCE7F2);
  static const Color lightTextPrimary = Color(0xFF071A3D);
  static const Color lightTextSecondary = Color(0xFF55687E);

  // Dark Theme Surfaces & Text
  static const Color darkSurface = Color(0xFF071A3D);
  static const Color darkSurfaceVariant = Color(0xFF0C234E);
  static const Color darkBorder = Color(0xFF163768);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9BB2CD);

  // General Text
  static const Color lightText = Colors.white;
  static const Color darkText = Color(0xFF071A3D);

  // Accent Colors
  static const Color accentLight = Color(0xFF66D9FF);
  static const Color accentDark = Color(0xFF0099CC);

  // Semantic States
  static const Color favorite = Color(0xFFE53935);
  static const Color favoriteBg = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
}
