import 'package:flutter/material.dart';
import 'package:lingafriq/theme/stitch_theme_extensions.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';

const _globalFontFallback = <String>[
  'Plus Jakarta Sans',
  'Noto Sans',
  'NotoSans',
  'Roboto',
  'Segoe UI',
  'Arial Unicode MS',
  'Apple Color Emoji',
  'Segoe UI Emoji',
  'Segoe UI Symbol',
  'Noto Color Emoji',
];

final lightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Plus Jakarta Sans',
  fontFamilyFallback: _globalFontFallback,
  brightness: Brightness.light,
  colorScheme: ModernGriotColorScheme.light,
  canvasColor: ModernGriotColors.surface,
  scaffoldBackgroundColor: ModernGriotColors.surface,
  cardColor: ModernGriotColors.surfaceContainerLowest,
  dividerColor: ModernGriotColors.onSurface.withValues(alpha: 0.08),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: const IconThemeData(color: ModernGriotColors.onSurface),
    titleTextStyle: const TextStyle(
      color: ModernGriotColors.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Plus Jakarta Sans',
    ),
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: ModernGriotColors.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
    ),
    clipBehavior: Clip.antiAlias,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: ModernGriotColors.primary,
      foregroundColor: ModernGriotColors.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ModernGriotRadius.full),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ModernGriotColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ModernGriotRadius.full),
      ),
      side: BorderSide(
        color: ModernGriotColors.outlineVariant.withValues(alpha: 0.15),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ModernGriotColors.primary,
      textStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ModernGriotColors.surfaceContainerHighest,
    border: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.md),
      borderSide: BorderSide.none,
    ),
    enabledBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.md),
      borderSide: BorderSide(
        color: ModernGriotColors.outlineVariant.withValues(alpha: 0.15),
        width: 1,
      ),
    ),
    focusedBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.md),
      borderSide: const BorderSide(
        color: ModernGriotColors.primary,
        width: 2,
      ),
    ),
    errorBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.md),
      borderSide: BorderSide(
        color: ModernGriotColorScheme.light.error,
        width: 1,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: const TextStyle(
      color: ModernGriotColors.onSurfaceVariant,
      fontFamily: 'Plus Jakarta Sans',
    ),
    labelStyle: const TextStyle(
      color: ModernGriotColors.onSurfaceVariant,
      fontFamily: 'Plus Jakarta Sans',
    ),
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: ModernGriotColors.surfaceContainerLow,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
    ),
    titleTextStyle: const TextStyle(
      color: ModernGriotColors.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Plus Jakarta Sans',
    ),
    contentTextStyle: const TextStyle(
      color: ModernGriotColors.onSurfaceVariant,
      fontSize: 16,
      fontFamily: 'Plus Jakarta Sans',
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: ModernGriotColors.surfaceContainerLow,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ModernGriotRadius.xl),
      ),
    ),
    modalBackgroundColor: ModernGriotColors.surfaceContainerLow,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: ModernGriotColors.surfaceVariant,
    selectedColor: ModernGriotColors.primaryContainer,
    labelStyle: const TextStyle(
      color: ModernGriotColors.onSurface,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      fontFamily: 'Plus Jakarta Sans',
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.full),
    ),
    side: BorderSide.none,
  ),
  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
    ),
    titleTextStyle: const TextStyle(
      color: ModernGriotColors.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Plus Jakarta Sans',
    ),
    subtitleTextStyle: const TextStyle(
      color: ModernGriotColors.onSurfaceVariant,
      fontSize: 14,
      fontFamily: 'Plus Jakarta Sans',
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: ModernGriotColors.primary,
    foregroundColor: ModernGriotColors.onPrimary,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.full),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ModernGriotColors.surface.withValues(alpha: 0.8),
    indicatorColor: ModernGriotColors.primaryContainer.withValues(alpha: 0.2),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          color: ModernGriotColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Plus Jakarta Sans',
        );
      }
      return const TextStyle(
        color: ModernGriotColors.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Plus Jakarta Sans',
      );
    }),
  ),
  extensions: <ThemeExtension>[
    ModernGriotThemeExtension.light,
    FlbEditorialTheme.light,
    StitchArcadeTheme.light,
    StitchCommunityChatTheme.light,
  ],
);

final darkTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Plus Jakarta Sans',
  fontFamilyFallback: _globalFontFallback,
  brightness: Brightness.dark,
  colorScheme: ModernGriotColorScheme.dark,
  canvasColor: ModernGriotColorsDark.surface,
  scaffoldBackgroundColor: ModernGriotColorsDark.surface,
  cardColor: ModernGriotColorsDark.surfaceContainerLowest,
  dividerColor: ModernGriotColorsDark.onSurface.withValues(alpha: 0.08),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: ModernGriotColorsDark.onSurface),
    titleTextStyle: TextStyle(
      color: ModernGriotColorsDark.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Plus Jakarta Sans',
    ),
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: ModernGriotColorsDark.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
    ),
    clipBehavior: Clip.antiAlias,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: ModernGriotColorsDark.primary,
      foregroundColor: ModernGriotColorsDark.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ModernGriotRadius.full),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ModernGriotColorsDark.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ModernGriotRadius.full),
      ),
      side: BorderSide(
        color: ModernGriotColorsDark.outlineVariant.withValues(alpha: 0.15),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ModernGriotColorsDark.primary,
      textStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ModernGriotColorsDark.surfaceContainerHighest,
    border: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.md),
      borderSide: BorderSide.none,
    ),
    enabledBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.md),
      borderSide: BorderSide(
        color: ModernGriotColorsDark.outlineVariant.withValues(alpha: 0.15),
        width: 1,
      ),
    ),
    focusedBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.md),
      borderSide: BorderSide(
        color: ModernGriotColorsDark.primary,
        width: 2,
      ),
    ),
    errorBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.md),
      borderSide: BorderSide(
        color: ModernGriotColorScheme.dark.error,
        width: 1,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: TextStyle(
      color: ModernGriotColorsDark.onSurfaceVariant,
      fontFamily: 'Plus Jakarta Sans',
    ),
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: ModernGriotColorsDark.surfaceContainerLow,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.xl),
    ),
    titleTextStyle: TextStyle(
      color: ModernGriotColorsDark.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Plus Jakarta Sans',
    ),
    contentTextStyle: TextStyle(
      color: ModernGriotColorsDark.onSurfaceVariant,
      fontSize: 16,
      fontFamily: 'Plus Jakarta Sans',
    ),
  ),
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: ModernGriotColorsDark.surfaceContainerLow,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ModernGriotRadius.xl),
      ),
    ),
    modalBackgroundColor: ModernGriotColorsDark.surfaceContainerLow,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: ModernGriotColorsDark.surfaceVariant,
    selectedColor: ModernGriotColorsDark.primaryContainer,
    labelStyle: TextStyle(
      color: ModernGriotColorsDark.onSurface,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      fontFamily: 'Plus Jakarta Sans',
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.full),
    ),
    side: BorderSide.none,
  ),
  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
    ),
    titleTextStyle: TextStyle(
      color: ModernGriotColorsDark.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Plus Jakarta Sans',
    ),
    subtitleTextStyle: TextStyle(
      color: ModernGriotColorsDark.onSurfaceVariant,
      fontSize: 14,
      fontFamily: 'Plus Jakarta Sans',
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: ModernGriotColorsDark.primary,
    foregroundColor: ModernGriotColorsDark.onPrimary,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ModernGriotRadius.full),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: ModernGriotColorsDark.surface.withValues(alpha: 0.8),
    indicatorColor: ModernGriotColorsDark.primaryContainer.withValues(alpha: 0.2),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return TextStyle(
          color: ModernGriotColorsDark.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Plus Jakarta Sans',
        );
      }
      return TextStyle(
        color: ModernGriotColorsDark.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Plus Jakarta Sans',
      );
    }),
  ),
  extensions: <ThemeExtension>[
    ModernGriotThemeExtension.dark,
    FlbEditorialTheme.dark,
    StitchArcadeTheme.dark,
    StitchCommunityChatTheme.dark,
  ],
);
