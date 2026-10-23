import 'package:flutter/material.dart';

/// Colour tokens from the design (section 8): night ink and lamplight.
abstract final class Palette {
  static const night = Color(0xFF18213A);
  static const wall = Color(0xFF222C49);
  static const panel = Color(0xFF1F2945);
  static const raise = Color(0xFF2A3456);
  static const line = Color(0xFF2E3A5E);
  static const unlit = Color(0xFF1A2238);
  static const indicator = Color(0xFF3A4469);
  static const tickPassed = Color(0xFFB48B3C);
  static const tickAhead = Color(0xFF4A5680);
  static const lamp = Color(0xFFF6C453);
  static const me = Color(0xFFFFE29A);
  static const paper = Color(0xFFEDE6D6);
  static const soft = Color(0xFFC9C3B6);
  static const mute = Color(0xFF9AA3BD);
}

/// The dark evening theme. Persian gets its own faces and taller lines,
/// and never letter spacing (it would break the joined letters).
ThemeData buildTheme(Locale locale) {
  final persian = locale.languageCode == 'fa';
  final ui = persian ? 'VazirmatnUI' : 'BricolageGrotesque';
  // Mixed text (a Persian word in English, or the reverse) falls back to the
  // other script's face instead of empty boxes.
  final fallback = [if (persian) 'BricolageGrotesque' else 'VazirmatnUI'];
  final heading = TextStyle(
    fontFamily: persian ? 'VazirmatnUI' : 'Literata',
    fontWeight: persian ? FontWeight.w700 : FontWeight.w500,
    fontVariations: persian ? null : const [FontVariation.weight(500)],
    fontSize: persian ? 23 : 26,
    height: persian ? 1.55 : 1.2,
    letterSpacing: 0,
    color: Palette.paper,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: ui,
    fontFamilyFallback: fallback,
    colorScheme: const ColorScheme.dark(
      primary: Palette.lamp,
      onPrimary: Palette.night,
      secondary: Palette.me,
      surface: Palette.night,
      onSurface: Palette.paper,
      surfaceContainer: Palette.panel,
      outline: Palette.line,
    ),
    scaffoldBackgroundColor: Palette.night,
  );
  final textTheme = base.textTheme
      .apply(fontFamily: ui, bodyColor: Palette.paper)
      .copyWith(
        headlineSmall: heading,
        bodyMedium: TextStyle(
          fontFamily: ui,
          fontSize: 16,
          height: persian ? 1.8 : 1.5,
          color: Palette.soft,
        ),
      );
  final withFallback = textTheme.apply(fontFamilyFallback: fallback);
  return base.copyWith(
    textTheme: persian ? _withoutLetterSpacing(withFallback) : withFallback,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.night,
      indicatorColor: Palette.indicator,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Palette.lamp
              : Palette.mute,
        ),
      ),
    ),
  );
}

/// Material's default styles letter-space labels and titles;
/// Persian must not be.
TextTheme _withoutLetterSpacing(TextTheme t) {
  TextStyle? z(TextStyle? s) => s?.copyWith(letterSpacing: 0);
  return t.copyWith(
    displayLarge: z(t.displayLarge),
    displayMedium: z(t.displayMedium),
    displaySmall: z(t.displaySmall),
    headlineLarge: z(t.headlineLarge),
    headlineMedium: z(t.headlineMedium),
    headlineSmall: z(t.headlineSmall),
    titleLarge: z(t.titleLarge),
    titleMedium: z(t.titleMedium),
    titleSmall: z(t.titleSmall),
    bodyLarge: z(t.bodyLarge),
    bodyMedium: z(t.bodyMedium),
    bodySmall: z(t.bodySmall),
    labelLarge: z(t.labelLarge),
    labelMedium: z(t.labelMedium),
    labelSmall: z(t.labelSmall),
  );
}
