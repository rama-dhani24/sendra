import 'package:flutter/material.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
class SColors {
  SColors._();

  // Brand
  static const gold = Color(0xFFD4A843);
  static const goldDark = Color(0xFFB8922E);

  // Dark palette
  static const navy = Color(0xFF0D1B2A);
  static const navyCard = Color(0xFF152535);
  static const navyLight = Color(0xFF1E3448);
  static const navyBorder = Color(0xFF243D55);
  static const bg = Color(0xFF0A1520);

  // Light palette
  static const lightBg = Color(0xFFF5F7FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightNavBar = Color(0xFFFFFFFF);

  // Semantic
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const blue = Color(0xFF3B82F6);

  // Text — dark mode
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSub = Color(0xFF94A3B8);
  static const textDim = Color(0xFF475569);

  // Text — light mode
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSub = Color(0xFF64748B);
  static const lightTextDim = Color(0xFF94A3B8);
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class SText {
  SText._();

  static const heading = TextStyle(
    color: SColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const title = TextStyle(
    color: SColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const sectionTitle = TextStyle(
    color: SColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const appBarTitle = TextStyle(
    color: SColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(color: SColors.textPrimary, fontSize: 15);
  static const label = TextStyle(
    color: SColors.textSub,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
  static const caption = TextStyle(color: SColors.textSub, fontSize: 13);
  static const tiny = TextStyle(color: SColors.textDim, fontSize: 11);
  static const hint = TextStyle(color: SColors.textDim, fontSize: 15);
  static const goldAccent = TextStyle(
    color: SColors.gold,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static const errorText = TextStyle(color: SColors.red, fontSize: 12);
}

// ─── Decorations ──────────────────────────────────────────────────────────────
class SDecor {
  SDecor._();

  static const balanceCard = BoxDecoration(
    color: SColors.navyCard,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    border: Border.fromBorderSide(
      BorderSide(color: SColors.navyLight, width: 1),
    ),
  );

  static const card = BoxDecoration(
    color: SColors.navyCard,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(
      BorderSide(color: SColors.navyLight, width: 1),
    ),
  );

  static const inputField = BoxDecoration(
    color: SColors.navyCard,
    borderRadius: BorderRadius.all(Radius.circular(14)),
    border: Border.fromBorderSide(
      BorderSide(color: SColors.navyLight, width: 1),
    ),
  );

  static const errorBox = BoxDecoration(
    color: Color(0x1AEF4444),
    borderRadius: BorderRadius.all(Radius.circular(12)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0x33EF4444), width: 1),
    ),
  );

  static const goldGlow = BoxDecoration(
    color: SColors.navyCard,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0x33D4A843), width: 1),
    ),
  );

  static InputDecoration textInput({
    String? hint,
    String? prefixText,
    TextStyle? prefixStyle,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      border: InputBorder.none,
      hintText: hint,
      hintStyle: SText.hint,
      prefixText: prefixText,
      prefixStyle: prefixStyle,
      prefixIcon: prefix != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: prefix,
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: suffix,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ─── Button Styles ────────────────────────────────────────────────────────────
class SButton {
  SButton._();

  static final primary = ElevatedButton.styleFrom(
    backgroundColor: SColors.gold,
    foregroundColor: SColors.navy,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 0,
  );

  static const primaryLabel = TextStyle(
    color: SColors.navy,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
}

// ─── Themes ───────────────────────────────────────────────────────────────────
class STheme {
  STheme._();

  // ── Dark theme (existing Sendra look) ──────────────────────────────────────
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: SColors.gold,
      secondary: SColors.gold,
      surface: SColors.navyCard,
      background: SColors.bg,
      error: SColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SColors.bg,
      elevation: 0,
      titleTextStyle: SText.appBarTitle,
      iconTheme: IconThemeData(color: SColors.textSub),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: SColors.textPrimary),
      bodyMedium: TextStyle(color: SColors.textSub),
      bodySmall: TextStyle(color: SColors.textDim),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: SColors.navyCard,
    ),
    dividerColor: SColors.navyLight,
    useMaterial3: false,
  );

  // ── Light theme ─────────────────────────────────────────────────────────────
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: SColors.lightBg,
    colorScheme: ColorScheme.light(
      primary: SColors.gold,
      secondary: SColors.gold,
      surface: SColors.lightCard,
      background: SColors.lightBg,
      error: SColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SColors.lightBg,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: SColors.lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: SColors.lightTextSub),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: SColors.lightTextPrimary),
      bodyMedium: TextStyle(color: SColors.lightTextSub),
      bodySmall: TextStyle(color: SColors.lightTextDim),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: SColors.lightCard,
    ),
    cardColor: SColors.lightCard,
    dividerColor: SColors.lightBorder,
    useMaterial3: false,
  );
}
