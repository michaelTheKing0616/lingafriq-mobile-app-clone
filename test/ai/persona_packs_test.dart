import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/persona_packs.dart';

void main() {
  group('P11-015 PersonaPackCatalog', () {
    test('four packs list figures with language codes', () {
      expect(PersonaPackCatalog.all.length, 4);
      final titles = PersonaPackCatalog.all.map((p) => p.title).toSet();
      expect(titles, containsAll([
        'Queens of Africa',
        'Scholars of Timbuktu',
        'Independence Generation',
        'Writers & Thinkers',
      ]));
      for (final pack in PersonaPackCatalog.all) {
        for (final figure in pack.figures) {
          expect(figure.languageCodes, isNotEmpty);
        }
      }
    });

    test('AC2 pack assignments for Mofolo, Ahmed Baba, Diop', () {
      final mofoloPack = PersonaPackCatalog.packContaining('thomas_mofolo');
      expect(mofoloPack?.title, 'Writers & Thinkers');
      expect(
        PersonaPackCatalog.findFigure('thomas_mofolo')?.dossierStatus,
        PersonaDossierStatus.authored,
      );

      final babaPack = PersonaPackCatalog.packContaining('ahmed_baba');
      expect(babaPack?.title, 'Scholars of Timbuktu');
      expect(
        PersonaPackCatalog.findFigure('ahmed_baba')?.dossierStatus,
        PersonaDossierStatus.authored,
      );

      final diopPack = PersonaPackCatalog.packContaining('diop_cheikh_anta');
      expect(diopPack?.title, 'Writers & Thinkers');
      expect(
        PersonaPackCatalog.findFigure('diop_cheikh_anta')?.dossierStatus,
        PersonaDossierStatus.planned,
      );
    });

    test('planned figures render coming soon and cannot start', () {
      final diop = PersonaPackCatalog.findFigure('diop_cheikh_anta')!;
      expect(PersonaPackCatalog.renderState(diop), FigureRenderState.comingSoon);
      expect(PersonaPackCatalog.canStart(diop), isFalse);

      final yaa = PersonaPackCatalog.findFigure('yaa_asantewaa')!;
      expect(PersonaPackCatalog.renderState(yaa), FigureRenderState.available);
      expect(PersonaPackCatalog.canStart(yaa), isTrue);
    });
  });
}
