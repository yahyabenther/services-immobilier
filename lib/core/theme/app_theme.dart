import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextStyle _f(double size, FontWeight weight, [Color color = AppColors.text]) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color);

  static TextTheme _textTheme(TextTheme t) {
    TextStyle? g(TextStyle? s) => s == null ? null : GoogleFonts.plusJakartaSans(textStyle: s);
    return t
        .copyWith(
          displayLarge: g(t.displayLarge),
          displayMedium: g(t.displayMedium),
          displaySmall: g(t.displaySmall),
          headlineLarge: g(t.headlineLarge),
          headlineMedium: g(t.headlineMedium),
          headlineSmall: g(t.headlineSmall),
          titleLarge: g(t.titleLarge),
          titleMedium: g(t.titleMedium),
          titleSmall: g(t.titleSmall),
          bodyLarge: g(t.bodyLarge),
          bodyMedium: g(t.bodyMedium),
          bodySmall: g(t.bodySmall),
          labelLarge: g(t.labelLarge),
          labelMedium: g(t.labelMedium),
          labelSmall: g(t.labelSmall),
        )
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);
  }

  static ThemeData get light {
    final radius = BorderRadius.circular(14);
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        surface: Colors.white,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.text,
        titleTextStyle: _f(18, FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: _f(14, FontWeight.w400, AppColors.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: border(AppColors.line),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.primary, 1.6),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: _f(16, FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: _f(15, FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: _f(14, FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        height: 68,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 26,
              color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return _f(11, selected ? FontWeight.w700 : FontWeight.w500,
              selected ? AppColors.primary : AppColors.muted);
        }),
      ),
    );
  }
}