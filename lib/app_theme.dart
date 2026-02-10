import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

// Font fallback to ensure diacritics/emoji render correctly on all devices.
const _globalFontFallback = <String>[
  'Noto Sans',
  'NotoSans',
  'Roboto',
  'Segoe UI',
  'Arial Unicode MS',
  // Emoji fonts (platform-dependent; harmless if missing).
  'Apple Color Emoji',
  'Segoe UI Emoji',
  'Segoe UI Symbol',
  'Noto Color Emoji',
];

final lightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Lato',
  fontFamilyFallback: _globalFontFallback,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: PanAfricanColors.primary,
    brightness: Brightness.light,
    primary: PanAfricanColors.primary,
    secondary: PanAfricanColors.secondary,
    tertiary: PanAfricanColors.tertiary,
  ),
  canvasColor: Colors.white,
  scaffoldBackgroundColor: Colors.white,
  cardColor: PanAfricanColors.cardLight,
  dividerColor: Colors.black.withValues(alpha: 0.12),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Lato',
    ),
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Lato',
  fontFamilyFallback: _globalFontFallback,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: PanAfricanColors.primary,
    brightness: Brightness.dark,
    primary: PanAfricanColors.primaryLight,
    secondary: PanAfricanColors.secondary,
    tertiary: PanAfricanColors.tertiary,
  ),
  canvasColor: Colors.black,
  scaffoldBackgroundColor: Colors.black,
  cardColor: PanAfricanColors.cardDark,
  dividerColor: Colors.white.withValues(alpha: 0.12),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Lato',
    ),
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
);

const primarySwatchLight = MaterialColor(0XFF566A29, {
  50: Color(0xffEBEDE5),
  100: Color(0xffCCD2BF),
  200: Color(0xffABB594),
  300: Color(0xff899769),
  400: Color(0xff6F8049),
  500: Color(0xff566A29),
  600: Color(0xff4F6224),
  700: Color(0xff45571F),
  800: Color(0xff3C4D19),
  900: Color(0xff2B3C0F)
});

const primarySwatchDark = MaterialColor(0XFFEE9B55, {
  50: Color(0xffFDF1E7),
  100: Color(0xffF9DCC3),
  200: Color(0xffF5C49B),
  300: Color(0xffF1AC73),
  400: Color(0xffEE9B55),
  500: Color(0xffEB8937),
  600: Color(0xffE98131),
  700: Color(0xffE5762A),
  800: Color(0xffE26C23),
  900: Color(0xffDD5916)
});
