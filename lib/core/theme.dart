import 'package:flutter/material.dart';

// ─── Brand palette ─────────────────────────────────────────────────────────
class SColors {
  SColors._();

  static const navy = Color(0xFF0B1E3F);
  static const navyLight = Color(0xFF112847);
  static const navyCard = Color(0xFF0E2245);
  static const navyDeep = Color(0xFF0B1A38);
  static const navyBorder = Color(0xFF1A3560);
  static const bg = Color(0xFF060F1E);

  static const gold = Color(0xFFC9A84C);
  static const goldDark = Color(0xFF8B6A1F);

  static const textPrimary = Colors.white;
  static const textSub = Color(0xFF7A90B0);
  static const textDim = Color(0xFF4A6080);

  static const green = Color(0xFF2ECC8F);
  static const red = Color(0xFFE05C5C);
}

// ─── Text styles ───────────────────────────────────────────────────────────
class SText {
  SText._();

  static const heading = TextStyle(
    color: SColors.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w700,
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
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const body = TextStyle(color: SColors.textPrimary, fontSize: 15);

  static const label = TextStyle(
    color: SColors.textSub,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const hint = TextStyle(color: SColors.textDim, fontSize: 14);

  static const caption = TextStyle(color: SColors.textSub, fontSize: 13);

  static const tiny = TextStyle(color: SColors.textDim, fontSize: 11);

  static const goldAccent = TextStyle(
    color: SColors.gold,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const errorText = TextStyle(color: SColors.red, fontSize: 13);
}

// ─── Decoration helpers ────────────────────────────────────────────────────
class SDecor {
  SDecor._();

  static BoxDecoration card = BoxDecoration(
    color: SColors.navyCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: SColors.navyLight, width: 1),
  );

  static BoxDecoration inputField = BoxDecoration(
    color: SColors.navyCard,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: SColors.navyLight, width: 1),
  );

  static BoxDecoration balanceCard = const BoxDecoration(
    gradient: LinearGradient(
      colors: [SColors.navyCard, SColors.navyDeep],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.all(Radius.circular(24)),
    border: Border.fromBorderSide(
      BorderSide(color: SColors.navyBorder, width: 1),
    ),
  );

  static BoxDecoration goldGlow = BoxDecoration(
    gradient: LinearGradient(
      colors: [SColors.gold.withOpacity(0.12), SColors.gold.withOpacity(0.04)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: SColors.gold.withOpacity(0.25), width: 1),
  );

  static BoxDecoration errorBox = BoxDecoration(
    color: SColors.red.withOpacity(0.08),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: SColors.red.withOpacity(0.25), width: 1),
  );

  static BoxDecoration successBox = BoxDecoration(
    color: SColors.green.withOpacity(0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: SColors.green.withOpacity(0.2), width: 1),
  );

  static InputDecoration textInput({
    required String hint,
    Widget? prefix,
    Widget? suffix,
    String? prefixText,
    TextStyle? prefixStyle,
  }) {
    return InputDecoration(
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintText: hint,
      hintStyle: SText.hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      prefixText: prefixText,
      prefixStyle: prefixStyle,
    );
  }
}

// ─── Button styles ─────────────────────────────────────────────────────────
class SButton {
  SButton._();

  static ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: SColors.gold,
    disabledBackgroundColor: SColors.navyLight,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 0,
  );

  static const TextStyle primaryLabel = TextStyle(
    color: SColors.navy,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle disabledLabel = TextStyle(
    color: SColors.textDim,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
}

// ─── App ThemeData ─────────────────────────────────────────────────────────
class STheme {
  STheme._();

  static ThemeData get dark => ThemeData(
    fontFamily: 'SF Pro Display',
    scaffoldBackgroundColor: SColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: SColors.gold,
      surface: SColors.navy,
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}
