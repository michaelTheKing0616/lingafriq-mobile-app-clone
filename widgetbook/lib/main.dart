import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/design/catalogue/registry.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:widgetbook/widgetbook.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadFace(
    LingAfriqType.targetFamily,
    '../assets/google_fonts/Andika-Regular.ttf',
  );
  await _loadFace(
    LingAfriqType.bodyFamily,
    '../assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
  );
  runApp(const CatalogueApp());
}

Future<void> _loadFace(String family, String path) async {
  final FontLoader loader = FontLoader(family)
    ..addFont(File(path).readAsBytes().then(ByteData.sublistView));
  await loader.load();
}

/// Screens come from [catalogueUseCases], so this app and the golden harness
/// paint the same states.
class CatalogueApp extends StatelessWidget {
  const CatalogueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: <WidgetbookNode>[
        WidgetbookFolder(
          name: 'Design',
          children: <WidgetbookNode>[
            for (final CatalogueUseCase useCase in catalogueUseCases)
              WidgetbookComponent(
                name: useCase.id,
                useCases: <WidgetbookUseCase>[
                  for (final String state in useCase.states)
                    WidgetbookUseCase(
                      name: state,
                      builder: (BuildContext context) {
                        return Builder(
                          builder: (BuildContext inner) {
                            return useCase.build(
                              Theme.of(inner).brightness,
                              MediaQuery.textScalerOf(inner).scale(1),
                              state,
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
          ],
        ),
      ],
      addons: <WidgetbookAddon<dynamic>>[
        MaterialThemeAddon(
          themes: <WidgetbookTheme<ThemeData>>[
            for (final Brightness brightness in catalogueBrightnesses)
              WidgetbookTheme<ThemeData>(
                name: brightness.name,
                data: catalogueTheme(brightness),
              ),
          ],
        ),
        TextScaleAddon(
          min: catalogueTextScales.first,
          max: catalogueTextScales.last,
          divisions: catalogueTextScales.length - 1,
          initialScale: catalogueTextScales.first,
        ),
      ],
    );
  }
}
