import 'package:riverpod/riverpod.dart';

class BaseProviderState {
  final bool isLoading;

  BaseProviderState({this.isLoading = false});

  BaseProviderState copyWith({bool? isLoading}) {
    return BaseProviderState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

mixin BaseProviderMixin on Notifier<BaseProviderState> {
  void setBusy() {
    state = state.copyWith(isLoading: true);
  }

  void setIdle() {
    state = state.copyWith(isLoading: false);
  }

  bool get isLoading => state.isLoading;
}

abstract class BaseProvider extends Notifier<BaseProviderState> with BaseProviderMixin {
  @override
  BaseProviderState build() => BaseProviderState();
}
