import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

final lightTheme = ThemeData(
  useMaterial3: true, // ✅ Material 3 Enabled
  fontFamily: 'dosis',
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primarySwatchLight.shade500, // Use primary color as seed
    brightness: Brightness.light,
    primary: primarySwatchLight.shade500,
    secondary: primarySwatchDark.shade400,
    tertiary: primarySwatchLight.shade300,
  ),
  canvasColor: Colors.white,
  scaffoldBackgroundColor: Colors.white,
  cardColor: AppColors.filledLight,
  dividerColor: Colors.black.withOpacity(0.12),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'dosis',
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
  useMaterial3: true, // ✅ Material 3 Enabled
  fontFamily: 'dosis',
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primarySwatchDark.shade400, // Use primary color as seed
    brightness: Brightness.dark,
    primary: primarySwatchDark.shade400,
    secondary: primarySwatchLight.shade300,
    tertiary: primarySwatchDark.shade300,
  ),
  canvasColor: Colors.black,
  scaffoldBackgroundColor: Colors.black,
  cardColor: AppColors.filledDark,
  dividerColor: Colors.white.withOpacity(0.12),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'dosis',
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
