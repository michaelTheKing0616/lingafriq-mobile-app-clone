import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/services/localization/dynamic_localization_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_theme.dart';
import 'providers/navigation_provider.dart';
import 'screens/splash/splash_screen.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final navigatorKey = ref.watch(navigationProvider).navigatorKey;
    // Listen to locale changes to trigger UI rebuild
    final localeNotifier = DynamicLocalizationService.localeNotifier;
    
    return ScreenUtilInit(
      designSize: const Size(428, 926),
      minTextAdapt: true,
      child: const SplashScreen(),
      builder: (context, child) {
        // Watch locale changes to rebuild when language changes
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, currentLocale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: ThemeMode.system,
              locale: currentLocale,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: DynamicLocalizationService.getSupportedLanguages()
                  .map((lang) => Locale(lang.code)),
              localeResolutionCallback: (locale, supportedLocales) {
                // Use DynamicLocalizationService to resolve locale
                if (locale != null) {
                  final languageCode = locale.languageCode.toLowerCase();
                  final supported = DynamicLocalizationService.getSupportedLanguages()
                      .firstWhere(
                        (lang) => lang.code == languageCode,
                        orElse: () => DynamicLocalizationService.currentLanguage,
                      );
                  return Locale(supported.code);
                }
                return DynamicLocalizationService.currentLocale;
              },
              builder: (context, child) {
                ScreenUtil.init(context, designSize: const Size(428, 926));
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                    // Support edge-to-edge display
                    padding: EdgeInsets.zero,
                  ),
                  child: AnnotatedRegion<SystemUiOverlayStyle>(
                    value: SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness: context.isDarkMode ? Brightness.light : Brightness.dark,
                      systemNavigationBarColor: Colors.transparent,
                      systemNavigationBarIconBrightness: context.isDarkMode ? Brightness.light : Brightness.dark,
                    ),
                    child: _Unfocus(child: child),
                  ),
                );
              },
              home: child,
              // home: const OnboardingScreen(),
            );
          },
        );
      },
    );
  }
}

class _Unfocus extends StatelessWidget {
  const _Unfocus({Key? key, required this.child}) : super(key: key);

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: child,
    );
  }
}
