import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightCyan,
      onPrimaryContainer: AppColors.deepNavy,
      secondary: AppColors.brightCyan,
      onSecondary: AppColors.deepNavy,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.deepNavy,
      tertiary: AppColors.navyBlue,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.deepNavy,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainer: AppColors.lightSurfaceVariant,
      surfaceContainerHigh: AppColors.lightSurface,
      surfaceContainerHighest: AppColors.secondaryContainer,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.lightBorder,
      outlineVariant: Color(0xFFD8EFF4),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cyanSurface,

      // ── AppBar: Deep Navy ──────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: AppColors.brightCyan),
        actionsIconTheme: IconThemeData(color: AppColors.brightCyan),
      ),

      // ── Cards ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 1.5,
        shadowColor: AppColors.deepNavy.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),

      // ── Chips ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        disabledColor: AppColors.lightSurfaceVariant.withAlpha(120),
        selectedColor: AppColors.brightCyan,
        secondarySelectedColor: AppColors.primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        labelStyle: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.deepNavy,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Dialogs ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.navyBlue,
        elevation: 8,
        shadowColor: AppColors.deepNavy.withAlpha(40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.brightCyan, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.pureWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.lightCyan,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      // ── Bottom Sheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.deepNavy,
        modalBackgroundColor: AppColors.deepNavy,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // ── Input Fields ───────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.brightCyan, width: 2),
        ),
        prefixIconColor: AppColors.primaryBlue,
        suffixIconColor: AppColors.lightTextSecondary,
        hintStyle: TextStyle(
            color: AppColors.lightTextSecondary, fontSize: 14),
        labelStyle: TextStyle(
            color: AppColors.lightTextSecondary, fontSize: 14),
        floatingLabelStyle:
            const TextStyle(color: AppColors.primaryBlue, fontSize: 14),
      ),

      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.navyBlue,
        headerBackgroundColor: AppColors.deepNavy,
        headerForegroundColor: AppColors.pureWhite,
        surfaceTintColor: Colors.transparent,
        dayForegroundColor: WidgetStatePropertyAll(AppColors.pureWhite),
        yearForegroundColor: WidgetStatePropertyAll(AppColors.lightCyan),
        todayForegroundColor: WidgetStatePropertyAll(AppColors.brightCyan),
        todayBorder: BorderSide(color: AppColors.brightCyan),
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.navyBlue,
        dialBackgroundColor: AppColors.deepNavy,
        dialHandColor: AppColors.brightCyan,
        dialTextColor: AppColors.pureWhite,
        hourMinuteColor: AppColors.deepNavy,
        hourMinuteTextColor: AppColors.pureWhite,
        entryModeIconColor: AppColors.brightCyan,
      ),

      // ── Navigation Bar: Deep Navy ──────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.deepNavy,
        indicatorColor: AppColors.brightCyan,
        elevation: 8,
        shadowColor: AppColors.darkNavy.withAlpha(80),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.brightCyan,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.lightCyan,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.deepNavy);
          }
          return const IconThemeData(color: AppColors.lightCyan);
        }),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brightCyan,
        foregroundColor: AppColors.deepNavy,
        elevation: 6,
        splashColor: AppColors.lightCyan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // ── Buttons ────────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
        ),
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),

      // ── Snack Bar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navyBlue,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: AppColors.brightCyan,
      ),

      // ── Switch ─────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.deepNavy;
          }
          return AppColors.lightTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brightCyan;
          }
          return AppColors.lightBorder;
        }),
      ),

      // ── Checkbox ───────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brightCyan;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.deepNavy),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
      ),

      // ── Progress Indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brightCyan,
      ),

      // ── Icon Theme ────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.primaryBlue),

      // ── List Tile ──────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primaryBlue,
        textColor: AppColors.lightTextPrimary,
      ),

      // ── Segmented Button ──────────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryBlue;
            }
            return AppColors.lightSurfaceVariant;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.lightTextSecondary;
          }),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DARK THEME
  // ────────────────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.brightCyan,
      onPrimary: AppColors.darkNavy,
      primaryContainer: AppColors.navyBlue,
      onPrimaryContainer: AppColors.lightCyan,
      secondary: AppColors.primaryBlue,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF09254C),
      onSecondaryContainer: AppColors.brightCyan,
      tertiary: AppColors.lightCyan,
      onTertiary: AppColors.darkNavy,
      tertiaryContainer: AppColors.darkElevated,
      onTertiaryContainer: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainer: AppColors.darkSurfaceVariant,
      surfaceContainerHigh: AppColors.darkElevated,
      surfaceContainerHighest: Color(0xFF134585),
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.darkBorder,
      outlineVariant: Color(0xFF163E78),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,

      // ── AppBar: Dark Navy ──────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: AppColors.brightCyan),
        actionsIconTheme: IconThemeData(color: AppColors.brightCyan),
      ),

      // ── Cards ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceVariant,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),

      // ── Chips ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        disabledColor: AppColors.darkSurfaceVariant.withAlpha(120),
        selectedColor: AppColors.brightCyan,
        secondarySelectedColor: AppColors.primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        labelStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.darkNavy,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Dialogs ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        elevation: 8,
        shadowColor: Colors.black.withAlpha(120),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      // ── Bottom Sheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        modalBackgroundColor: AppColors.darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // ── Input Fields ───────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.brightCyan, width: 2),
        ),
        prefixIconColor: AppColors.brightCyan,
        suffixIconColor: AppColors.darkTextSecondary,
        hintStyle:
            const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        labelStyle:
            const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        floatingLabelStyle:
            const TextStyle(color: AppColors.brightCyan, fontSize: 14),
      ),

      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.darkSurface,
        headerBackgroundColor: AppColors.darkNavy,
        headerForegroundColor: AppColors.pureWhite,
        surfaceTintColor: Colors.transparent,
        dayForegroundColor: WidgetStatePropertyAll(AppColors.pureWhite),
        yearForegroundColor: WidgetStatePropertyAll(AppColors.lightCyan),
        todayForegroundColor: WidgetStatePropertyAll(AppColors.brightCyan),
        todayBorder: BorderSide(color: AppColors.brightCyan),
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.darkSurface,
        dialBackgroundColor: AppColors.darkNavy,
        dialHandColor: AppColors.brightCyan,
        dialTextColor: AppColors.pureWhite,
        hourMinuteColor: AppColors.navyBlue,
        hourMinuteTextColor: AppColors.pureWhite,
        entryModeIconColor: AppColors.brightCyan,
      ),

      // ── Navigation Bar: Dark Navy ──────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkNavy,
        indicatorColor: AppColors.navyBlue,
        elevation: 8,
        shadowColor: Colors.black.withAlpha(120),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.brightCyan,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.lightCyan,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.brightCyan);
          }
          return const IconThemeData(color: AppColors.lightCyan);
        }),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brightCyan,
        foregroundColor: AppColors.darkNavy,
        elevation: 6,
        splashColor: AppColors.lightCyan,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // ── Buttons ────────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brightCyan,
          foregroundColor: AppColors.darkNavy,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brightCyan,
          foregroundColor: AppColors.darkNavy,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brightCyan,
          side: const BorderSide(color: AppColors.brightCyan, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brightCyan,
        ),
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),

      // ── Snack Bar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: AppColors.brightCyan,
      ),

      // ── Switch ─────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkNavy;
          }
          return AppColors.darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brightCyan;
          }
          return AppColors.darkBorder;
        }),
      ),

      // ── Checkbox ───────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brightCyan;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.darkNavy),
        side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      ),

      // ── Progress Indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brightCyan,
      ),

      // ── Icon Theme ────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.brightCyan),

      // ── List Tile ──────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.brightCyan,
        textColor: AppColors.darkTextPrimary,
      ),

      // ── Segmented Button ──────────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.brightCyan;
            }
            return AppColors.darkSurfaceVariant;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.darkNavy;
            }
            return AppColors.darkTextSecondary;
          }),
        ),
      ),
    );
  }
}
