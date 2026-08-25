import 'package:flutter/material.dart';

/// "Warm and cold" palette: orange (warm) + blue (cold).
/// Separate file so screens can use accent colors (e.g., `warmRed`).
abstract final class AppColors {
  // Warm orange
  static const Color warmOrange = Color(0xFFE65100);
  static const Color warmOrangeDark = Color(0xFFFFB74D);
  static const Color warmContainer = Color(0xFFFFCC80);
  static const Color warmOnContainer = Color(0xFFBF360C);
  static const Color warmContainerDark = Color(0xFFBF360C);
  static const Color warmOnContainerDark = Color(0xFFFFCC80);

  // Cool blue
  static const Color coldBlue = Color(0xFF0277BD);
  static const Color coldBlueDark = Color(0xFF4FC3F7);
  static const Color coldBlueContainer = Color(0xFFB3E5FC);
  static const Color coldBlueOnContainer = Color(0xFF01579B);
  static const Color coldBlueContainerDark = Color(0xFF01579B);
  static const Color coldBlueOnContainerDark = Color(0xFFB3E5FC);

  // Red (accents: heart rate, deletion, heart rate chart)
  static const Color warmRed = Color(0xFFD32F2F);
  static const Color warmRedDark = Color(0xFFEF5350);

  // Neutral grays — cards and backgrounds (no M3 pink tint)
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceLowLight = Color(0xFFF4F4F4);
  static const Color surfaceContainerLight = Color(0xFFEFEFEF);
  static const Color surfaceHighLight = Color(0xFFEAEAEA);
  static const Color surfaceHighestLight = Color(0xFFE2E2E2);
  static const Color onSurfaceLight = Color(0xFF1C1B1F);
  static const Color onSurfaceVariantLight = Color(0xFF49454F);
  static const Color outlineLight = Color(0xFF79747E);
  static const Color outlineVariantLight = Color(0xFFE4E1E6);

  static const Color surfaceDark = Color(0xFF141414);
  static const Color surfaceLowestDark = Color(0xFF0F0F0F);
  static const Color surfaceLowDark = Color(0xFF191919);
  static const Color surfaceContainerDark = Color(0xFF1F1F1F);
  static const Color surfaceHighDark = Color(0xFF252525);
  static const Color surfaceHighestDark = Color(0xFF2C2C2C);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);
  static const Color onSurfaceVariantDark = Color(0xFFC7C2CC);
  static const Color outlineDark = Color(0xFF938F99);
  static const Color outlineVariantDark = Color(0xFF44474F);
}
