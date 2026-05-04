import 'package:flutter/material.dart';

class AppColorsLight {
  static const Color seed = Color(0xFF2E7D32);

  static const Color scaffoldBg = Color(0xFFEEF3EF);
  static const Color cardBg = Color(0xFFF4EEDF);

  static const Color surfaceContainerHighest = Color(0xFFE8DFC8);
  static const Color surfaceContainerHigh = Color(0xFFECE4D0);
  static const Color surfaceContainer = Color(0xFFEFE8D6);
  static const Color surfaceContainerLow = Color(0xFFF1ECDC);
  static const Color surfaceContainerLowest = Color(0xFFF7F2E5);

  static const Color primary = Color(0xFF2E7D32);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color primaryContainer = Color(0xFF9BD0A0);
  static const Color onPrimaryContainer = Color(0xFF0A3A0E);
  static const Color secondary = Color(0xFF00796B);

  static const Color btnExpense = Color(0xFFEF9A9A);
  static const Color btnTransfer = Color(0xFF90CAF9);
  static const Color btnMenu = Color(0xFFCFCFCF);

  static const Color expenseBg = Color(0xFFF67268);
  static const Color expenseFg = Color(0xFFFFFFFF);
}

class AppColorsDark {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surface2 = Color(0xFF2A2A2A);

  static const Color onSurface = Color(0xFFEEEEEE);
  static const Color onSurfaceMuted = Color(0xFFAAAAAA);

  static const Color divider = Color(0xFF333333);
  static const Color outline2 = Color(0xFF2C2C2C);

  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color primaryContainer = Color(0xFF1B3A1F);
  static const Color onPrimaryContainer = Color(0xFFB7EFB9);

  static const Color secondary = Color(0xFF80CBC4);
  static const Color onSecondary = Color(0xFF000000);
  static const Color secondaryContainer = Color(0xFF1A3330);
  static const Color onSecondaryContainer = Color(0xFFB2DFDB);

  static const Color tertiary = Color(0xFF90CAF9);
  static const Color onTertiary = Color(0xFF000000);
  static const Color tertiaryContainer = Color(0xFF1A2A3A);
  static const Color onTertiaryContainer = Color(0xFFBBDEFB);

  static const Color error = Color(0xFFEF9A9A);
  static const Color onError = Color(0xFF000000);
  static const Color errorContainer = Color(0xFF4E1212);
  static const Color onErrorContainer = Color(0xFFFFCDD2);

  static const Color btnExpense = Color(0xFF3A1A1A);
  static const Color btnTransfer = Color(0xFF1A2A3A);
  static const Color btnMenu = Color(0xFF2A2A2A);

  static const Color expenseBg = Color(0xFF4A1A1A);
  static const Color expenseFg = Color(0xFFEF9A9A);
}

class PageColors {
  static const Color records = Colors.blue;
  static const Color accounts = Colors.green;
  static const Color dashboard = Color(0xFFB71C1C);
  static const Color bills = Colors.orange;
  static const Color categories = Colors.purple;
  static const Color budget = Colors.deepOrange;
  static const Color goals = Colors.teal;
}

class ProgressColors {
  static Color goalProgress(double ratio) {
    final r = ratio.clamp(0.0, 1.0);
    if (r <= 0.33) {
      return Color.lerp(Colors.red.shade600, Colors.orange.shade600, r / 0.33)!;
    }
    if (r <= 0.66) {
      return Color.lerp(
        Colors.orange.shade600,
        Colors.yellow.shade700,
        (r - 0.33) / 0.33,
      )!;
    }
    return Color.lerp(
      Colors.yellow.shade700,
      Colors.green.shade600,
      (r - 0.66) / 0.34,
    )!;
  }

  static Color budgetProgress(double ratio, {required bool overBudget}) {
    if (overBudget) return Colors.red.shade600;
    final r = ratio.clamp(0.0, 1.0);
    if (r <= 0.5) {
      return Color.lerp(
        Colors.green.shade600,
        Colors.yellow.shade700,
        r / 0.5,
      )!;
    }
    return Color.lerp(
      Colors.yellow.shade700,
      Colors.red.shade600,
      (r - 0.5) / 0.5,
    )!;
  }
}

class AppColorPresets {
  static const Color koviraGreen = Color(0xFF4CAF50);
  static const Color oceanBlue = Color(0xFF1976D2);
  static const Color royalPurple = Color(0xFF7B1FA2);
  static const Color warmOrange = Color(0xFFF57C00);
  static const Color deepTeal = Color(0xFF00796B);
  static const Color rosePink = Color(0xFFC2185B);
  static const Color burntCoral = Color(0xFFE64A19);
  static const Color forestGreen = Color(0xFF2E7D32);
}
