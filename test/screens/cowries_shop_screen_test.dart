import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/user_gamification_model.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/screens/village/cowries_shop_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ShopNotifier extends GamificationProvider {
  @override
  BaseProviderState build() => BaseProviderState();

  @override
  UserGamificationModel get gamification =>
      UserGamificationModel(cowries: 200);

  @override
  List<CowriesShopItem> get shopCatalog => const [
        CowriesShopItem(
          id: 'heritage_preservation_donation',
          sink: 'preservation_fund',
          cost: 50,
          title: 'Heritage Fund gift',
          does: 'Sends Cowries to the community language-preservation fund.',
        ),
        CowriesShopItem(
          id: 'cosmetic_kente_cloak',
          sink: 'cosmetic_avatar',
          cost: 120,
          title: 'Kente cloak',
          does: 'Adds a Kente-pattern cloak to your Village avatar look.',
        ),
      ];

  @override
  bool get shopCatalogLoading => false;

  @override
  Future<void> loadCowriesShopCatalog() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shop lists item outcomes and cost', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamificationProvider.overrideWith(() => _ShopNotifier()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(home: CowriesShopScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heritage Fund gift'), findsOneWidget);
    expect(find.textContaining('language-preservation fund'), findsOneWidget);
    expect(find.text('50 Cowries'), findsOneWidget);
    expect(find.textContaining('200'), findsWidgets);
  });

  testWidgets('shop_buy_item_golden browse state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamificationProvider.overrideWith(() => _ShopNotifier()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(home: CowriesShopScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CowriesShopScreen),
      matchesGoldenFile('goldens/shop_buy_item_golden.png'),
    );
  });
}
