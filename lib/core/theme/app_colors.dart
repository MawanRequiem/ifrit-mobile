/// AgniRakhsa color system.
///
/// Each palette instance exposes the same semantic colors so that
/// widgets can theme transparently via `Theme.of(context).brightness`.
///
/// Usage:
///   final colors = AppColors.of(context);
///   colors.surface1 // adaptive

import 'package:flutter/material.dart';

/// Light / dark color palette container.
class AppColorPalette {
  final Color surface0;
  final Color surface1;
  final Color surface2;
  final Color surface3;
  final Color border;
  final Color borderSub;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color brand;
  final Color brandHover;
  final Color safe;
  final Color warning;
  final Color critical;
  final Color info;

  const AppColorPalette({
    required this.surface0, required this.surface1, required this.surface2,
    required this.surface3, required this.border, required this.borderSub,
    required this.textPrimary, required this.textSecondary, required this.textMuted,
    required this.brand, required this.brandHover,
    required this.safe, required this.warning, required this.critical, required this.info,
  });

  factory AppColorPalette.dark() => const AppColorPalette(
    surface0: Color(0xFF0D0F14), surface1: Color(0xFF13161D),
    surface2: Color(0xFF1A1D26), surface3: Color(0xFF22262F),
    border: Color(0xFF2A2E38), borderSub: Color(0xFF1F222B),
    textPrimary: Color(0xFFE8E9ED), textSecondary: Color(0xFF9BA1B0), textMuted: Color(0xFF5C6372),
    brand: Color(0xFFD64545), brandHover: Color(0xFFE55050),
    safe: Color(0xFF3DBB7D), warning: Color(0xFFE5A84B), critical: Color(0xFFE54B4B), info: Color(0xFF4BA3E5),
  );

  factory AppColorPalette.light() => const AppColorPalette(
    surface0: Color(0xFFF2F2F7), surface1: Color(0xFFFFFFFF),
    surface2: Color(0xFFF5F5F7), surface3: Color(0xFFE5E5EA),
    border: Color(0xFFD1D1D6), borderSub: Color(0xFFE5E5EA),
    textPrimary: Color(0xFF1C1C1E), textSecondary: Color(0xFF636366), textMuted: Color(0xFF8E8E93),
    brand: Color(0xFFC0392B), brandHover: Color(0xFFD64545),
    safe: Color(0xFF27AE60), warning: Color(0xFFF39C12), critical: Color(0xFFC0392B), info: Color(0xFF2980B9),
  );
}

/// Kept for backward compatibility — all fields are the dark palette.
abstract final class AppColors {
  static const Color surface0    = Color(0xFF0D0F14);
  static const Color surface1    = Color(0xFF13161D);
  static const Color surface2    = Color(0xFF1A1D26);
  static const Color surface3    = Color(0xFF22262F);
  static const Color border      = Color(0xFF2A2E38);
  static const Color borderSub   = Color(0xFF1F222B);
  static const Color textPrimary   = Color(0xFFE8E9ED);
  static const Color textSecondary = Color(0xFF9BA1B0);
  static const Color textMuted     = Color(0xFF5C6372);
  static const Color brand      = Color(0xFFD64545);
  static const Color brandHover = Color(0xFFE55050);
  static const Color safe     = Color(0xFF3DBB7D);
  static const Color warning  = Color(0xFFE5A84B);
  static const Color critical = Color(0xFFE54B4B);
  static const Color info     = Color(0xFF4BA3E5);

  static const Color sensorMQ2  = Color(0xFFE57A4B);
  static const Color sensorMQ4  = Color(0xFF4BD6B0);
  static const Color sensorMQ6  = Color(0xFFB04BE5);
  static const Color sensorMQ9  = Color(0xFFE5C94B);
  static const Color sensorTemp = Color(0xFF4B8CE5);
  static const Color sensorHum  = Color(0xFF4BC6E5);
  static const Color sensorFlam = Color(0xFFE54B4B);

  static AppColorPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? AppColorPalette.dark() : AppColorPalette.light();
  }
}
