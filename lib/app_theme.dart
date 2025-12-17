import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/material3_motion.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

final lightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'dosis',
  brightness: Brightness.light,
  canvasColor: PanAfricanColors.surface,
  scaffoldBackgroundColor: PanAfricanColors.surface,
  primarySwatch: primarySwatchLight,
  primaryColor: PanAfricanColors.primary,
  colorScheme: PanAfricanColorScheme.light,
  dividerColor: PanAfricanColors.outline,
  cardColor: AppColors.filledLight,
  cardTheme: CardThemeData(
    elevation: 0,
    shadowColor: Colors.black.withOpacity(0.08),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: PanAfricanColors.outline.withOpacity(0.2)),
    ),
    margin: const EdgeInsets.all(8),
    clipBehavior: Clip.antiAlias,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    iconTheme: const IconThemeData(color: PanAfricanColors.textPrimary),
    titleTextStyle: const TextStyle(
      color: PanAfricanColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'dosis',
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: PanAfricanColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: PanAfricanColors.primary,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: PanAfricanColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: PanAfricanColors.outline.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: PanAfricanColors.outline.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: PanAfricanColors.primary, width: 2),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: PanAfricanColors.surface,
    selectedColor: PanAfricanColors.primaryLight,
    labelStyle: const TextStyle(color: PanAfricanColors.textPrimary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
  ),
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      TargetPlatform.android: SharedAxisTransition(),
      TargetPlatform.iOS: SharedAxisTransition(),
    },
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'dosis',
  brightness: Brightness.dark,
  canvasColor: PanAfricanColors.surfaceDark,
  scaffoldBackgroundColor: PanAfricanColors.surfaceDark,
  primarySwatch: primarySwatchDark,
  primaryColor: PanAfricanColors.primaryLight,
  colorScheme: PanAfricanColorScheme.dark,
  dividerColor: PanAfricanColors.outlineDark,
  cardColor: AppColors.filledDark,
  cardTheme: CardThemeData(
    elevation: 0,
    shadowColor: Colors.black.withOpacity(0.4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.white.withOpacity(0.1)),
    ),
    margin: const EdgeInsets.all(8),
    clipBehavior: Clip.antiAlias,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    iconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'dosis',
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: PanAfricanColors.primaryLight,
      foregroundColor: PanAfricanColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: PanAfricanColors.primaryLight,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: PanAfricanColors.cardDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: PanAfricanColors.primaryLight, width: 2),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: PanAfricanColors.cardDark,
    selectedColor: PanAfricanColors.primary,
    labelStyle: const TextStyle(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
  ),
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      TargetPlatform.android: SharedAxisTransition(),
      TargetPlatform.iOS: SharedAxisTransition(),
    },
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
