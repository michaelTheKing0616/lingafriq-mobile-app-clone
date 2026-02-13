import 'package:flutter/material.dart';
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
  colorScheme: PanAfricanColorScheme.light,
  canvasColor: PanAfricanColorScheme.light.surface,
  scaffoldBackgroundColor: PanAfricanColorScheme.light.surface,
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
    color: PanAfricanColorScheme.light.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      backgroundColor: PanAfricanColorScheme.light.primary,
      foregroundColor: PanAfricanColorScheme.light.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: PanAfricanColorScheme.light.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PanAfricanColorScheme.light.outlineVariant,
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PanAfricanColorScheme.light.outlineVariant,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PanAfricanColorScheme.light.primary,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PanAfricanColorScheme.light.error,
        width: 1,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: PanAfricanColorScheme.light.surfaceContainerHigh,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    titleTextStyle: TextStyle(
      color: PanAfricanColorScheme.light.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Lato',
    ),
    contentTextStyle: TextStyle(
      color: PanAfricanColorScheme.light.onSurfaceVariant,
      fontSize: 16,
      fontFamily: 'Lato',
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: PanAfricanColorScheme.light.surfaceContainerHigh,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    modalBackgroundColor: PanAfricanColorScheme.light.surfaceContainerHigh,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: PanAfricanColorScheme.light.surfaceContainerHighest,
    selectedColor: PanAfricanColorScheme.light.primaryContainer,
    labelStyle: TextStyle(
      color: PanAfricanColorScheme.light.onSurface,
      fontSize: 14,
      fontFamily: 'Lato',
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    titleTextStyle: TextStyle(
      color: PanAfricanColorScheme.light.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Lato',
    ),
    subtitleTextStyle: TextStyle(
      color: PanAfricanColorScheme.light.onSurfaceVariant,
      fontSize: 14,
      fontFamily: 'Lato',
    ),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Lato',
  fontFamilyFallback: _globalFontFallback,
  brightness: Brightness.dark,
  colorScheme: PanAfricanColorScheme.dark,
  canvasColor: Colors.black,
  scaffoldBackgroundColor: Colors.black,
  cardColor: PanAfricanColors.cardDark,
  dividerColor: PanAfricanColorScheme.dark.onSurface.withValues(alpha: 0.12),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: PanAfricanColorScheme.dark.onSurface),
    titleTextStyle: TextStyle(
      color: PanAfricanColorScheme.dark.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Lato',
    ),
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    color: PanAfricanColorScheme.dark.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 2,
      backgroundColor: PanAfricanColorScheme.dark.primary,
      foregroundColor: PanAfricanColorScheme.dark.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: PanAfricanColorScheme.dark.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PanAfricanColorScheme.dark.outlineVariant,
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PanAfricanColorScheme.dark.outlineVariant,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PanAfricanColorScheme.dark.primary,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: PanAfricanColorScheme.dark.error,
        width: 1,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: PanAfricanColorScheme.dark.surfaceContainerHigh,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    titleTextStyle: TextStyle(
      color: PanAfricanColorScheme.dark.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Lato',
    ),
    contentTextStyle: TextStyle(
      color: PanAfricanColorScheme.dark.onSurfaceVariant,
      fontSize: 16,
      fontFamily: 'Lato',
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: PanAfricanColorScheme.dark.surfaceContainerHigh,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    modalBackgroundColor: PanAfricanColorScheme.dark.surfaceContainerHigh,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: PanAfricanColorScheme.dark.surfaceContainerHighest,
    selectedColor: PanAfricanColorScheme.dark.primaryContainer,
    labelStyle: TextStyle(
      color: PanAfricanColorScheme.dark.onSurface,
      fontSize: 14,
      fontFamily: 'Lato',
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    titleTextStyle: TextStyle(
      color: PanAfricanColorScheme.dark.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Lato',
    ),
    subtitleTextStyle: TextStyle(
      color: PanAfricanColorScheme.dark.onSurfaceVariant,
      fontSize: 14,
      fontFamily: 'Lato',
    ),
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
