import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

AppLocalizations _l(String c) => lookupAppLocalizations(Locale(c));

void main() {
  test('streak/day counts agree in number (en/fr/ar)', () {
    expect(_l('en').dgStreak(1), '1-day streak');
    expect(_l('en').lbStreak(5), '5-day streak');
    expect(_l('fr').dgStreak(1), 'Série de 1 jour');
    expect(_l('fr').lbStreak(1), 'Série de 1 jour');
    expect(_l('fr').dgStreak(4), 'Série de 4 jours');
    expect(_l('ar').dgStreak(1), 'سلسلة يوم واحد');
    expect(_l('ar').lbStreak(2), 'سلسلة يومين');
    expect(_l('ar').dgStreak(5), 'سلسلة 5 أيام');
    expect(_l('ar').dgStreak(11), 'سلسلة 11 يومًا');
    expect(_l('ar').dgStreak(100), 'سلسلة 100 يوم');
  });

  test('goal ring, minutes, rank moves and trial days pluralise', () {
    expect(_l('en').dgRing(0, 1), '0 of 1 goal done');
    expect(_l('en').dgRing(1, 4), '1 of 4 goals done');
    expect(_l('fr').dgRing(1, 1), '1 objectif sur 1 atteint');
    expect(_l('ar').dgRing(1, 2), 'تم 1 من هدفين');
    expect(_l('ar').dgMinutes(4, 10), '4 من 10 دقائق');
    expect(_l('en').lbUp(1), 'Up 1 place');
    expect(_l('fr').lbDown(1), 'Perd 1 place');
    expect(_l('ar').lbUp(2), 'صعد مركزين');
    expect(_l('fr').subFineTrial(1, '€2'), startsWith('Gratuit 1 jour,'));
    expect(_l('ar').subStartTrial(7), 'ابدأ تجربة مجانية لمدة 7 أيام');
  });
}
