import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/features/api/providers/api_provider_mixin_1.dart';
import 'package:lingafriq/features/api/providers/api_provider_mixin_2.dart';
import 'package:lingafriq/features/api/providers/api_provider_mixin_3.dart';
import 'package:lingafriq/features/api/providers/api_provider_mixin_4.dart';
import 'package:lingafriq/features/api/providers/api_provider_mixin_5.dart';
import 'package:lingafriq/features/api/providers/api_provider_mixin_6.dart';

final apiProvider = NotifierProvider<ApiProvider, BaseProviderState>(() {
  return ApiProvider();
});

class ApiProvider extends Notifier<BaseProviderState>
    with BaseProviderMixin, ApiProviderMixin1, ApiProviderMixin2, ApiProviderMixin3, ApiProviderMixin4, ApiProviderMixin5, ApiProviderMixin6 {}
