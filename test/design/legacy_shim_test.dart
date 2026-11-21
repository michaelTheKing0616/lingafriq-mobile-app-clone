import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/legacy_shim.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

void main() {
  test('a legacy colour is the token and a shim read is counted', () {
    expect(AppColors.grey, LingAfriqTokens.hexFFB9C0D1);
    expect(AppColors.readGrey(), LingAfriqTokens.hexFFB9C0D1);
    expect(LegacyDesignShim.countFor('app_colors.grey'), 1);
    expect(PanAfricanColors.primary, LingAfriqTokens.hexFF1B7340);
  });
}
