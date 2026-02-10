import 'package:riverpod/riverpod.dart';

class BaseProviderState {
  final bool isLoading;
  final String? errorMessage;
  final DateTime? errorTimestamp;

  BaseProviderState({
    this.isLoading = false,
    this.errorMessage,
    this.errorTimestamp,
  });

  bool get hasError => errorMessage != null;

  BaseProviderState copyWith({
    bool? isLoading,
    String? errorMessage,
    DateTime? errorTimestamp,
    bool clearError = false,
  }) {
    return BaseProviderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorTimestamp: clearError ? null : (errorTimestamp ?? this.errorTimestamp),
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
