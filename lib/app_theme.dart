import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

final lightTheme = ThemeData(
  useMaterial3: false,
  fontFamily: 'dosis',
  brightness: Brightness.light,
  canvasColor: Colors.white,
  scaffoldBackgroundColor: Colors.white,
  primarySwatch: primarySwatchLight,
  primaryColor: primarySwatchLight.shade400,
  colorScheme: ColorScheme.fromSwatch(primarySwatch: primarySwatchLight).copyWith(
    brightness: Brightness.light,
    secondary: primarySwatchLight.shade300,
  ),
  dividerColor: Colors.black,
  cardColor: AppColors.filledLight,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: false,
  fontFamily: 'dosis',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardColor: AppColors.filledDark,
  brightness: Brightness.dark,
  canvasColor: Colors.black,
  scaffoldBackgroundColor: Colors.black,
  // canvasColor: const Color(0Xff181818),
  // scaffoldBackgroundColor: const Color(0Xff181818),
  primarySwatch: primarySwatchDark,
  primaryColor: primarySwatchDark.shade400,
  colorScheme: ColorScheme.fromSwatch(primarySwatch: primarySwatchDark).copyWith(
    brightness: Brightness.dark,
    secondary: primarySwatchDark.shade300,
  ),
  dividerColor: Colors.white,
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
