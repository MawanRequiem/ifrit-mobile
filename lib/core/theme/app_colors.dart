// AgniRakhsa color system.
//
// Industrial avionics palette — deep charcoal surfaces with
// restrained ember accents. Color is functional, never decorative.
import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Surfaces ──────────────────────────────────────────────
  static const Color surface0 = Color(0xFF0D0F14);    // deepest background
  static const Color surface1 = Color(0xFF13161D);    // card / sheet
  static const Color surface2 = Color(0xFF1A1D26);    // elevated card
  static const Color surface3 = Color(0xFF22262F);    // interactive hover

  // ── Borders ───────────────────────────────────────────────
  static const Color border    = Color(0xFF2A2E38);
  static const Color borderSub = Color(0xFF1F222B);

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFE8E9ED);
  static const Color textSecondary = Color(0xFF9BA1B0);
  static const Color textMuted     = Color(0xFF5C6372);

  // ── Brand / Accent ────────────────────────────────────────
  static const Color brand      = Color(0xFFD64545);  // ember red
  static const Color brandHover = Color(0xFFE55050);

  // ── Status Semantics ──────────────────────────────────────
  static const Color safe     = Color(0xFF3DBB7D);
  static const Color warning  = Color(0xFFE5A84B);
  static const Color critical = Color(0xFFE54B4B);
  static const Color info     = Color(0xFF4BA3E5);

  // ── Sensor Type Accents ───────────────────────────────────
  static const Color sensorMQ2  = Color(0xFFE57A4B);  // smoke/LPG
  static const Color sensorMQ4  = Color(0xFF4BD6B0);  // methane
  static const Color sensorMQ6  = Color(0xFFB04BE5);  // LPG
  static const Color sensorMQ9  = Color(0xFFE5C94B);  // CO
  static const Color sensorTemp = Color(0xFF4B8CE5);  // temperature
  static const Color sensorHum  = Color(0xFF4BC6E5);  // humidity
  static const Color sensorFlam = Color(0xFFE54B4B);  // flame
}
