import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme get textTheme {
    final body = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return body.copyWith(
      // Display — large headlines (rarely used in mobile)
      displayLarge: body.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      // Headline — screen titles
      headlineMedium: body.headlineMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      headlineSmall: body.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.25,
      ),
      // Title — card headers, section titles
      titleLarge: body.titleLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.3,
      ),
      // Body — paragraph text
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      // Label — buttons, chips, badges
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  /// Monospace style for sensor values, MAC addresses, timestamps.
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static TextStyle get monoSmall => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static TextStyle get monoLarge => GoogleFonts.jetBrainsMono(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}
